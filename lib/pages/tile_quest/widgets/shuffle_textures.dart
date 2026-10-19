// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../style.dart';
import 'tile_assets.dart';
import 'tile_skin.dart';
import 'tile_surface.dart';
import 'tile_surface_style.dart';

/// 当前场景持有的牌面和洗牌图集；与静态牌共用 Flutter 的解码缓存。
///
/// 每个流回调交付的 ImageInfo 都由这里独占，场景结束时释放自己的引用，
/// 不驱逐 ImageCache 中仍被其他场景或静态牌使用的图片。
class QuestShuffleTextures extends ChangeNotifier {
  final Map<int, ImageInfo> _images = {};
  final Map<int, _QuestTextureRequest> _requests = {};
  final Set<int> _failed_types = {};
  final Map<(int, bool), Rect> _sources = {};
  Set<int> _required = {};
  ImageConfiguration? _configuration;
  ImageInfo? _body;
  _QuestTextureRequest? _body_request;
  bool _body_failed = false;
  ui.Image? _atlas;
  final Paint _tile_paint = Paint()..filterQuality = FilterQuality.low;
  bool _disposed = false;
  bool _building = false;
  bool _notification_pending = false;
  int _generation = 0;
  int _image_revision = 0;
  int? _failed_atlas_revision;

  /// 单张图集包含每种牌的普通和遮挡版本，调用方借用而不负责释放。
  ui.Image? get atlas => _atlas;

  /// 与图集烘焙完全相同的共享皮肤；调用方借用，不可自行释放。
  ui.Image? get body_image => _body?.image;

  /// 所有所需牌面都已经进入当前图集，才允许切换到批量绘制。
  bool get ready =>
      !_disposed &&
      _atlas != null &&
      _required.isNotEmpty &&
      _required.every(
        (type) =>
            _sources.containsKey((type, false)) &&
            _sources.containsKey((type, true)),
      );

  /// 图集中的内容区域不含防止相邻牌采样串色的透明留边。
  Rect? source_of(int type, {required bool blocked}) =>
      _sources[(type, blocked)];

  /// 绘制格内的逻辑牌区域；三消粒子按这个矩形切碎，避免把外扩落影切进去。
  Rect? content_of(int type, {required bool blocked}) {
    final source = _sources[(type, blocked)];
    if (source == null) return null;
    final inset = QuestTileSurfaceStyle.bleed * QuestTileSurfaceStyle.edge;
    return source.deflate(inset);
  }

  /// 图集尚未就绪时，可借用已解码透明图标与同一立体皮肤组合绘制。
  ui.Image? image_of(int type) => _images[type]?.image;

