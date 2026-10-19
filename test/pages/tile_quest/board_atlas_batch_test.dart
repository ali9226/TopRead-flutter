// ignore_for_file: non_constant_identifier_names
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/game/geometry.dart';
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/board_canvas.dart';
import 'package:app/pages/tile_quest/widgets/board_reveal.dart';
import 'package:app/pages/tile_quest/widgets/scene_layout.dart';
import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AtlasImage extends Fake implements ui.Image {}

/// 只提供绘制所需的纹理区域，避免将 GPU 提交数量测试绑定到异步图片解码。
class _AtlasTextures extends QuestShuffleTextures {
  static const double _edge = QuestTileSurfaceStyle.cell_edge * 1.0;
  static const double _height = QuestTileSurfaceStyle.cell_height * 1.0;
  final _image = _AtlasImage();

  @override
  ui.Image get atlas => _image;

  @override
  bool get ready => true;

  @override
  Rect source_of(int type, {required bool blocked}) =>
      Rect.fromLTWH(type * _edge, blocked ? _height * 2 : 0, _edge, _height);
}

/// 只有一次图集提交是合法路径；额外的逐层 path/atlas 调用会使测试失败。
class _BatchCanvas extends Fake implements Canvas {
  var calls = 0;
  final sources = <Rect>[];
  final centers = <Offset>[];
  final alphas = <int>[];

  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List transforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blend_mode,
    Rect? cull_rect,
    Paint paint,
  ) {
    calls++;
    for (var offset = 0; offset < rects.length; offset += 4) {
      final source = Rect.fromLTRB(
        rects[offset],
        rects[offset + 1],
        rects[offset + 2],
        rects[offset + 3],
      );
      sources.add(source);
      alphas.add((colors![offset ~/ 4] >> 24) & 255);
      centers.add(
        Offset(
          transforms[offset + 2] + transforms[offset] * source.width / 2,
          transforms[offset + 3] + transforms[offset] * source.height / 2,
        ),
      );
    }
  }
}

