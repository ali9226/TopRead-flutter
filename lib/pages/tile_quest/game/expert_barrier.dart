// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'config.dart';
import 'geometry.dart';
import 'models.dart';

/// Static dependency barrier. Identities and geometry never change in response
/// to player progress; the required Remove budget follows from held capacity.
class TileQuestExpertBarrier {
  TileQuestExpertBarrier({
    required List<int> front_ids,
    required List<int> partner_ids,
    List<int> lead_solution = const [],
  }) : front_ids = List.unmodifiable(front_ids),
       partner_ids = List.unmodifiable(partner_ids),
       lead_solution = List.unmodifiable(lead_solution);

  static const int front_count = 13;
  static const int type_count = 7;
  static const int partner_count = 8;
  static const int tile_count = front_count + partner_count;

  /// These are matching identities, subsequently mapped to seven actual PNGs.
  /// Every type occurs exactly three times across the complete static core.
  static const List<int> front_types = [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 6];
  static const List<int> partner_types = [3, 0, 4, 1, 5, 2, 6, 6];
  static const int required_remove_uses = 3;

  /// Difficulties 5–9 need seven unmatched front tiles before any partner can
  /// be reached. Six live tray spaces are insufficient without using Remove.
  static const List<int> tool_front_types = [0, 1, 2, 0, 1, 2, 3];
  static const List<int> tool_partner_types = [0, 1, 2, 3, 3];
  static const int tool_type_count = 4;
  static const int tool_tile_count = 12;
  static const int tool_required_remove_uses = 1;
  static const int remove_step = -1;
  final List<int> front_ids;
  final List<int> partner_ids;
  final List<int> lead_solution;
  List<int> get witness => solution();

  int get minimum_remove_uses => front_ids.length == tool_front_types.length
      ? tool_required_remove_uses
      : required_remove_uses;

  int get core_tile_count => front_ids.length + partner_ids.length;

  static List<int> front_types_for_difficulty(int difficulty) =>
      difficulty == 10
      ? front_types
      : difficulty >= TileQuestConfig.mandatory_tool_difficulty
      ? tool_front_types
      : const [];

  static List<int> partner_types_for_difficulty(int difficulty) =>
      difficulty == 10
      ? partner_types
      : difficulty >= TileQuestConfig.mandatory_tool_difficulty
      ? tool_partner_types
      : const [];

  static int type_count_for_difficulty(int difficulty) => difficulty == 10
      ? type_count
      : difficulty >= TileQuestConfig.mandatory_tool_difficulty
      ? tool_type_count
      : 0;

  static int tile_count_for_difficulty(int difficulty) => difficulty == 10
      ? tile_count
      : difficulty >= TileQuestConfig.mandatory_tool_difficulty
      ? tool_tile_count
      : 0;

  static int safe_capacity(int remove_uses) =>
      TileQuestConfig.tray_capacity -
      1 +
      remove_uses * TileQuestConfig.remove_batch_size;

  bool is_closed(TileQuestState state) =>
      front_ids.any((id) => !state.tile_by_id(id).is_removed);

  /// The first three rows become reserve stacks [A,D,A], [B,E,B],
  /// [C,F,C]. After D,E,F,G reach the tray, each column can legally unwind:
  /// return its top A and middle D, close D with its partner, return the bottom
  /// A and close A. This keeps at most six tray tiles even with stack ordering.
  List<int> solution([List<int>? lead_solution]) {
    final path = List<int>.from(lead_solution ?? this.lead_solution);
    if (minimum_remove_uses == tool_required_remove_uses) {
      for (var index = 0; index < front_ids.length; index++) {
        path.add(front_ids[index]);
        if (index == 2) path.add(remove_step);
      }
      // The single Remove stores A, B and C in three separate columns. After
      // A,B,C,D reach the tray, return each column's top and close that triple
      // with its own partner; D's two remaining partners then clear the tray.
      for (var column = 0; column < TileQuestConfig.reserve_columns; column++) {
        path.add(front_ids[column]);
        path.add(partner_ids[column]);
      }
      path.addAll(partner_ids.skip(TileQuestConfig.reserve_columns));
      return List.unmodifiable(path);
    }
    for (var index = 0; index < front_ids.length; index++) {
      path.add(front_ids[index]);
      if (index == 2 || index == 5 || index == 8) path.add(remove_step);
    }
    for (var column = 0; column < TileQuestConfig.reserve_columns; column++) {
      path.add(front_ids[6 + column]);
      path.add(front_ids[3 + column]);
      path.add(partner_ids[column * 2]);
      path.add(front_ids[column]);
      path.add(partner_ids[column * 2 + 1]);
    }
    path.addAll(partner_ids.skip(TileQuestConfig.reserve_columns * 2));
    return List.unmodifiable(path);
  }

