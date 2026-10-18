// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'game/config.dart';
import 'game/engine.dart';
import 'game/models.dart';
import 'services/feedback_service.dart';
import 'services/save_service.dart';
import 'services/work_service.dart';

/// Tile Quest 的页面控制器；规则由纯 Dart 引擎负责，动画只消费结果快照。
///
/// 存储、计算、时钟和反馈均可注入。所有操作在执行规则前同步加锁；
/// 保存只捕获不可变状态，后台编码并有序写入，避免阻塞点击。
class TileQuestLogic extends GetxController with WidgetsBindingObserver {
  TileQuestLogic({
    TileQuestSaveService? save_service,
    TileQuestWorkService? work_service,
    TileQuestFeedbackService? feedback_service,
    int Function()? now_ms,
    int Function()? next_seed,
    bool enable_timer = true,
  }) : _save_service = save_service ?? TileQuestSaveService.shared,
       _work_service = work_service ?? TileQuestIsolateWork(),
       _feedback_service = feedback_service ?? TileQuestSystemFeedback(),
       _now_ms = now_ms ?? _monotonic_clock.elapsed_milliseconds,
       _next_seed = next_seed ?? _random_seed,
       _enable_timer = enable_timer;

  /// 保存周期与界面时间刷新周期分别管理，避免每帧重建棋盘。
  static const Duration timer_period = Duration(seconds: 1);
  static const int save_interval_ms = 5000;
  static const int supported_level_count = 2;
  static const Duration feedback_preload_budget = Duration(milliseconds: 240);

  static final _TileQuestClock _monotonic_clock = _TileQuestClock();
  static final Random _random = Random.secure();
  static const Uuid _uuid = Uuid();

  final TileQuestSaveService _save_service;
  final TileQuestWorkService _work_service;
  final TileQuestFeedbackService _feedback_service;
  final int Function() _now_ms;
  final int Function() _next_seed;
  final bool _enable_timer;

  TileQuestEngine? _engine;
  Future<void>? _initialization;
  Timer? _timer;
  Timer? _progress_save_timer;
  int? _clock_anchor;
  int _last_saved_elapsed = 0;
  bool _foreground = true;
  bool _modal_paused = false;
  bool _leaving = false;
  Future<void>? _departure;
  bool _closed = false;
  bool _observing = false;
  Object? _session_token;
  int _session_epoch = 0;
  int _board_revision = 0;

  TileQuestState? get state => _engine?.state;
  TileQuestActionResult? last_action;
  final List<TileQuestActionResult> _recent_actions = <TileQuestActionResult>[];

  /// 整局保留所有事务，避免同帧动作在场景接收前被截掉。
  /// 牌数、道具和回槽次数均有上限，重开或接管会话时整批释放。
  List<TileQuestActionResult> get recent_actions =>
      List<TileQuestActionResult>.unmodifiable(_recent_actions);

  /// 新局和洗牌更换牌面时递增，旧画面回调不能操作尚未呈现的新牌面。
  int get board_revision => _board_revision;
  bool is_loading = true;
  bool is_busy = false;
  bool has_save_error = false;
  bool save_recovered = false;
  bool session_suspended = false;
  String? error_message;

  bool get _owns_session => _save_service.owns_session(_session_token);
  bool get _input_active => _foreground && !_modal_paused && !_leaving;
  bool _is_current_session(int epoch) =>
      !_closed && !_leaving && _owns_session && epoch == _session_epoch;

  bool get sound_enabled => state?.sound_enabled ?? true;
  int get elapsed_ms => state?.elapsed_ms ?? 0;
  bool get can_undo => _engine?.can_undo ?? false;
  bool get can_shuffle =>
      state?.status == TileQuestStatus.playing &&
      (state?.remaining_count ?? 0) > 0 &&
      state?.tools[TileQuestTool.shuffle] == 1;
  bool get can_remove =>
      state?.status == TileQuestStatus.playing &&
      state!.tray.isNotEmpty &&
      state!.reserve.length +
              min(TileQuestConfig.remove_batch_size, state!.tray.length) <=
          TileQuestConfig.reserve_capacity &&
      (state!.tools[TileQuestTool.remove] ?? 0) > 0;

