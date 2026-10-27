// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

import 'layout_style.dart';

enum PosterSaveResult { saved, access_denied, unavailable, failed }

typedef PosterCapture = Future<Uint8List?> Function(GlobalKey key);
typedef PosterWriter = Future<void> Function(Uint8List bytes, String name);

/// 图库流程可注入测试替身；测试不需要写入真实相册。
class PosterExportService {
  PosterExportService({
    required this.has_access,
    required this.request_access,
    required this.capture,
    required this.write_image,
    this.supported = true,
  });

  final Future<bool> Function() has_access;
  final Future<bool> Function() request_access;
  final PosterCapture capture;
  final PosterWriter write_image;
  final bool supported;

  Future<PosterSaveResult> save({
    required GlobalKey boundary_key,
    required String image_name,
    bool Function()? is_current,
  }) async {
    if (!supported) return PosterSaveResult.unavailable;
    bool current() => is_current?.call() ?? true;
    try {
      if (!current()) return PosterSaveResult.unavailable;
      if (!await has_access() && !await request_access()) {
        return PosterSaveResult.access_denied;
      }
      if (!current()) return PosterSaveResult.unavailable;
      final bytes = await capture(boundary_key);
      if (!current()) return PosterSaveResult.unavailable;
      if (bytes == null || bytes.isEmpty) return PosterSaveResult.failed;
      await write_image(bytes, image_name);
      return PosterSaveResult.saved;
    } on GalException catch (error) {
      return error.type == GalExceptionType.accessDenied
          ? PosterSaveResult.access_denied
          : PosterSaveResult.failed;
    } catch (_) {
      return PosterSaveResult.failed;
    }
  }
}

/// 只捕获海报RepaintBoundary；弹窗按钮、提示和背景不会进入导出图片。
Future<Uint8List?> capture_share_poster(GlobalKey key) async {
  await WidgetsBinding.instance.endOfFrame;
  final render = key.currentContext?.findRenderObject();
  if (render is! RenderRepaintBoundary || !render.attached) return null;
  final image = await render.toImage(
    pixelRatio: ShareLayoutStyle.export_pixel_ratio,
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

final _default_exporter = PosterExportService(
  supported: !kIsWeb,
  has_access: () => Gal.hasAccess(),
  request_access: () => Gal.requestAccess(),
  capture: capture_share_poster,
  write_image: (bytes, name) => Gal.putImageBytes(bytes, name: name),
);

Future<PosterSaveResult> save_share_poster({
  required GlobalKey boundary_key,
  required String image_name,
  bool Function()? is_current,
  PosterExportService? exporter,
}) => (exporter ?? _default_exporter).save(
  boundary_key: boundary_key,
  image_name: image_name,
  is_current: is_current,
);
