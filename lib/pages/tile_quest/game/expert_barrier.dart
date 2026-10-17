// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'config.dart';
import 'geometry.dart';
import 'models.dart';

/// Static difficulty-10 dependency barrier. Identities and geometry never change
/// in response to player progress; the threshold follows from held capacity.
class TileQuestExpertBarrier {
  TileQuestExpertBarrier({
    required List<int> front_ids,
    required List<int> partner_ids,
    List<int> lead_solution = const [],
  }) : front_ids = List.unmodifiable(front_ids),
       partner_ids = List.unmodifiable(partner_ids),
       lead_solution = List.unmodifiable(lead_solution);

  static const int front_count = 13;
  static const int required_remove_uses = 3;
  static const int remove_step = -1;
  final List<int> front_ids;
  final List<int> partner_ids;
  final List<int> lead_solution;
  List<int> get witness => solution();

  static int safe_capacity(int remove_uses) =>
      TileQuestConfig.tray_capacity -
      1 +
      remove_uses * TileQuestConfig.remove_batch_size;

  bool is_closed(TileQuestState state) =>
      front_ids.any((id) => !state.tile_by_id(id).is_removed);

  /// A witness clears the independent front area, moves three batches, then
  /// clears the last four front tiles and unwinds the three reserve stacks.
  List<int> solution([List<int>? lead_solution]) {
    final path = List<int>.from(lead_solution ?? this.lead_solution);
    for (var index = 0; index < front_ids.length; index++) {
      path.add(front_ids[index]);
      if (index == 2 || index == 5 || index == 8) path.add(remove_step);
    }
    for (var index = 0; index < front_ids.length; index++) {
      final front_index = front_ids.length - index - 1;
      if (front_index < 9) path.add(front_ids[front_index]);
      path.addAll(partner_ids.skip(index * 2).take(2));
    }
    return List.unmodifiable(path);
  }

  /// Verify the proof prerequisites against actual geometric dependencies.
  /// Each partner is behind the final front tile; each later front is behind
  /// its predecessor. Before all 13 fronts leave, no front type can match.
  void validate(TileQuestState state, {TileQuestGeometry? geometry}) {
    Never invalid() => throw const FormatException('Invalid expert barrier');
    if (state.level != 2 ||
        state.difficulty != 10 ||
        safe_capacity(required_remove_uses - 1) >= front_count ||
        safe_capacity(required_remove_uses) < front_count ||
        front_ids.length != front_count ||
        partner_ids.length != front_count * 2 ||
        {...front_ids, ...partner_ids}.length != front_count * 3) {
      invalid();
    }
    final by_id = {for (final tile in state.tiles) tile.id: tile};
    if ([...front_ids, ...partner_ids].any((id) => !by_id.containsKey(id))) {
      invalid();
    }
    if (lead_solution.isNotEmpty &&
        (lead_solution.length != state.tiles.length - front_count * 3 ||
            lead_solution.toSet().length != lead_solution.length ||
            lead_solution.any(
              (id) =>
                  !by_id.containsKey(id) ||
                  front_ids.contains(id) ||
                  partner_ids.contains(id),
            ))) {
      invalid();
    }
    final front_types = front_ids.map((id) => by_id[id]!.type).toSet();
    if (front_types.length != front_count) invalid();
    final graph = geometry ?? TileQuestGeometry(state.tiles);
    bool depends_on(int id, int prerequisite) {
      final pending = <int>[...graph.blockers[id]!];
      final visited = <int>{};
      while (pending.isNotEmpty) {
        final upper = pending.removeLast();
        if (upper == prerequisite) return true;
        if (visited.add(upper)) pending.addAll(graph.blockers[upper]!);
      }
      return false;
    }

    for (var index = 1; index < front_ids.length; index++) {
      if (!depends_on(front_ids[index], front_ids[index - 1])) invalid();
    }
    for (final id in partner_ids) {
      if (!depends_on(id, front_ids.last)) invalid();
    }
    final partner_index = {
      for (var index = 0; index < partner_ids.length; index++)
        partner_ids[index]: index,
    };
    for (final id in partner_ids) {
      if (graph.blockers[id]!.any(
        (upper) =>
            partner_index.containsKey(upper) &&
            partner_index[upper]! > partner_index[id]!,
      )) {
        invalid();
      }
    }
    if (is_closed(state)) {
      for (var index = 0; index < front_count; index++) {
        final type = by_id[front_ids[front_count - index - 1]]!.type;
        if (by_id[partner_ids[index * 2]]!.type != type ||
            by_id[partner_ids[index * 2 + 1]]!.type != type ||
            state.tiles.where((tile) => tile.type == type).length != 3) {
          invalid();
        }
      }
    }
  }

  Map<String, dynamic> to_json() => {
    'front_ids': front_ids,
    'partner_ids': partner_ids,
    'lead_solution': lead_solution,
  };

  static TileQuestExpertBarrier from_json(dynamic json) {
    if (json is! Map) throw const FormatException('Invalid expert barrier');
    List<int> ids(dynamic raw, int count) {
      if (raw is! List ||
          raw.length != count ||
          raw.any((id) => id is! int || id < 0)) {
        throw const FormatException('Invalid expert barrier ids');
      }
      return raw.cast<int>();
    }

    final lead = json['lead_solution'];
    if (lead != null &&
        (lead is! List || lead.length > TileQuestConfig.max_tiles)) {
      throw const FormatException('Invalid expert lead solution');
    }
    return TileQuestExpertBarrier(
      front_ids: ids(json['front_ids'], front_count),
      partner_ids: ids(json['partner_ids'], front_count * 2),
      lead_solution: lead == null ? const [] : ids(lead, (lead as List).length),
    );
  }
}