void main() {
  test('528 simultaneous reveals still submit exactly one ordered atlas', () {
    final before = [
      for (var id = 0; id < 528; id++)
        TileQuestTile(
          id: id,
          type: id % 15,
          layer: id ~/ 30,
          x: (id % 6).toDouble(),
          y: (id ~/ 6).toDouble(),
          is_blocked: true,
        ),
    ];
    final after = [
      for (final tile in before) tile.copy_with(is_blocked: false),
    ];
    final reveal = QuestBoardReveal()..reset(before);
    final textures = _AtlasTextures();
    final pressed = ValueNotifier<int?>(null);
    addTearDown(reveal.dispose);
    addTearDown(textures.dispose);
    addTearDown(pressed.dispose);
    reveal.update(after, 0);
    reveal.advance(110);
    final state = TileQuestState(
      tiles: after,
      level: 2,
      difficulty: 10,
      seed: 1,
      challenge_id: 'batch-reveal',
    );
    const size = Size(390, 844);
    final painter = QuestBoardPainter(
      tiles: after,
      layout: QuestSceneLayout(size, state),
      textures: textures,
      pressed: pressed,
      enabled: true,
      on_tile: (_) {},
      reveal: reveal,
    );
    final canvas = _BatchCanvas();
    painter.paint(canvas, size);
    expect(canvas.calls, 1);
    expect(canvas.alphas.where((alpha) => alpha == 128), hasLength(528));
    expect(
      canvas.alphas.every((alpha) => alpha == 255 || alpha == 128),
      isTrue,
    );
    expect(painter.frames, hasLength(528));
  });

  test('48 layers retain full frames but paint same-position cards once', () {
    const size = Size(390, 844);
    final tiles = [
      for (var layer = 0; layer < 48; layer++)
        for (var cell = 0; cell < 4; cell++)
          TileQuestTile(
            id: layer * 4 + cell,
            type: (layer + cell) % 15,
            layer: layer,
            x: (cell % 2).toDouble(),
            y: (cell ~/ 2).toDouble(),
          ),
    ];
    final state = TileQuestState(
      tiles: tiles,
      level: 2,
      difficulty: 4,
      seed: 1,
      challenge_id: 'board-atlas-order',
    );
    final textures = _AtlasTextures();
    final pressed = ValueNotifier<int?>(189);
    addTearDown(textures.dispose);
    addTearDown(pressed.dispose);
    final layout = QuestSceneLayout(size, state);
    final painter = QuestBoardPainter(
      tiles: tiles,
      layout: layout,
      textures: textures,
      pressed: pressed,
      enabled: true,
      on_tile: (_) {},
    );
    final canvas = _BatchCanvas();
    painter.paint(canvas, size);
    expect(canvas.calls, 1);
    expect(painter.frames, hasLength(48 * 4));
    // 第47层按下189：只需第46层185补在其下，其余深层不重复投影。
    expect(painter.painted_frames.map((frame) => frame.id), [
      185,
      188,
      189,
      190,
      191,
    ]);
    expect(canvas.sources, hasLength(5));
    for (final (sprite, id) in [
      (0, 185),
      (1, 188),
      (2, 189),
      (3, 190),
      (4, 191),
    ]) {
      final frame = painter.frames.singleWhere((frame) => frame.id == id);
      expect(
        canvas.sources[sprite],
        textures.source_of(frame.type, blocked: frame.blocked),
      );
      final center = frame.id == pressed.value
          ? frame.rect.center +
                Offset(
                  0,
                  frame.rect.height * TileQuestStyle.tile_press_depth_fraction,
                )
          : frame.rect.center;
      expect((canvas.centers[sprite] - center).distance, lessThan(.0001));
    }
  });

  test(
    'exact Rect culling preserves partial overlaps, press underlay and reveal/Undo',
    () {
      final original = [
        const TileQuestTile(id: 0, type: 0, layer: 0, x: 0, y: 0),
        const TileQuestTile(id: 1, type: 1, layer: 1, x: 0, y: 0),
        const TileQuestTile(id: 2, type: 2, layer: 2, x: 0, y: 0),
        const TileQuestTile(id: 3, type: 3, layer: 1, x: .5, y: 0),
        const TileQuestTile(id: 4, type: 4, layer: 2, x: 2, y: 0),
        const TileQuestTile(id: 5, type: 5, layer: 2, x: 2, y: 0),
      ];
      final before = TileQuestGeometry(original).refresh(original);
      final reveal = QuestBoardReveal()..reset(before);
      final textures = _AtlasTextures();
      final pressed = ValueNotifier<int?>(null);
      addTearDown(reveal.dispose);
      addTearDown(textures.dispose);
      addTearDown(pressed.dispose);
      QuestBoardPainter painter_for(List<TileQuestTile> tiles) {
        final state = TileQuestState(
          tiles: tiles,
          level: 2,
          seed: 1,
          challenge_id: 'exact-cull',
        );
        return QuestBoardPainter(
          tiles: tiles,
          layout: QuestSceneLayout(const Size(390, 844), state),
          textures: textures,
          pressed: pressed,
          enabled: true,
          on_tile: (_) {},
          reveal: reveal,
        );
      }

      final painter = painter_for(before);
      expect(painter.frames, hasLength(6));
      expect(painter.painted_frames.map((frame) => frame.id), [3, 2, 5]);
      expect(
        painter
            .tile_at(
              painter.frames.singleWhere((frame) => frame.id == 2).rect.center,
            )
            ?.id,
        2,
      );
      pressed.value = 2;
      expect(painter.painted_frames.map((frame) => frame.id), [1, 3, 2, 5]);
      pressed.value = null;
      final removed = [
        for (final tile in before) tile.copy_with(is_removed: tile.id == 2),
      ];
      final after = TileQuestGeometry(removed).refresh(removed);
      reveal.update(after, 0);
      final revealed = painter_for(after);
      expect(revealed.frames, hasLength(6));
      expect(revealed.painted_frames.map((frame) => frame.id), [1, 3, 5]);
      final next = revealed.frames.singleWhere((frame) => frame.id == 1);
      expect(next.blocked, isFalse);
      expect(revealed.reveal_amount_of(next), 1);
      reveal.advance(110);
      expect(revealed.reveal_amount_of(next), closeTo(.5, 1e-10));
      // Undo重新遮挡：逻辑顶牌恢复，但隐藏牌的亮度轨迹也不能跳回端点。
      reveal.update(before, 110);
      final restored = painter_for(before);
      expect(restored.painted_frames.map((frame) => frame.id), [3, 2, 5]);
      final hidden = restored.frames.singleWhere((frame) => frame.id == 1);
      expect(restored.reveal_amount_of(hidden), closeTo(.5, 1e-10));
      final canvas = _BatchCanvas();
      restored.paint(canvas, const Size(390, 844));
      expect(canvas.calls, 1);
      // 同位去重不创建逐牌合成层，并保留半格遮挡牌3。
      expect(
        canvas.sources.any(
          (source) => source == textures.source_of(3, blocked: true),
        ),
        isTrue,
      );
    },
  );
}
