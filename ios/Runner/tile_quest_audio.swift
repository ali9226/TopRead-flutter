import AVFAudio
import Flutter
import UIKit

/// 只管理 Tile Quest 自有的短 PCM 声部，不停止或注销其他模块的播放器。
///
/// audioplayers 的 Darwin 实现使用 AVPlayer。对于 110 ms 的点击声，
/// stop/异步 seek/setVolume/resume 的多次平台往返会消耗声音本身的时长。
/// AVAudioPlayer 的 currentTime/play 在真机仍会等待 I/O 周期；此桥使用
/// 一个持续预热的 AVAudioEngine 和固定声部，点击只投递内存中的 PCM。
final class TileQuestAudioPlugin: NSObject, FlutterPlugin {
  private static let channel_name = "com.topread.novel/tile_quest_audio"
  private static let asset_prefix = "assets/audio/tile_quest/"
  private static let maximum_voices = 24

  /// 资源读取、播放器预热和所有声部状态都在同一后台串行队列执行。
  /// Flutter 主线程不进行 WAV 读取、解码、seek 或音频硬件准备。
  private let audio_queue = DispatchQueue(
    label: "com.topread.novel.tile_quest_audio",
    qos: .userInteractive
  )
  private let registrar: FlutterPluginRegistrar
  private var voices: [Int: TileQuestPreparedVoice] = [:]
  private var asset_buffers: [String: AVAudioPCMBuffer] = [:]
  private var engine: AVAudioEngine?
  private var engine_format: AVAudioFormat?
  private var idle_nodes: [AVAudioPlayerNode] = []
  private var engine_observer: NSObjectProtocol?
  private var engine_running = false
  private var observers: [NSObjectProtocol] = []
  private var session_configured = false
  private var interrupted = false
  private var foreground = true

