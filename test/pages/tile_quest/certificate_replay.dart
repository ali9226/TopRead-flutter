// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/expert_barrier.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/logic.dart';

TileQuestActionResult replay_certificate_step(TileQuestEngine engine, int id) =>
    id == TileQuestExpertBarrier.remove_step
    ? engine.remove()
    : engine.state.reserve.contains(id)
    ? engine.return_reserve(id)
    : engine.tap_tile(id);

Future<TileQuestActionResult?> replay_logic_certificate_step(
  TileQuestLogic logic,
  int id,
) => id == TileQuestExpertBarrier.remove_step
    ? logic.remove()
    : logic.state!.reserve.contains(id)
    ? logic.return_reserve(id)
    : logic.tap_tile(id);