  static int _random_seed() => _random.nextInt(TileQuestConfig.max_seed);

  /// 即使测试种子源固定，重进和重新挑战也不能复用刚结束的牌局种子。
  /// 到达合法上界时回到 0，避免产生无法保存的越界状态。
  int _challenge_seed(int? previous_seed) {
    final int candidate = _next_seed();
    return candidate == previous_seed
        ? (candidate + 1) % (TileQuestConfig.max_seed + 1)
        : candidate;
  }

  @override
  void onInit() {
    super.onInit();
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
    unawaited(initialize());
  }

  /// 每次进入只读取解锁进度和设置，并从简单第一关生成全新挑战。
  /// 同一会话内重复调用共享初始化任务，前后台切换也不会重开。
  Future<void> initialize() {
    if (_closed || _leaving) return Future<void>.value();
    if (_owns_session && _initialization != null) return _initialization!;
    if (!_owns_session) {
      _session_token = _save_service.acquire_session(
        on_revoke: _relinquish_session,
      );
      session_suspended = false;
      _modal_paused = false;
      final AppLifecycleState? lifecycle =
          WidgetsBinding.instance.lifecycleState;
      _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
      _engine = null;
      last_action = null;
      _recent_actions.clear();
    }
    final int epoch = ++_session_epoch;
    return _initialization = _initialize(epoch);
  }

  /// 旧页面重新显示时读取最新设置，从第一关重新开局并接管写入租约。
  Future<void> resume_session() => initialize();

  /// 在租约仍属于本页时同步捕获最终状态，再让出所有权。
  void _relinquish_session() {
    if (!_owns_session || _closed) return;
    _capture_elapsed();
    _foreground = false;
    unawaited(_stop_feedback());
    _clock_anchor = null;
    unawaited(_persist());
    _session_token = null;
    _session_epoch++;
    _initialization = null;
    _timer?.cancel();
    _timer = null;
    is_busy = false;
    is_loading = false;
    session_suspended = true;
    _notify();
  }

  Future<void> _initialize(int epoch) async {
    is_loading = true;
    error_message = null;
    _notify();
    // Load cues alongside the save/generator so the first falling card is not
    // noticeably ahead of its sound. An unavailable backend cannot hold entry.
    final audio_ready = _prepare_feedback().timeout(
      feedback_preload_budget,
      onTimeout: () {},
    );
    try {
      final TileQuestLoadedSave loaded = await _save_service.load();
      if (!_is_current_session(epoch)) return;
      save_recovered = loaded.recovered;
      has_save_error = _save_service.has_write_error;
      // 每次进入都从教学关开始；旧图案表仅恢复经独立校验的进度与偏好。
      final TileQuestState generated = await _work_service.generate(
        level: 1,
        seed: _challenge_seed(loaded.previous_seed),
        unlocked_level: loaded.unlocked_level,
        challenge_id: _uuid.v4(),
      );
      await audio_ready;
      if (!_is_current_session(epoch)) return;
      _engine = TileQuestEngine(generated);
      _board_revision++;
      _engine!.update_metadata(sound_enabled: loaded.sound_enabled);
      _last_saved_elapsed = 0;
      _clock_anchor = null;
      unawaited(_persist());
    } on Object {
      // 存储读错误或生成失败保留明确的可重试状态，不覆盖未知旧存档。
      if (_is_current_session(epoch)) {
        error_message = 'tile_quest.load_error';
        _initialization = null;
      }
    } finally {
      if (_is_current_session(epoch)) {
        is_loading = false;
        _capture_elapsed();
        if (_enable_timer && _engine != null) {
          _timer ??= Timer.periodic(timer_period, (_) => tick());
        }
        _notify();
      }
    }
  }

