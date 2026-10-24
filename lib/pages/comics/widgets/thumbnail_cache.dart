// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';

/// 缩略图保持原始比例；超长漫画页限制解码像素量，不影响阅读器的完整图片。
int comic_thumbnail_cache_width({
  required double width,
  required double device_pixel_ratio,
  ComicImageData? image,
}) {
  final target = math.max(1, (width * device_pixel_ratio).ceil());
  if (image == null || image.width <= 0 || image.height <= 0) return target;
  final budget_width = math
      .sqrt(ComicsStyle.thumbnail_max_pixels * image.width / image.height)
      .floor();
  return math.max(1, math.min(target, math.min(image.width, budget_width)));
}