  /// Verify the proof prerequisites against actual geometric dependencies.
  /// Each partner is behind the final front tile; each later front is behind
  /// its predecessor. Each front type occurs only once or twice before the
  /// final front, and its third copy is a partner: none can match before then.
  void validate(TileQuestState state, {TileQuestGeometry? geometry}) {
    Never invalid() => throw const FormatException('Invalid expert barrier');
    final expected_front = front_types_for_difficulty(state.difficulty);
    final expected_partner = partner_types_for_difficulty(state.difficulty);
    final expected_types = type_count_for_difficulty(state.difficulty);
    final expected_tiles = tile_count_for_difficulty(state.difficulty);
    if (state.level != 2 ||
        state.difficulty < TileQuestConfig.mandatory_tool_difficulty ||
        state.difficulty > 10 ||
        safe_capacity(minimum_remove_uses - 1) >= expected_front.length ||
        safe_capacity(minimum_remove_uses) < expected_front.length ||
        front_ids.length != expected_front.length ||
        partner_ids.length != expected_partner.length ||
        {...front_ids, ...partner_ids}.length != expected_tiles) {
      invalid();
    }
    final by_id = {for (final tile in state.tiles) tile.id: tile};
    if ([...front_ids, ...partner_ids].any((id) => !by_id.containsKey(id))) {
      invalid();
    }
    // An open gate was reached only after holding every unmatched front. Its
    // capacity lower bound also constrains restored progress: spending Shuffle
    // or Undo cannot substitute for the necessary physical Remove charges.
    // A losing seventh-slot snapshot is legal even though its final tap exposes
    // the partners; no further action can be taken from that terminal state.
    final spent_removes =
        TileQuestConfig.initial_tool_uses(TileQuestTool.remove) -
        (state.tools[TileQuestTool.remove] ??
            TileQuestConfig.initial_tool_uses(TileQuestTool.remove));
    if (!is_closed(state) &&
        state.status != TileQuestStatus.lost &&
        spent_removes < minimum_remove_uses) {
      invalid();
    }
    if (lead_solution.isNotEmpty &&
        (lead_solution.length != state.tiles.length - expected_tiles ||
            lead_solution.toSet().length != lead_solution.length ||
            lead_solution.any(
              (id) =>
                  !by_id.containsKey(id) ||
                  front_ids.contains(id) ||
                  partner_ids.contains(id),
            ))) {
      invalid();
    }
    final actual_types = [
      for (var index = 0; index < expected_types - 1; index++)
        by_id[front_ids[index]]!.type,
      by_id[front_ids.last]!.type,
    ];
    if (actual_types.toSet().length != expected_types) invalid();
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
    for (var index = 0; index < expected_front.length; index++) {
      if (by_id[front_ids[index]]!.type !=
          actual_types[expected_front[index]]) {
        invalid();
      }
    }
    for (var index = 0; index < expected_partner.length; index++) {
      if (by_id[partner_ids[index]]!.type !=
          actual_types[expected_partner[index]]) {
        invalid();
      }
    }
    for (final type in actual_types) {
      if (state.tiles.where((tile) => tile.type == type).length != 3) {
        invalid();
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
    final front = json['front_ids'];
    final partners = json['partner_ids'];
    if (front is! List ||
        partners is! List ||
        !((front.length == front_count && partners.length == partner_count) ||
            (front.length == tool_front_types.length &&
                partners.length == tool_partner_types.length))) {
      throw const FormatException('Invalid expert barrier dimensions');
    }
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
      front_ids: ids(front, front.length),
      partner_ids: ids(partners, partners.length),
      lead_solution: lead == null ? const [] : ids(lead, (lead as List).length),
    );
  }
}
