// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../style.dart';
import 'shuffle_textures.dart';

/// 棋盘、入场和飞牌共用的图集批次，缓冲区只在容量增长时分配。
class QuestTileBatch {
  QuestTileBatch(int capacity) {
    _reserve(capacity);
  }
  late Float32List _transforms, _sources;
  late Int32List _colors;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  int _capacity = 0;
  int _count = 0;

  void _reserve(int capacity) {
    _capacity = math.max(1, capacity);
    _transforms = Float32List(_capacity * 4);
    _sources = Float32List(_capacity * 4);
    _colors = Int32List(_capacity);
  }

  void begin() => _count = 0;

  /// 图集内每格是同尺寸完整立体牌；不添加逐牌渐变、裁剪或合成层。
  void add(
    Rect source,
    Rect destination, {
    double rotation = 0,
    double opacity = 1,
  }) {
    if (_count >= _capacity) {
      final old_transforms = _transforms,
          old_sources = _sources,
          old_colors = _colors;
      _reserve(_capacity * 2);
      _transforms.setRange(0, old_transforms.length, old_transforms);
      _sources.setRange(0, old_sources.length, old_sources);
      _colors.setRange(0, old_colors.length, old_colors);
    }
    final scale = destination.shortestSide / TileQuestStyle.tile_cache_width;
    final scos = math.cos(rotation) * scale;
    final ssin = math.sin(rotation) * scale;
    final offset = _count * 4;
    _transforms[offset] = scos;
    _transforms[offset + 1] = ssin;
    _transforms[offset + 2] =
        destination.center.dx - (scos - ssin) * source.width / 2;
    _transforms[offset + 3] =
        destination.center.dy - (scos + ssin) * source.height / 2;
    _sources[offset] = source.left;
    _sources[offset + 1] = source.top;
    _sources[offset + 2] = source.right;
    _sources[offset + 3] = source.bottom;
    _colors[_count++] =
        ((opacity.clamp(0.0, 1.0) * 255).round() << 24) | 0x00ffffff;
  }

  void paint(Canvas canvas, QuestShuffleTextures textures) {
    final atlas = textures.atlas;
    if (atlas == null || _count == 0) return;
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_transforms, 0, _count * 4),
      Float32List.sublistView(_sources, 0, _count * 4),
      Int32List.sublistView(_colors, 0, _count),
      BlendMode.modulate,
      null,
      _paint,
    );
  }
}