  private init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
    observe_lifecycle()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = TileQuestAudioPlugin(registrar: registrar)
    let channel = FlutterMethodChannel(
      name: channel_name,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(plugin, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let voice_id = arguments["voice_id"] as? Int
    else {
      result(FlutterError(code: "invalid_voice", message: "Invalid voice id.", details: nil))
      return
    }

    // 只在主线程解析资产键；实际文件读取留在音频队列。
    let asset = arguments["asset"] as? String
    let asset_key = asset.map { registrar.lookupKey(forAsset: $0) }
    audio_queue.async { [self] in
      do {
        switch call.method {
        case "prepare":
          guard let asset, let asset_key,
            asset.hasPrefix(Self.asset_prefix),
            !asset.contains(".."), asset.hasSuffix(".wav"),
            voices[voice_id] != nil || voices.count < Self.maximum_voices
          else { throw audio_error("Invalid or excessive audio asset.") }
          let buffer: AVAudioPCMBuffer
          if let cached = asset_buffers[asset] {
            buffer = cached
          } else {
            guard let path = Bundle.main.path(forResource: asset_key, ofType: nil) else {
              throw audio_error("Audio asset is missing.")
            }
            let file = try AVAudioFile(
              forReading: URL(fileURLWithPath: path),
              commonFormat: .pcmFormatFloat32,
              interleaved: false
            )
            guard file.length > 0, file.length <= Int64(UInt32.max),
              let decoded = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
              )
            else { throw audio_error("Invalid PCM audio asset.") }
            try file.read(into: decoded)
            buffer = decoded
            asset_buffers[asset] = buffer
          }
          try prepare_graph(format: buffer.format)
          if let previous = voices.removeValue(forKey: voice_id) {
            previous.stop()
            idle_nodes.append(previous.node)
          }
          guard let node = idle_nodes.popLast() else {
            throw audio_error("No free PCM voice.")
          }
          let voice = TileQuestPreparedVoice(node: node, buffer: buffer)
          voices[voice_id] = voice
          if foreground && !interrupted {
            try start_engine()
            try voice.prepare()
          }
        case "restart":
          guard foreground && !interrupted else { break }
          guard let volume = arguments["volume"] as? Double,
            volume.isFinite, (0...1).contains(volume),
            let voice = voices[voice_id]
          else { throw audio_error("Audio voice is not prepared.") }
          // 正常连续输入时两个分支均不做 I/O：引擎已启动、声部已预热。
          // 只有显式停止、后台或硬件中断后的首次恢复才重新启动引擎。
          if !engine_running { try start_engine() }
          try voice.restart(volume: Float(volume))
        case "stop":
          voices[voice_id]?.stop()
          pause_if_all_stopped()
        case "dispose":
          if let voice = voices.removeValue(forKey: voice_id) {
            voice.stop()
            idle_nodes.append(voice.node)
          }
          if voices.isEmpty {
            release_engine()
          } else {
            pause_if_all_stopped()
          }
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
          return
        }
        DispatchQueue.main.async { result(nil) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "tile_quest_audio_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  /// Ambient 与其他音频混音，并遵守静音键和锁屏状态。
  /// 不在每次点击时激活/停用共享会话，避免切断其他模块的声音。
  private func configure_session() throws {
    if session_configured { return }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.ambient, mode: .default)
    try session.setActive(true)
    session_configured = true
  }

  /// 在第一次预载时建立固定的 mixer 上游节点池；点击期间不改动音频图。
  /// 所有自有 WAV 使用同一采样率/声道，Mixer 负责转换到实际输出格式。
  private func prepare_graph(format: AVAudioFormat) throws {
    if let existing = engine_format {
      guard existing.isEqual(format) else {
        throw audio_error("Game PCM assets must share one sample rate and channel format.")
      }
      return
    }
    let new_engine = AVAudioEngine()
    let mixer = new_engine.mainMixerNode
    for _ in 0..<Self.maximum_voices {
      let node = AVAudioPlayerNode()
      new_engine.attach(node)
      new_engine.connect(node, to: mixer, format: format)
      idle_nodes.append(node)
    }
    engine = new_engine
    engine_format = format
    engine_observer = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange, object: new_engine, queue: nil
    ) { [weak self, weak new_engine] _ in
      // Apple 明确禁止在引擎通知的内部回调队列同步停止/释放引擎。
      self?.audio_queue.async { [weak self, weak new_engine] in
        guard let self, let new_engine, self.engine === new_engine else { return }
        guard !new_engine.isRunning else { return }
        self.stop_owned_audio()
        self.session_configured = false
        try? self.prewarm_owned_audio()
      }
    }
  }

  private func start_engine() throws {
    guard !engine_running, let engine else { return }
    try configure_session()
    engine.prepare()
    try engine.start()
    engine_running = true
  }

  /// 生命周期恢复只恢复空闲播放节点，不重新排入任何已过期的声音。
  private func prewarm_owned_audio() throws {
    guard foreground && !interrupted && !voices.isEmpty else { return }
    try start_engine()
    for voice in voices.values { try voice.prepare() }
  }

  private func stop_owned_audio() {
    for voice in voices.values { voice.stop() }
    if engine_running { engine?.pause() }
    engine_running = false
  }

  private func pause_if_all_stopped() {
    if voices.values.allSatisfy({ !$0.running }) {
      if engine_running { engine?.pause() }
      engine_running = false
    }
  }

  /// 最后一个页面声部释放时，同时释放固定音频图和解码缓存。
  /// 不停用共享 AVAudioSession，其他模块的音频仍可继续播放。
  private func release_engine() {
    if let observer = engine_observer { NotificationCenter.default.removeObserver(observer) }
    engine_observer = nil
    engine?.stop()
    engine_running = false
    idle_nodes.removeAll()
    engine_format = nil
    engine = nil
    asset_buffers.removeAll()
    session_configured = false
  }

  private func observe_lifecycle() {
    let center = NotificationCenter.default
    observers.append(center.addObserver(
      forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.audio_queue.async { [weak self] in
        guard let self else { return }
        self.foreground = false
        self.stop_owned_audio()
      }
    })
    observers.append(center.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.audio_queue.async { [weak self] in
        guard let self else { return }
        self.foreground = true
        self.session_configured = false
        // 只预热，不补播后台期间的点击或入场声。
        guard !self.interrupted else { return }
        try? self.prewarm_owned_audio()
      }
    })
    observers.append(center.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] notification in
      let kind = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue
      self?.audio_queue.async { [weak self] in
        guard let self else { return }
        self.interrupted = kind == AVAudioSession.InterruptionType.began.rawValue
        self.session_configured = false
        self.stop_owned_audio()
        if !self.interrupted && self.foreground {
          try? self.prewarm_owned_audio()
        }
      }
    })
  }

  private func audio_error(_ message: String) -> NSError {
    NSError(domain: Self.channel_name, code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
    if let observer = engine_observer { NotificationCenter.default.removeObserver(observer) }
  }
}

/// 节点在短 PCM 播完后继续保持 playing 状态，空闲时没有音频数据。
/// 下一次点击直接 interrupts 调度，不等待 stop/seek/play 或结束回调。
private final class TileQuestPreparedVoice {
  let node: AVAudioPlayerNode
  private let buffer: AVAudioPCMBuffer
  private(set) var running = false
  private var volume: Float = 1

  init(node: AVAudioPlayerNode, buffer: AVAudioPCMBuffer) {
    self.node = node
    self.buffer = buffer
  }

  func prepare() throws {
    guard !running else { return }
    node.prepare(withFrameCount: buffer.frameLength)
    try start_node()
  }

  func restart(volume: Float) throws {
    if self.volume != volume {
      node.volume = volume
      self.volume = volume
    }
    node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    if !running { try start_node() }
  }

  private func start_node() throws {
    if #available(iOS 27.0, *) {
      try node.playAudio()
    } else {
      node.play()
    }
    running = true
  }

  func stop() {
    // start_node 失败时也可能已有待播放 buffer，必须一并取消。
    node.stop()
    running = false
  }
}
