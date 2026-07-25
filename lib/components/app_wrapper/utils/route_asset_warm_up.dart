import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/components/svg_icon/index.dart';

// TODO 路由资源预热器：
// TODO - 负责在应用首帧之后，把常见路由会首次命中的本地图片和 svg 提前送进缓存；
// TODO - 这样用户第一次进入新页面时，不需要同时承担“页面首次构建 + 资源首次解析”两份开销；
// TODO - 预热过程做分批执行，避免把所有成本又重新堆到应用启动首帧。
class RouteAssetWarmUp {
  static bool _hasStarted = false;

  // TODO 对外统一入口。
  // TODO 只允许启动一次，避免路由树重建或热重载时重复做整轮预热。
  static Future<void> warmUpAfterFirstFrame(BuildContext context) async {
    if (_hasStarted) {
      return;
    }
    _hasStarted = true;

    final List<String> svgAssets = await _loadSvgAssets();
    final List<String> imageAssets = await _loadImageAssets();
    if (!context.mounted) return;

    // TODO 先预热图片，再预热 svg：
    // TODO - 图片会直接影响某些页面背景和语言选择首开；
    // TODO - svg 数量更多，放在后面分批慢慢吃掉。
    await _warmUpImages(context, imageAssets);
    if (!context.mounted) return;
    await _warmUpSvgs(context, svgAssets);
  }

  static Future<List<String>> _loadSvgAssets() async {
    final List<String> manifest = await _loadAssetManifest();
    return manifest
        .where(
          (asset) =>
              asset.startsWith('assets/svg/') &&
              asset.endsWith('.svg') &&
              !asset.contains('.DS_Store'),
        )
        .toList()
      ..sort();
  }

  static Future<List<String>> _loadImageAssets() async {
    final List<String> manifest = await _loadAssetManifest();
    return manifest
        .where(
          (asset) =>
              asset.startsWith('assets/img/') &&
              (asset.endsWith('.png') ||
                  asset.endsWith('.webp') ||
                  asset.endsWith('.jpg') ||
                  asset.endsWith('.jpeg')) &&
              !asset.contains('.DS_Store'),
        )
        .toList()
      ..sort();
  }

  static Future<List<String>> _loadAssetManifest() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    return manifest.listAssets();
  }

  static Future<void> _warmUpImages(
    BuildContext context,
    List<String> imageAssets,
  ) async {
    for (final String asset in imageAssets) {
      if (!context.mounted) return;
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (_) {
        // TODO 资源预热失败不应该影响正常启动，直接吞掉异常即可。
      }
      await Future<void>.delayed(const Duration(milliseconds: 8));
    }
  }

  static Future<void> _warmUpSvgs(
    BuildContext context,
    List<String> svgAssets,
  ) async {
    // TODO svg 预热分小批执行，避免一次性把大量向量资源编译都压到同一帧。
    const int batchSize = 6;
    for (int index = 0; index < svgAssets.length; index += batchSize) {
      if (!context.mounted) return;
      final List<String> batch = svgAssets.skip(index).take(batchSize).toList();
      await Future.wait(
        batch.map((asset) => SvgIcon.warm_up_asset(asset, context: context)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
  }
}
