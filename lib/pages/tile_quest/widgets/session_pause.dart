// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import '../style.dart';
import 'quest_controls.dart';
import 'quest_text.dart';

/// 多窗口打开同一存档时，只允许当前会话提交；旧页明确提供继续入口。
class QuestSessionPause extends StatelessWidget {
  const QuestSessionPause({
    super.key,
    required this.loading,
    required this.on_continue,
    required this.on_back,
  });
  final bool loading;
  final VoidCallback on_continue, on_back;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xE807152D),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.all(24),
          decoration: TileQuestStyle.glass(radius: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline_rounded,
                size: 44,
                color: TileQuestStyle.gold,
              ),
              const SizedBox(height: 18),
              Text(
                quest_text(
                  context,
                  'session_paused',
                  'This challenge is open in another window.',
                ),
                style: TileQuestStyle.body(quest_is_cjk(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              QuestPrimaryButton(
                key: const ValueKey('tile_quest_resume_session'),
                label: quest_text(context, 'continue_game', 'Continue'),
                on_tap: loading ? null : on_continue,
                icon: Icons.play_arrow_rounded,
              ),
              const SizedBox(height: 10),
              QuestPrimaryButton(
                label: quest_text(context, 'back', 'Back'),
                on_tap: on_back,
                primary: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
