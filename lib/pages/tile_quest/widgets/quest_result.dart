// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'quest_controls.dart';
import 'quest_text.dart';

/// 结果层不改变引擎状态；恢复存档后也可重现统计和继续关卡入口。
class QuestResult extends StatelessWidget {
  const QuestResult({
    super.key,
    required this.state,
    required this.coming_soon,
    required this.busy,
    required this.on_next,
    required this.on_restart,
    required this.on_back,
    required this.on_undo,
  });
  final TileQuestState state;
  final bool coming_soon, busy;
  final VoidCallback on_next, on_restart, on_back, on_undo;

  @override
  Widget build(BuildContext context) {
    final won = state.status == TileQuestStatus.won;
    final cjk = quest_is_cjk(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey('${state.challenge_id}_${state.status.name}_$coming_soon'),
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        final appear = Curves.easeOutCubic.transform(
          ((value - .48) / .52).clamp(0.0, 1.0),
        );
        final shake = !won
            ? math.sin(value * math.pi * 9) * 9 * (1 - value)
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFF061126).withValues(alpha: .72 * appear),
            ),
            if (won && !coming_soon)
              IgnorePointer(
                child: CustomPaint(painter: _CelebrationPainter(value)),
              ),
            Center(
              child: Opacity(
                opacity: appear,
                child: Transform.translate(
                  offset: Offset(shake, 20 * (1 - appear)),
                  child: Transform.scale(
                    scale: .94 + appear * .06,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(350, constraints.maxWidth - 32),
            maxHeight: constraints.maxHeight - 32,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: TileQuestStyle.glass(radius: 30).copyWith(
                gradient: const LinearGradient(
                  colors: [Color(0xFF29476D), Color(0xFF142846)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: TileQuestStyle.gold.withValues(alpha: .35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ResultCrest(won: won, coming_soon: coming_soon),
                  const SizedBox(height: 14),
                  Text(
                    quest_text(
                      context,
                      coming_soon
                          ? 'coming_soon'
                          : won
                          ? 'complete'
                          : 'game_over',
                      coming_soon
                          ? 'More Levels Coming Soon'
                          : won
                          ? 'Level Complete!'
                          : 'Game Over',
                    ),
                    style: TileQuestStyle.title(
                      cjk,
                    ).copyWith(fontSize: cjk ? 25 : 27),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coming_soon
                        ? quest_text(
                            context,
                            'coming_soon_hint',
                            'The next adventure is on its way.',
                          )
                        : won
                        ? quest_text(
                            context,
                            'level',
                            'Level {level}',
                            args: {'level': '${state.level}'},
                          )
                        : quest_text(
                            context,
                            'game_over_hint',
                            'A fresh start is all it takes.',
                          ),
                    style: TileQuestStyle.body(cjk, color: TileQuestStyle.pale),
                    textAlign: TextAlign.center,
                  ),
                  if (!coming_soon) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1D36).withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _stat(
                            context,
                            'time',
                            'Time',
                            _time(state.elapsed_ms),
                            cjk,
                          ),
                          const SizedBox(height: 9),
                          _stat(
                            context,
                            'cleared',
                            'Tiles cleared',
                            '${state.matched_count}',
                            cjk,
                          ),
                          if (state.level > 1) ...[
                            const SizedBox(height: 9),
                            _stat(
                              context,
                              'tools_used',
                              'Tools used',
                              '${state.tools_used}',
                              cjk,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  QuestPrimaryButton(
                    key: const ValueKey('tile_quest_result_primary'),
                    label: quest_text(
                      context,
                      coming_soon
                          ? 'play_again'
                          : won
                          ? 'next_level'
                          : 'restart',
                      coming_soon
                          ? 'Play again'
                          : won
                          ? 'Next Level'
                          : 'Restart',
                    ),
                    icon: coming_soon || !won
                        ? Icons.refresh_rounded
                        : Icons.arrow_forward_rounded,
                    on_tap: busy
                        ? null
                        : coming_soon || !won
                        ? on_restart
                        : on_next,
                  ),
                  if (state.level > 1 &&
                      !won &&
                      (state.tools[TileQuestTool.undo] ?? 0) > 0) ...[
                    const SizedBox(height: 9),
                    QuestPrimaryButton(
                      label: '${quest_text(context, 'undo', 'Undo')} 1/1',
                      primary: false,
                      icon: Icons.undo_rounded,
                      on_tap: busy ? null : on_undo,
                    ),
                  ],
                  const SizedBox(height: 9),
                  QuestPrimaryButton(
                    label: quest_text(context, 'back', 'Back'),
                    primary: false,
                    on_tap: busy ? null : on_back,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _time(int elapsed_ms) {
    final seconds = elapsed_ms ~/ 1000;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _stat(
    BuildContext context,
    String key,
    String fallback,
    String value,
    bool cjk,
  ) => Row(
    children: [
      Expanded(
        child: Text(
          quest_text(context, key, fallback),
          style: TileQuestStyle.body(cjk, color: TileQuestStyle.pale),
        ),
      ),
      const SizedBox(width: 12),
      Text(value, style: TileQuestStyle.body(cjk, emphasis: true)),
    ],
  );
}

class _ResultCrest extends StatelessWidget {
  const _ResultCrest({required this.won, required this.coming_soon});
  final bool won, coming_soon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: won && !coming_soon
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(0, i == 1 ? -13 : 0),
                  child: Icon(
                    Icons.star_rounded,
                    size: i == 1 ? 76 : 58,
                    color: TileQuestStyle.gold,
                    shadows: const [
                      Shadow(
                        color: Color(0xA9ECA936),
                        blurRadius: 20,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
            ],
          )
        : Container(
            width: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFADBBE8).withValues(alpha: .35),
                  const Color(0xFF657BB6).withValues(alpha: .06),
                ],
              ),
            ),
            child: Icon(
              coming_soon
                  ? Icons.auto_awesome_rounded
                  : Icons.nights_stay_rounded,
              size: 54,
              color: coming_soon
                  ? TileQuestStyle.gold
                  : const Color(0xFFD8DFF7),
            ),
          ),
  );
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress < .25) return;
    final t = ((progress - .25) / .75).clamp(0.0, 1.0);
    final random = math.Random(83);
    for (var i = 0; i < 52; i++) {
      final origin = Offset(size.width / 2, size.height * .35);
      final angle = random.nextDouble() * math.pi * 2;
      final distance =
          (70 + random.nextDouble() * size.width * .6) *
          Curves.easeOut.transform(t);
      final position =
          origin +
          Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + t * t * 140,
          );
      final paint = Paint()
        ..color = [
          TileQuestStyle.gold,
          TileQuestStyle.mint,
          const Color(0xFFC1B4FF),
        ][i % 3].withValues(alpha: 1 - t * .9);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + t * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -4, 4, 8),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