  /// 完整牌的共享绘制入口；场景和单牌均借用图集，不复制原生纹理。
  void paint_tile(
    Canvas canvas,
    Rect rect,
    int type, {
    bool blocked = false,
    double? blocked_amount,
    double opacity = 1,
  }) {
    if (_disposed || rect.isEmpty || opacity <= 0) return;
    final image = _atlas;
    final amount = (blocked_amount ?? (blocked ? 1.0 : 0.0)).clamp(0.0, 1.0);
    final source = source_of(type, blocked: amount > 0);
    if (image != null && source != null) {
      _tile_paint.color = Colors.white.withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );
      canvas.drawImageRect(
        image,
        source,
        QuestTileSurface.cell_rect(rect),
        _tile_paint,
      );
      if (amount > 0 && amount < 1) {
        final normal = source_of(type, blocked: false);
        if (normal != null) {
          _tile_paint.color = Colors.white.withValues(
            alpha: (opacity * (1 - amount)).clamp(0.0, 1.0),
          );
          canvas.drawImageRect(
            image,
            normal,
            QuestTileSurface.cell_rect(rect),
            _tile_paint,
          );
        }
      }
      return;
    }
    // 正常交互开始前已预烘焙；仅启动、素材缺失或重载期间走向量皮肤。
    QuestTileSurface.paint(
      canvas,
      rect,
      body: body_image,
      icon: image_of(type),
      blocked: blocked,
      blocked_amount: amount,
    );
  }

  /// 根据场景依赖解析所需类型；重复调用不会重复加载或重建现有图集。
  ///
  /// AssetImage 和 ResizeImage 的参数与 QuestTileCard 完全相同，因而
  /// 缓存命中时不会再次解码。bundle、像素比等依赖变化时重新解析。
  void resolve(BuildContext context, Iterable<int> types) {
    if (_disposed) return;
    final configuration = createLocalImageConfiguration(context);
    final required = types.toSet();
    if (_configuration != configuration) {
      _clear_images();
      _configuration = configuration;
    }
    final changed =
        required.length != _required.length || !_required.containsAll(required);
    _required = required;
    if (required.isNotEmpty &&
        _body == null &&
        _body_request == null &&
        !_body_failed) {
      _resolve_body(configuration);
    }
    for (final type in required) {
      if (_images.containsKey(type) ||
          _requests.containsKey(type) ||
          _failed_types.contains(type)) {
        continue;
      }
      _resolve_type(type, configuration);
    }
    _maybe_build_atlas();
    if (changed) _notify_after_resolution();
  }

  /// 底板和图标并行解析；同步缓存命中也使用相同的请求解绑流程。
  void _resolve_body(ImageConfiguration configuration) {
    final generation = _generation;
    _QuestTextureRequest? request;
    try {
      final stream = QuestTileSkin.provider.resolve(configuration);
      final listener = ImageStreamListener(
        (info, synchronous) {
          request?.detach();
          if (_disposed || generation != _generation) {
            info.dispose();
            return;
          }
          _body_request = null;
          _body?.dispose();
          _body = info;
          _image_revision++;
          _maybe_build_atlas();
          _notify_after_resolution();
        },
        onError: (Object error, StackTrace? stack) {
          request?.detach();
          if (_disposed || generation != _generation) return;
          _body_request = null;
          _body_failed = true;
          _image_revision++;
          QuestTileSurface.prepare();
          _maybe_build_atlas();
          _notify_after_resolution();
        },
      );
      request = _QuestTextureRequest(stream, listener);
      _body_request = request;
      stream.addListener(listener);
    } catch (_) {
      request?.detach();
      if (_disposed || generation != _generation) return;
      _body_request = null;
      _body_failed = true;
      _image_revision++;
      QuestTileSurface.prepare();
      _maybe_build_atlas();
      _notify_after_resolution();
    }
  }

  /// 单个请求自行解绑，旧 bundle 或已结束场景的迟到结果立即释放。
  void _resolve_type(int type, ImageConfiguration configuration) {
    final generation = _generation;
    _QuestTextureRequest? request;
    try {
      final stream = ResizeImage.resizeIfNeeded(
        TileQuestStyle.tile_cache_width,
        null,
        AssetImage(quest_tile_asset_path(type)),
      ).resolve(configuration);
      final listener = ImageStreamListener(
        (info, synchronous) {
          request?.detach();
          if (_disposed || generation != _generation) {
            info.dispose();
            return;
          }
          _requests.remove(type);
          _images.remove(type)?.dispose();
          _images[type] = info;
          _image_revision++;
          _maybe_build_atlas();
          _notify_after_resolution();
        },
        onError: (Object error, StackTrace? stack) {
          request?.detach();
          if (_disposed || generation != _generation) return;
          _requests.remove(type);
          _failed_types.add(type);
          _notify_after_resolution();
        },
      );
      request = _QuestTextureRequest(stream, listener);
      _requests[type] = request;
      stream.addListener(listener);
    } catch (_) {
      request?.detach();
      if (_disposed || generation != _generation) return;
      _requests.remove(type);
      _failed_types.add(type);
      _notify_after_resolution();
    }
  }

  /// 全部所需图片到齐后才生成图集；同一时刻最多有一个原生栅格化任务。
  void _maybe_build_atlas() {
    if (_disposed ||
        _building ||
        _required.isEmpty ||
        (_body == null && !_body_failed) ||
        _failed_atlas_revision == _image_revision ||
        _required.any((type) => !_images.containsKey(type)) ||
        ready) {
      return;
    }
    unawaited(_build_atlas());
  }

  /// 普通牌和遮挡牌各占一格，洗牌时无需为每张牌另外绘制遮挡蒙层。
  Future<void> _build_atlas() async {
    _building = true;
    final generation = _generation;
    final revision = _image_revision;
    // 栅格化期间依赖可以变化，克隆引用保证本次 picture 的纹理仍有效。
    final snapshot = <int, ImageInfo>{};
    ImageInfo? body_snapshot;
    ui.Picture? picture;
    ui.Image? generated;
    try {
      if (_body == null) QuestTileSurface.prepare();
      if (_disposed || generation != _generation) return;
      body_snapshot = _body?.clone();
      for (final entry in _images.entries) {
        snapshot[entry.key] = entry.value.clone();
      }
      final types = snapshot.keys.toList()..sort();
      const edge = QuestTileSurfaceStyle.cell_edge;
      const height = QuestTileSurfaceStyle.cell_height;
      final padding = TileQuestStyle.shuffle_atlas_padding;
      final pitch_x = edge + padding * 2;
      final pitch_y = height + padding * 2;
      const columns = TileQuestStyle.shuffle_atlas_columns;
      // 每种牌只保留普通和遮挡两格，不创建覆盖透明圆角的额外纹理。
      final rows = (types.length * 2 + columns - 1) ~/ columns;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final sources = <(int, bool), Rect>{};
      var slot = 0;
      for (final type in types) {
        final image = snapshot[type]!.image;
        for (final blocked in const [false, true]) {
          final cell = Rect.fromLTWH(
            (slot % columns * pitch_x + padding).toDouble(),
            (slot ~/ columns * pitch_y + padding).toDouble(),
            edge.toDouble(),
            height.toDouble(),
          );
          sources[(type, blocked)] = cell;
          QuestTileSurface.paint(
            canvas,
            Rect.fromCenter(
              center: cell.center,
              width: QuestTileSurfaceStyle.edge.toDouble(),
              height: QuestTileSurfaceStyle.height.toDouble(),
            ),
            body: body_snapshot?.image,
            icon: image,
            blocked: blocked,
            icon_shadow: true,
          );
          slot++;
        }
      }
      picture = recorder.endRecording();
      generated = await picture.toImage(columns * pitch_x, rows * pitch_y);
      if (_disposed || generation != _generation) return;
      final previous = _atlas;
      _atlas = generated;
      generated = null;
      _sources
        ..clear()
        ..addAll(sources);
      previous?.dispose();
      _notify_after_resolution();
    } catch (_) {
      // 保留可用的原图供直接绘制；同一批失败不循环提交栅格化任务。
      if (!_disposed && generation == _generation) {
        _failed_atlas_revision = revision;
      }
    } finally {
      generated?.dispose();
      picture?.dispose();
      body_snapshot?.dispose();
      for (final info in snapshot.values) {
        info.dispose();
      }
      _building = false;
      // toImage 期间可能加入新类型或切换 bundle，随后补齐新一轮图集。
      _maybe_build_atlas();
    }
  }

  /// 合并同步缓存命中的通知，避免 resolve 在 build 中触发重入刷新。
  void _notify_after_resolution() {
    if (_disposed || _notification_pending) return;
    _notification_pending = true;
    scheduleMicrotask(() {
      _notification_pending = false;
      if (!_disposed) notifyListeners();
    });
  }

  /// 失效所有待完成请求；保留正在运行的任务标记以避免并行 toImage。
  void _clear_images() {
    _generation++;
    _image_revision++;
    for (final request in _requests.values) {
      request.detach();
    }
    _requests.clear();
    _body_request?.detach();
    _body_request = null;
    _body?.dispose();
    _body = null;
    _body_failed = false;
    for (final info in _images.values) {
      info.dispose();
    }
    _images.clear();
    _failed_types.clear();
    _failed_atlas_revision = null;
    _sources.clear();
    _atlas?.dispose();
    _atlas = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clear_images();
    super.dispose();
  }
}

/// ImageStream 的监听所有权，允许同步命中、异步完成和场景释放共用解绑。
class _QuestTextureRequest {
  _QuestTextureRequest(this.stream, this.listener);
  final ImageStream stream;
  final ImageStreamListener listener;
  bool _detached = false;

  void detach() {
    if (_detached) return;
    _detached = true;
    stream.removeListener(listener);
  }
}