  /// 只累计当前前台、可操作且尚未结束的游戏时间。
  void _capture_elapsed() {
    final int now = _now_ms();
    final int? anchor = _clock_anchor;
    if (_engine != null && anchor != null) {
      final int delta = max(0, now - anchor);
      _engine!.update_metadata(elapsed_ms: elapsed_ms + delta);
    }
    _clock_anchor =
        _input_active &&
            _owns_session &&
            !_closed &&
            !is_loading &&
            !is_busy &&
            state?.status == TileQuestStatus.playing
        ? now
        : null;
  }

  /// 定时器入口公开用于可重复的虚拟时钟测试。
  void tick() {
    if (_closed || _leaving || !_owns_session || _engine == null) return;
    _capture_elapsed();
    if (elapsed_ms - _last_saved_elapsed >= save_interval_ms) {
      unawaited(_persist());
    }
    if (_input_active) _notify();
  }

  /// 前后台切换立即截取最后一段前台时间并提交进度。
  void set_foreground(bool foreground) {
    if (_closed || _leaving || !_owns_session || foreground == _foreground) {
      return;
    }
    _capture_elapsed();
    _foreground = foreground;
    if (!foreground) unawaited(_stop_feedback());
    _capture_elapsed();
    if (!foreground) unawaited(_persist());
    _notify();
  }

  /// 弹层只暂停当前交互，不能覆盖操作系统报告的真实前后台状态。
  void set_modal_paused(bool paused) {
    if (_closed || _leaving || !_owns_session || paused == _modal_paused) {
      return;
    }
    _capture_elapsed();
    _modal_paused = paused;
    if (paused) unawaited(_stop_feedback());
    _capture_elapsed();
    if (paused) unawaited(_persist());
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    set_foreground(state == AppLifecycleState.resumed);
  }

  Future<TileQuestActionResult?> tap_tile(int tile_id) =>
      _perform(() => _engine!.tap_tile(tile_id), TileQuestFeedbackEvent.tap);

  Future<TileQuestActionResult?> return_reserve(int tile_id) => _perform(
    () => _engine!.return_reserve(tile_id),
    TileQuestFeedbackEvent.tap,
  );

  Future<TileQuestActionResult?> undo() =>
      _perform(() => _engine!.undo(), TileQuestFeedbackEvent.tool);

  Future<TileQuestActionResult?> remove() =>
      _perform(() => _engine!.remove(), TileQuestFeedbackEvent.tool);

  /// 同步完成原子规则更新后再返回；UI 动画不能决定结算顺序。
  Future<TileQuestActionResult?> _perform(
    TileQuestActionResult Function() operation,
    TileQuestFeedbackEvent feedback,
  ) async {
    if (_closed ||
        !_owns_session ||
        is_loading ||
        is_busy ||
        !_input_active ||
        _engine == null) {
      return null;
    }
    _capture_elapsed();
    is_busy = true;
    try {
      final TileQuestActionResult result = operation();
      if (result.accepted) {
        _record_action(result);
        error_message = null;
        // A tap reacts immediately; matches/tools/results follow visual timing.
        if (feedback == TileQuestFeedbackEvent.tap) {
          unawaited(presentation_feedback(feedback));
        }
        if ((result.action == TileQuestAction.tap ||
                result.action == TileQuestAction.return_reserve) &&
            result.after.status == TileQuestStatus.playing) {
          _schedule_progress_save();
        } else {
          unawaited(_persist());
        }
      }
      return result;
    } on Object {
      error_message = 'tile_quest.action_error';
      return null;
    } finally {
      is_busy = false;
      _capture_elapsed();
      _notify();
    }
  }

