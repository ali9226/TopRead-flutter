// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:app/stores/device_info.dart';
import 'package:app/util/router/router_back.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'game/models.dart';
import 'logic.dart';
import 'style.dart';
import 'widgets/atmosphere.dart';
import 'widgets/quest_controls.dart';
import 'widgets/quest_result.dart';
import 'widgets/quest_scene.dart';
import 'widgets/quest_text.dart';
import 'widgets/session_pause.dart';
import 'widgets/tile_card.dart';

/// 游戏路由页面只协调 UI、弹层与导航；所有规则和存档由控制器处理。
class TileQuestPage extends StatefulWidget {
  const TileQuestPage({super.key, this.logic, this.on_back});

  /// 注入入口用于独立页面测试，不依赖全局登录、设备或路由状态。
  final TileQuestLogic? logic;
  final VoidCallback? on_back;

  @override
  State<TileQuestPage> createState() => _TileQuestPageState();
}

class _TileQuestPageState extends State<TileQuestPage> {
  late final TileQuestLogic _logic;
  bool _allow_pop = false;
  bool _leaving = false;
  bool _restart_dialog_open = false;
  bool _coming_soon = false;
  bool _preloaded = false;
  bool _presentation_busy = false;
  TileQuestActionResult? _settled_action;

  @override
  void initState() {
    super.initState();
    _logic = widget.logic ?? TileQuestLogic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preloaded) return;
    _preloaded = true;
    // 高难度会用到全部图案；预热全部十五种图案的缩略图，避免落牌时
    // 后半组图案尚未解码而只显示底面。
    for (final name in quest_tile_assets) {
      unawaited(
        precacheImage(
          ResizeImage(
            AssetImage('assets/img/game/tile_$name.png'),
            width: TileQuestStyle.tile_cache_width,
          ),
          context,
        ),
      );
    }
  }

  @override
  void dispose() {
    // 局部 GetBuilder 不注册全局实例，页面显式结束控制器生命周期。
    _logic.onDelete();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _logic.leave_game();
    if (!mounted) return;
    setState(() => _allow_pop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (widget.on_back != null) {
      widget.on_back!();
      _leaving = false;
    } else {
      routerBack(context);
    }
  }

  /// 重开会丢弃本局，因此须先明确确认；确认时暂停本局计时。
  Future<void> _confirm_restart({int? board_revision}) async {
    if (_leaving ||
        _restart_dialog_open ||
        _logic.session_suspended ||
        _logic.is_busy ||
        _logic.state == null ||
        (board_revision != null && !_accepts_board_input(board_revision))) {
      return;
    }
    _restart_dialog_open = true;
    _logic.set_modal_paused(true);
    bool answered = false;
    void answer(BuildContext dialog_context, bool confirmed) {
      if (answered || !dialog_context.mounted) return;
      answered = true;
      Navigator.of(dialog_context).pop(confirmed);
    }

    final cjk = quest_is_cjk(context);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        barrierColor: const Color(0xFF07152D).withValues(alpha: .75),
        builder: (dialog_context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.all(24),
            decoration: TileQuestStyle.glass(radius: 26),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: TileQuestStyle.gold,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    quest_text(
                      context,
                      'restart_title',
                      'Restart from level 1?',
                    ),
                    textAlign: TextAlign.center,
                    style: TileQuestStyle.title(cjk).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quest_text(
                      context,
                      'restart_message',
                      'Your current board will be cleared. Start again from the easy first level with all tools restored.',
                    ),
                    textAlign: TextAlign.center,
                    style: TileQuestStyle.body(cjk, color: TileQuestStyle.pale),
                  ),
                  const SizedBox(height: 24),
                  QuestPrimaryButton(
                    key: const ValueKey('tile_quest_confirm_restart'),
                    label: quest_text(context, 'restart', 'Restart'),
                    on_tap: () => answer(dialog_context, true),
                  ),
                  const SizedBox(height: 10),
                  QuestPrimaryButton(
                    label: quest_text(context, 'cancel', 'Keep playing'),
                    primary: false,
                    on_tap: () => answer(dialog_context, false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      answered = true;
      _restart_dialog_open = false;
      _logic.set_modal_paused(false);
    }
    if (!mounted || _leaving || _logic.session_suspended) return;
    if (confirmed == true) {
      setState(() => _coming_soon = false);
      await _logic.restart();
    }
  }

  /// 牌面更换后的首帧尚未重建时，旧回调必须等待新画面，而普通连点
  /// 不更改版本，因此仍然按引擎即时提交每个合法事务。
  bool _accepts_board_input(int board_revision) =>
      mounted &&
      !_leaving &&
      !_logic.session_suspended &&
      board_revision == _logic.board_revision;

  Future<void> _tool(TileQuestTool tool, {int? board_revision}) async {
    if (_leaving ||
        _logic.session_suspended ||
        (board_revision != null && !_accepts_board_input(board_revision))) {
      return;
    }
    final String? challenge_id = _logic.state?.challenge_id;
    final TileQuestActionResult? result = await switch (tool) {
      TileQuestTool.undo => _logic.undo(),
      TileQuestTool.shuffle => _logic.shuffle(),
      TileQuestTool.remove => _logic.remove(),
    };
    if (!mounted ||
        _leaving ||
        _logic.session_suspended ||
        challenge_id != _logic.state?.challenge_id ||
        result == null ||
        result.accepted) {
      return;
    }
    final message = quest_text(
      context,
      tool == TileQuestTool.shuffle ? 'shuffle_failed' : 'no_moves',
      tool == TileQuestTool.shuffle
          ? 'Could not find a safe shuffle. Your tool is unchanged.'
          : 'This tool is not available yet.',
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _next({int? board_revision}) async {
    if (_leaving ||
        _logic.session_suspended ||
        (board_revision != null && !_accepts_board_input(board_revision))) {
      return;
    }
    if (_logic.state?.level == 2) {
      setState(() => _coming_soon = true);
    } else {
      await _logic.next_level();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget themed(bool is_dark) => PopScope<void>(
      canPop: _allow_pop,
      onPopInvokedWithResult: (did_pop, result) {
        if (!did_pop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: TileQuestStyle.sky(is_dark).first,
        body: Stack(
          fit: StackFit.expand,
          children: [
            QuestAtmosphere(is_dark: is_dark),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: TileQuestStyle.max_width,
                  ),
                  child: GetBuilder<TileQuestLogic>(
                    init: _logic,
                    global: false,
                    builder: (logic) {
                      final state = logic.state;
                      final int board_revision = logic.board_revision;
                      if (logic.session_suspended) {
                        return QuestSessionPause(
                          loading: logic.is_loading,
                          on_continue: () => unawaited(logic.resume_session()),
                          on_back: () => unawaited(_leave()),
                        );
                      }
                      if (state == null) return _loading_or_error(logic);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          TileQuestScene(
                            state: state,
                            action: logic.last_action,
                            recent_actions: logic.recent_actions,
                            can_undo: logic.can_undo,
                            on_presentation_busy_changed: (busy) {
                              if (mounted &&
                                  (_presentation_busy != busy ||
                                      (!busy &&
                                          !identical(
                                            _settled_action,
                                            logic.last_action,
                                          )))) {
                                setState(() {
                                  _presentation_busy = busy;
                                  if (!busy) {
                                    _settled_action = logic.last_action;
                                  }
                                });
                              }
                            },
                            sound_enabled: logic.sound_enabled,
                            on_feedback: (event) => unawaited(
                              logic.presentation_feedback(
                                event,
                                challenge_id: state.challenge_id,
                                board_revision: board_revision,
                              ),
                            ),
                            busy: logic.is_busy,
                            on_back: () => unawaited(_leave()),
                            on_restart: () => unawaited(
                              _confirm_restart(board_revision: board_revision),
                            ),
                            on_sound: () {
                              if (_accepts_board_input(board_revision)) {
                                unawaited(logic.toggle_sound());
                              }
                            },
                            on_tile: (id) {
                              if (_accepts_board_input(board_revision)) {
                                unawaited(logic.tap_tile(id));
                              }
                            },
                            on_reserve: (id) {
                              if (_accepts_board_input(board_revision)) {
                                unawaited(logic.return_reserve(id));
                              }
                            },
                            on_tool: (tool) => unawaited(
                              _tool(tool, board_revision: board_revision),
                            ),
                          ),
                          if (state.status != TileQuestStatus.playing &&
                              !_presentation_busy &&
                              (logic.last_action == null ||
                                  identical(
                                    logic.last_action,
                                    _settled_action,
                                  )))
                            QuestResult(
                              state: state,
                              coming_soon: _coming_soon,
                              busy: logic.is_busy,
                              on_next: () => unawaited(
                                _next(board_revision: board_revision),
                              ),
                              on_restart: () => unawaited(
                                _confirm_restart(
                                  board_revision: board_revision,
                                ),
                              ),
                              on_back: () => unawaited(_leave()),
                              on_undo: () => unawaited(
                                _tool(
                                  TileQuestTool.undo,
                                  board_revision: board_revision,
                                ),
                              ),
                            ),
                          if (logic.is_busy)
                            const Positioned(
                              top: 105,
                              left: 20,
                              right: 20,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: TileQuestStyle.gold,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          if (logic.has_save_error)
                            Positioned(
                              left: 16,
                              right: 16,
                              top: 108,
                              child: Material(
                                color: const Color(0xFF4A3645),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          quest_text(
                                            context,
                                            'save_error',
                                            'Progress could not be saved',
                                          ),
                                          style: TileQuestStyle.body(
                                            quest_is_cjk(context),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            unawaited(logic.retry_save()),
                                        child: Text(
                                          quest_text(
                                            context,
                                            'retry_save',
                                            'Retry save',
                                          ),
                                          style: TileQuestStyle.body(
                                            quest_is_cjk(context),
                                            color: TileQuestStyle.gold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (Get.isRegistered<DeviceInfo>()) {
      return Obx(() => themed(Get.find<DeviceInfo>().dark.value));
    }
    return themed(Theme.of(context).brightness == Brightness.dark);
  }

  Widget _loading_or_error(TileQuestLogic logic) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logic.is_loading)
            const CircularProgressIndicator(color: TileQuestStyle.gold)
          else
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: TileQuestStyle.gold,
            ),
          const SizedBox(height: 20),
          Text(
            quest_text(
              context,
              logic.is_loading ? 'loading' : 'load_error',
              logic.is_loading
                  ? 'Preparing your adventure…'
                  : 'Could not open this challenge.',
            ),
            textAlign: TextAlign.center,
            style: TileQuestStyle.body(quest_is_cjk(context)),
          ),
          if (!logic.is_loading) ...[
            const SizedBox(height: 24),
            QuestPrimaryButton(
              label: quest_text(context, 'retry', 'Try again'),
              on_tap: () => unawaited(logic.initialize()),
            ),
            const SizedBox(height: 10),
            QuestPrimaryButton(
              label: quest_text(context, 'back', 'Back'),
              primary: false,
              on_tap: () => unawaited(_leave()),
            ),
          ],
        ],
      ),
    ),
  );
}
