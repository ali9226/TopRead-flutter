import Flutter
import UIKit

/// 将当前 Flutter view 所在场景的硬件保留区域交给 Flutter 布局。
/// 不读取设备型号、全局 keyWindow 或物理屏幕尺寸，也不轮询屏幕。
final class WindowDisplayFeaturesPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  FlutterSceneLifeCycleDelegate
{
  private static let channel_name = "com.topread.novel/window_display_features"
  private let registrar: FlutterPluginRegistrar
  private var event_sink: FlutterEventSink?
  private var probe: WindowReservedRegionProbe?
  private var previous_snapshot: NSDictionary?
  private var subscription_generation = 0

  private init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = WindowDisplayFeaturesPlugin(registrar: registrar)
    let methods = FlutterMethodChannel(
      name: channel_name,
      binaryMessenger: registrar.messenger()
    )
    let events = FlutterEventChannel(
      name: channel_name + "/events",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(plugin, channel: methods)
    registrar.addSceneDelegate(plugin)
    events.setStreamHandler(plugin)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    event_sink = events
    subscription_generation += 1
    previous_snapshot = nil
    refresh()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    event_sink = nil
    subscription_generation += 1
    probe?.removeFromSuperview()
    probe = nil
    previous_snapshot = nil
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "refresh" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(refresh())
  }

  /// registrar.viewController 绑定当前引擎，避免多场景时查询到另一张窗口。
  @discardableResult
  private func refresh() -> [String: Any]? {
    guard let view = registrar.viewController?.view, !view.bounds.isEmpty else { return nil }
    if probe?.superview !== view {
      probe?.removeFromSuperview()
      let new_probe = WindowReservedRegionProbe(frame: view.bounds)
      new_probe.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      new_probe.isUserInteractionEnabled = false
      new_probe.isAccessibilityElement = false
      new_probe.backgroundColor = .clear
      new_probe.on_change = { [weak self] snapshot in self?.send_if_changed(snapshot) }
      probe = new_probe
      view.addSubview(new_probe)
    }
    return probe?.snapshot()
  }

  private func send_if_changed(_ snapshot: [String: Any]) {
    let dictionary = snapshot as NSDictionary
    guard dictionary != previous_snapshot else { return }
    previous_snapshot = dictionary
    let generation = subscription_generation
    // 不在 UIKit 正在布局时同步推动 Flutter 重建；只发送真正改变的几何。
    DispatchQueue.main.async { [weak self] in
      guard let self, generation == self.subscription_generation else { return }
      self.event_sink?(snapshot)
    }
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    guard registrar.viewController?.viewIfLoaded?.window?.windowScene === scene else { return }
    if let snapshot = refresh() { send_if_changed(snapshot) }
  }
}

/// 在 layoutSubviews 中读保留区域，让 UIKit 追踪布局依赖；折痕姿态更新
/// 通过 UIHingeInteraction 请求一次布局，不建立 CADisplayLink 或周期 timer。
private final class WindowReservedRegionProbe: UIView {
  var on_change: (([String: Any]) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    if #available(iOS 27.1, *) {
      addInteraction(UIHingeInteraction { [weak self] _, _ in self?.setNeedsLayout() })
    }
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    on_change?(snapshot())
  }

  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    setNeedsLayout()
  }

  func snapshot() -> [String: Any] {
    let host = superview ?? self
    var regions: [[String: Any]] = []
    if #available(iOS 27.1, *), window != nil {
      let kinds: [(UIView.ReservedRegion.Kind, String)] = [
        (.division, "division"), (.occlusion, "occlusion"),
      ]
      for (kind, name) in kinds {
        for region in reservedRegions(kind: kind) where region.isActive {
          // frame 已包含 margins；不能再次添加，否则会重复缩小可用空间。
          let frame = convert(region.frame, to: host)
          guard !frame.isNull, !frame.isInfinite else { continue }
          regions.append([
            "kind": name, "active": true,
            "x": frame.minX - host.bounds.minX,
            "y": frame.minY - host.bounds.minY,
            "width": frame.width, "height": frame.height,
          ])
        }
      }
    }
    regions.sort { left, right in
      let left_key = "\(left["kind"]!)_\(left["x"]!)_\(left["y"]!)"
      let right_key = "\(right["kind"]!)_\(right["x"]!)_\(right["y"]!)"
      return left_key < right_key
    }
    return [
      "view_width": host.bounds.width,
      "view_height": host.bounds.height,
      "regions": regions,
    ]
  }
}