  /// 洗牌搜索离开 UI isolate；加锁覆盖整个异步任务，防止重复消耗道具。
  Future<TileQuestActionResult?> shuffle() async {
    if (_closed ||
        !_owns_session ||
        is_loading ||
        is_busy ||
        !_input_active ||
        _engine == null) {
      return null;
    }
    final int epoch = _session_epoch;
    _capture_elapsed();
    unawaited(_persist());
    is_busy = true;
    _capture_elapsed();
    _notify();
    try {
      final TileQuestPreparedShuffle prepared = await _work_service.shuffle(
        _engine!.export_json(),
        seed: _next_seed(),
      );
      if (!_is_current_session(epoch)) return null;
      if (prepared.result.accepted) {
        // 保留计算期间发生的生命周期计时和设置变化。
        prepared.engine.update_metadata(
          elapsed_ms: elapsed_ms,
          sound_enabled: sound_enabled,
          unlocked_level: state!.unlocked_level,
        );
        _engine = prepared.engine;
        _board_revision++;
        _record_action(prepared.result);
        error_message = null;
        unawaited(_persist());
      }
      return prepared.result;
    } on Object {
      if (_is_current_session(epoch)) error_message = 'tile_quest.action_error';
      return null;
    } finally {
      if (_is_current_session(epoch)) {
        is_busy = false;
        _capture_elapsed();
        _notify();
      }
    }
  }

  /// UI 在确认弹窗通过后调用；回到简单第一关并恢复各道具的初始额度。
  Future<void> restart() async {
    if (state == null) return;
    await _start_level(1);
  }

  /// 第二关获胜后返回 false，由页面展示后续关卡提示。
  Future<bool> next_level() async {
    final TileQuestState? current = state;
    if (current == null ||
        current.status != TileQuestStatus.won ||
        current.level >= supported_level_count ||
        current.level + 1 > current.unlocked_level) {
      return false;
    }
    return _start_level(current.level + 1);
  }

  Future<bool> _start_level(int level) async {
    if (_closed ||
        !_owns_session ||
        !_input_active ||
        is_loading ||
        is_busy ||
        _engine == null) {
      return false;
    }
    final int epoch = _session_epoch;
    unawaited(_stop_feedback());
    _capture_elapsed();
    unawaited(_persist());
    is_busy = true;
    _capture_elapsed();
    _notify();
    try {
      final TileQuestState generated = await _work_service.generate(
        level: level,
        seed: _challenge_seed(state!.seed),
        unlocked_level: state!.unlocked_level,
        challenge_id: _uuid.v4(),
      );
      if (!_is_current_session(epoch)) return false;
      final bool current_sound = sound_enabled;
      _engine = TileQuestEngine(generated);
      _board_revision++;
      _engine!.update_metadata(sound_enabled: current_sound);
      _last_saved_elapsed = 0;
      last_action = null;
      _recent_actions.clear();
      save_recovered = false;
      error_message = null;
      // 与普通点击一致，快照立即排队，慢磁盘不延长新局的交互锁。
      unawaited(_persist());
      return _is_current_session(epoch);
    } on Object {
      if (_is_current_session(epoch)) error_message = 'tile_quest.load_error';
      return false;
    } finally {
      if (_is_current_session(epoch)) {
        is_busy = false;
        _capture_elapsed();
        _notify();
      }
    }
  }

  /// 声音设置和挑战一起保存；关闭后系统触感同样静默。
  Future<void> toggle_sound() async {
    if (_closed || _leaving || !_owns_session || _engine == null) return;
    _engine!.update_metadata(sound_enabled: !sound_enabled);
    if (!sound_enabled) unawaited(_stop_feedback());
    _notify();
    await _persist();
  }

  /// Presentation events are emitted once at the visual start/fade/finish.
  /// Session and foreground guards also discard callbacks from an obsolete page.
  Future<void> presentation_feedback(
    TileQuestFeedbackEvent event, {
    String? challenge_id,
    int? board_revision,
  }) async {
    if (_closed ||
        !_owns_session ||
        !_input_active ||
        !sound_enabled ||
        (challenge_id != null && challenge_id != state?.challenge_id) ||
        (board_revision != null && board_revision != _board_revision) ||
        (is_busy && event != TileQuestFeedbackEvent.tap)) {
      return;
    }
    await _play_feedback(event);
  }

  Future<void> _prepare_feedback() async {
    final feedback = _feedback_service;
    if (feedback is! TileQuestFeedbackLifecycle) return;
    try {
      await (feedback as TileQuestFeedbackLifecycle).prepare();
    } on Object {
      // Asset/plugin failures cannot prevent opening a challenge.
    }
  }

  Future<void> _stop_feedback() async {
    final feedback = _feedback_service;
    if (feedback is! TileQuestFeedbackLifecycle) return;
    try {
      await (feedback as TileQuestFeedbackLifecycle).stop();
    } on Object {
      // Lifecycle cleanup is independent from rule and persistence success.
    }
  }

  Future<void> _dispose_feedback() async {
    final feedback = _feedback_service;
    if (feedback is! TileQuestFeedbackLifecycle) return;
    try {
      await (feedback as TileQuestFeedbackLifecycle).dispose();
    } on Object {
      // A failing audio backend must never block route disposal.
    }
  }

  void _record_action(TileQuestActionResult result) {
    last_action = result;
    _recent_actions.add(result);
  }

  Future<void> _play_feedback(TileQuestFeedbackEvent event) async {
    try {
      await _feedback_service.play(event);
    } on Object {
      // 注入反馈服务失效也不能传播到规则更新或存档。
    }
  }

  /// 固定窗口从第一次点击计时，连续输入不会无限推迟最新状态落盘。
  /// 终局、道具和生命周期统一走 _persist，先取消本窗口再捕获状态。
  void _schedule_progress_save() {
    _progress_save_timer ??= Timer(TileQuestConfig.progress_save_window, () {
      _progress_save_timer = null;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    _progress_save_timer?.cancel();
    _progress_save_timer = null;
    final TileQuestEngine? engine = _engine;
    if (engine == null || !_owns_session) return;
    final int epoch = _session_epoch;
    _capture_elapsed();
    _last_saved_elapsed = elapsed_ms;
    bool save_failed = false;
    try {
      // 同步捕获状态引用；编码和磁盘写入不占用当前点击的 UI 帧。
      await _save_service.save(engine);
    } on Object {
      save_failed = true;
    }
    // 在完成时比较当前错误标记，排队请求也能正确清除先前写入的错误。
    // 正常落盘不改变画面，避免每次点击额外重建一次完整游戏页。
    if (_is_current_session(epoch) && has_save_error != save_failed) {
      has_save_error = save_failed;
      _notify();
    }
  }

  Future<void> retry_save() => _persist();

  Future<void> flush_save() async {
    await _persist();
    await _save_service.flush();
  }

  /// 退出先同步撤销计算的提交资格，再等待最终快照；重复退出共享栅栏。
  Future<void> leave_game() {
    if (_departure != null) return _departure!;
    _capture_elapsed();
    _leaving = true;
    _foreground = false;
    _clock_anchor = null;
    _session_epoch++;
    is_busy = false;
    is_loading = false;
    _timer?.cancel();
    _timer = null;
    unawaited(_stop_feedback());
    return _departure = flush_save();
  }

  void _notify() {
    if (!_closed) update();
  }

  @override
  void onClose() {
    if (_closed) return;
    _capture_elapsed();
    _foreground = false;
    _clock_anchor = null;
    // onClose 不能 await；同步排入共享队列，后续页面 load 会等待该队列。
    unawaited(_persist());
    _save_service.release_session(_session_token);
    _session_token = null;
    _closed = true;
    unawaited(_dispose_feedback());
    _timer?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}

/// Stopwatch 提供不受系统校时影响的单调时钟。
class _TileQuestClock {
  final Stopwatch _watch = Stopwatch()..start();

  int elapsed_milliseconds() => _watch.elapsedMilliseconds;
}
