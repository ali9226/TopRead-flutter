// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:async';
import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/style.dart';
import 'package:app/pages/tile_quest/widgets/shuffle_textures.dart';
import 'package:app/pages/tile_quest/widgets/tile_card.dart';
import 'package:app/pages/tile_quest/widgets/tile_skin.dart';
import 'package:app/pages/tile_quest/widgets/tile_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _asset_prefix = 'assets/img/tile_quest/icons/tile_';
const _first_color = Color(0xffe8be90);
const _second_color = Color(0xff63bca4);

/// 使用确定的真实 PNG 验证像素，不依赖当前美术素材的颜色或透明度。
Future<ByteData> _png(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    TileQuestStyle.tile_cache_width,
    TileQuestStyle.tile_cache_width,
  );
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// 透明画布保留完整绘制格范围，避免把实心测试图误认为所有像素都需填色。
Future<ByteData> _skin_png(Color color) async {
  final recorder = ui.PictureRecorder();
  final edge = QuestTileSurfaceStyle.cell_edge.toDouble();
  Canvas(recorder).drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(edge * .04, edge * .02, edge * .92, edge * .91),
      Radius.circular(edge * .14),
    ),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(edge.toInt(), edge.toInt());
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

String _asset(int type) => '$_asset_prefix${quest_tile_assets[type]}.png';

/// 非牌面资源仍从应用 bundle 读取，保留 AssetManifest 的真实解析路径。
class _TextureBundle extends CachingAssetBundle {
  _TextureBundle(this.assets);
  final Map<String, ByteData> assets;
  final Map<String, Completer<void>> gates = {};
  final List<String> requests = [];

  @override
  Future<ByteData> load(String key) async {
    if (!key.startsWith(_asset_prefix) && key != QuestTileSkin.asset) {
      return rootBundle.load(key);
    }
    requests.add(key);
    await gates[key]?.future;
    final data = assets[key];
    if (data == null) throw FlutterError('Missing fixture texture: $key');
    return data;
  }
}

Future<_TextureBundle> _bundle() async => _TextureBundle({
  QuestTileSkin.asset: await _skin_png(Colors.white),
  _asset(0): await _png(_first_color),
  _asset(1): await _png(_second_color),
});

class _TextureHost extends StatefulWidget {
  const _TextureHost({
    super.key,
    required this.textures,
    required this.bundle,
    this.types = const [0],
    this.show_static_card = false,
  });
  final QuestShuffleTextures textures;
  final AssetBundle bundle;
  final List<int> types;
  final bool show_static_card;

  @override
  State<_TextureHost> createState() => _TextureHostState();
}

class _TextureHostState extends State<_TextureHost> {
  late AssetBundle bundle = widget.bundle;
  late List<int> types = widget.types;

  void replace({List<int>? next_types, AssetBundle? next_bundle}) =>
      setState(() {
        types = next_types ?? types;
        bundle = next_bundle ?? bundle;
      });

  @override
  Widget build(BuildContext context) => DefaultAssetBundle(
    bundle: bundle,
    child: Builder(
      builder: (context) {
        widget.textures.resolve(context, types);
        return widget.show_static_card
            ? const SizedBox.square(
                dimension: 48,
                child: QuestTileCard(type: 0),
              )
            : const SizedBox.shrink();
      },
    ),
  );
}

/// 发起解析和等待结果都进入真实异步区域，避免 toImage 被 FakeAsync 挂起。
Future<void> _pump(WidgetTester tester, [Widget? widget]) async {
  await tester.runAsync(() async {
    if (widget == null) {
      await tester.pump();
    } else {
      await tester.pumpWidget(widget);
    }
  });
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Texture fixture did not finish');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

List<int> _rgba(ByteData data, int width, Offset position) {
  final offset = (position.dy.floor() * width + position.dx.floor()) * 4;
  return List.generate(4, (channel) => data.getUint8(offset + channel));
}

Future<List<int>> _center_pixel(
  QuestShuffleTextures textures,
  int type, {
  bool blocked = false,
}) async {
  final atlas = textures.atlas!;
  final data = (await atlas.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return _rgba(
    data,
    atlas.width,
    textures.source_of(type, blocked: blocked)!.center,
  );
}

void main() {
  test('tile skin uses the exact user supplied lattice asset', () {
    expect(QuestTileSkin.asset, 'assets/img/tile_quest/lattice.png');
  });

  testWidgets(
    'atlas bakes full raised cards, blocked skins and isolated padded cells',
    (tester) async {
      final bundle = (await tester.runAsync(_bundle))!;
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(
            textures: textures,
            bundle: bundle,
            types: const [0, 1],
            show_static_card: true,
          ),
        ),
      );
      await tester.runAsync(() => _until(() => textures.ready));
      final atlas = textures.atlas!;
      final normal = textures.source_of(0, blocked: false)!;
      final blocked = textures.source_of(0, blocked: true)!;
      expect(textures.image_of(0)!.width, TileQuestStyle.tile_cache_width);
      expect(textures.body_image!.width, QuestTileSurfaceStyle.cell_edge);
      expect(
        normal.size,
        Size(
          QuestTileSurfaceStyle.cell_edge.toDouble(),
          QuestTileSurfaceStyle.cell_height.toDouble(),
        ),
      );
      expect(normal.overlaps(blocked), isFalse);
      expect(
        atlas.width,
        TileQuestStyle.shuffle_atlas_columns *
            (QuestTileSurfaceStyle.cell_edge +
                TileQuestStyle.shuffle_atlas_padding * 2),
      );
      // 每格包含192×216逻辑长牌与四侧等宽留白，粒子只读取牌体。
      expect(
        textures.content_of(0, blocked: false)!.size,
        Size(
          TileQuestStyle.tile_cache_width.toDouble(),
          QuestTileSurfaceStyle.height.toDouble(),
        ),
      );
      await tester.runAsync(() async {
        final data = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final original = _rgba(data, atlas.width, normal.center);
        final shaded = _rgba(data, atlas.width, blocked.center);
        expect(original, [232, 190, 144, 255]);
        expect(await _center_pixel(textures, 1), [99, 188, 164, 255]);
        expect(
          _rgba(
            data,
            atlas.width,
            normal.topLeft + Offset(normal.width * .5, normal.height * .84),
          ),
          [
            (255 * QuestTileSurfaceStyle.body_red_scale +
                    QuestTileSurfaceStyle.body_red_lift)
                .round(),
            (255 * QuestTileSurfaceStyle.body_green_scale +
                    QuestTileSurfaceStyle.body_green_lift)
                .round(),
            (255 * QuestTileSurfaceStyle.body_blue_scale +
                    QuestTileSurfaceStyle.body_blue_lift)
                .round(),
            255,
          ],
          reason:
              'the supplied PNG skin receives only the shared body curve below the icon',
        );
        for (var channel = 0; channel < 3; channel++) {
          expect(
            shaded[channel],
            inInclusiveRange(original[channel] * .65, original[channel] * .99),
          );
        }
        expect(shaded.last, 255);
        expect(
          _rgba(data, atlas.width, blocked.topLeft),
          [0, 0, 0, 0],
          reason:
              'the complete rounded card must keep its outside corners clear',
        );
        expect(
          _rgba(data, atlas.width, normal.topLeft - const Offset(1, 0)),
          [0, 0, 0, 0],
          reason: 'sampling padding must stay clear of neighboring textures',
        );
      });
      expect(
        bundle.requests.where((key) => key == _asset(0)),
        hasLength(1),
        reason:
            'the standalone card and atlas must share one decoder cache key',
      );
      expect(
        bundle.requests.where((key) => key == QuestTileSkin.asset),
        hasLength(1),
        reason: 'standalone and scene cards must share one skin decoder',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'incremental types retain old pixels and a new bundle releases them',
    (tester) async {
      final bundle = (await tester.runAsync(_bundle))!;
      final gate = (await tester.runAsync(() async => Completer<void>()))!;
      bundle.gates[_asset(1)] = gate;
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      final host = GlobalKey<_TextureHostState>();
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(key: host, textures: textures, bundle: bundle),
        ),
      );
      await tester.runAsync(() => _until(() => textures.ready));
      final original_image = textures.image_of(0)!;
      final original_body = textures.body_image!;
      final first_atlas = textures.atlas!;
      host.currentState!.replace(next_types: [0, 1]);
      await _pump(tester);
      await tester.runAsync(
        () => _until(() => bundle.requests.contains(_asset(1))),
      );
      expect(textures.ready, isFalse);
      expect(textures.atlas, same(first_atlas));
      expect(textures.image_of(0), same(original_image));
      expect(textures.image_of(1), isNull);
      await tester.runAsync(() async {
        gate.complete();
        await _until(() => textures.ready);
      });
      expect(first_atlas.debugDisposed, isTrue);
      expect(original_image.debugDisposed, isFalse);
      final expanded_atlas = textures.atlas!;
      final replacement = (await tester.runAsync(_bundle))!;
      host.currentState!.replace(next_bundle: replacement);
      await _pump(tester);
      expect(original_image.debugDisposed, isTrue);
      expect(original_body.debugDisposed, isTrue);
      expect(expanded_atlas.debugDisposed, isTrue);
      await tester.runAsync(() => _until(() => textures.ready));
      expect(textures.image_of(0), isNot(same(original_image)));
      expect(replacement.requests.toSet(), {
        QuestTileSkin.asset,
        _asset(0),
        _asset(1),
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'simultaneous scenes share decoding and own independent handles',
    (tester) async {
      final bundle = (await tester.runAsync(_bundle))!;
      final gate = (await tester.runAsync(() async => Completer<void>()))!;
      bundle.gates[_asset(0)] = gate;
      final first = QuestShuffleTextures();
      final second = QuestShuffleTextures();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await _pump(
        tester,
        MaterialApp(
          home: Column(
            children: [
              _TextureHost(textures: first, bundle: bundle),
              _TextureHost(textures: second, bundle: bundle),
            ],
          ),
        ),
      );
      await tester.runAsync(() async {
        await _until(() => bundle.requests.contains(_asset(0)));
        expect(bundle.requests.toSet(), {QuestTileSkin.asset, _asset(0)});
        gate.complete();
        await _until(() => first.ready && second.ready);
      });
      final first_image = first.image_of(0)!;
      final second_image = second.image_of(0)!;
      final first_body = first.body_image!;
      final second_body = second.body_image!;
      expect(first_image, isNot(same(second_image)));
      expect(first_image.isCloneOf(second_image), isTrue);
      expect(first_body, isNot(same(second_body)));
      expect(first_body.isCloneOf(second_body), isTrue);
      expect(first.atlas, isNot(same(second.atlas)));
      first.dispose();
      expect(first_image.debugDisposed, isTrue);
      expect(first_body.debugDisposed, isTrue);
      expect(second_image.debugDisposed, isFalse);
      expect(second_body.debugDisposed, isFalse);
      expect(second.ready, isTrue);
      await tester.runAsync(() async {
        expect(await _center_pixel(second, 0), [232, 190, 144, 255]);
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dispose during loading detaches late results without notifications',
    (tester) async {
      final bundle = (await tester.runAsync(_bundle))!;
      final gate = (await tester.runAsync(() async => Completer<void>()))!;
      bundle.gates[_asset(0)] = gate;
      final textures = QuestShuffleTextures();
      var notifications = 0;
      textures.addListener(() => notifications++);
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(textures: textures, bundle: bundle),
        ),
      );
      await tester.runAsync(
        () => _until(() => bundle.requests.contains(_asset(0))),
      );
      textures.dispose();
      final before = notifications;
      await tester.runAsync(() async {
        gate.complete();
        await _until(
          () => PaintingBinding.instance.imageCache.pendingImageCount == 0,
        );
      });
      expect(notifications, before);
      expect(textures.image_of(0), isNull);
      expect(textures.body_image, isNull);
      expect(textures.atlas, isNull);
      expect(textures.ready, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dispose during atlas rasterization releases the late image and picture',
    (tester) async {
      final bundle = (await tester.runAsync(_bundle))!;
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      final previous_create = ui.Picture.onCreate;
      final previous_dispose = ui.Picture.onDispose;
      final finished = (await tester.runAsync(() async => Completer<void>()))!;
      ui.Picture? atlas_picture;
      ui.Image? pending_image;
      ui.Image? pending_body;
      ui.Picture.onCreate = (picture) {
        previous_create?.call(picture);
        if (textures.image_of(0) == null || atlas_picture != null) return;
        atlas_picture = picture;
        pending_image = textures.image_of(0);
        pending_body = textures.body_image;
        scheduleMicrotask(textures.dispose);
      };
      ui.Picture.onDispose = (picture) {
        previous_dispose?.call(picture);
        if (identical(picture, atlas_picture) && !finished.isCompleted) {
          finished.complete();
        }
      };
      addTearDown(() {
        ui.Picture.onCreate = previous_create;
        ui.Picture.onDispose = previous_dispose;
      });
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(textures: textures, bundle: bundle),
        ),
      );
      await tester.runAsync(
        () => finished.future.timeout(const Duration(seconds: 5)),
      );
      expect(atlas_picture, isNotNull);
      expect(atlas_picture!.debugDisposed, isTrue);
      expect(pending_image!.debugDisposed, isTrue);
      expect(pending_body!.debugDisposed, isTrue);
      expect(textures.atlas, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a missing asset stays a handled fallback without repeated decoding',
    (tester) async {
      final bundle = _TextureBundle({});
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      var notifications = 0;
      textures.addListener(() => notifications++);
      final host = GlobalKey<_TextureHostState>();
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(key: host, textures: textures, bundle: bundle),
        ),
      );
      await tester.runAsync(() async {
        await _until(() => bundle.requests.isNotEmpty && notifications >= 2);
      });
      expect(textures.ready, isFalse);
      expect(textures.image_of(0), isNull);
      host.currentState!.replace(next_types: [0]);
      await _pump(tester);
      expect(bundle.requests.toSet(), {QuestTileSkin.asset, _asset(0)});
      expect(tester.takeException(), isNull);
    },
  );

  for (final count in [4, 15]) {
    testWidgets('atlas contains only $count normal and blocked icon pairs', (
      tester,
    ) async {
      final bundle = (await tester.runAsync(_bundle))!;
      for (var type = 0; type < count; type++) {
        bundle.assets[_asset(type)] = bundle.assets[_asset(0)]!;
      }
      final textures = QuestShuffleTextures();
      addTearDown(textures.dispose);
      await _pump(
        tester,
        MaterialApp(
          home: _TextureHost(
            textures: textures,
            bundle: bundle,
            types: List.generate(count, (type) => type),
          ),
        ),
      );
      await tester.runAsync(() => _until(() => textures.ready));
      final pitch =
          QuestTileSurfaceStyle.cell_height +
          TileQuestStyle.shuffle_atlas_padding * 2;
      final rows =
          (count * 2 + TileQuestStyle.shuffle_atlas_columns - 1) ~/
          TileQuestStyle.shuffle_atlas_columns;
      expect(textures.atlas!.height, rows * pitch);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('atlas waits for the shared skin before baking icons', (
    tester,
  ) async {
    final bundle = (await tester.runAsync(_bundle))!;
    final gate = (await tester.runAsync(() async => Completer<void>()))!;
    bundle.gates[QuestTileSkin.asset] = gate;
    final textures = QuestShuffleTextures();
    addTearDown(textures.dispose);
    await _pump(
      tester,
      MaterialApp(
        home: _TextureHost(textures: textures, bundle: bundle),
      ),
    );
    await tester.runAsync(() => _until(() => textures.image_of(0) != null));
    expect(textures.body_image, isNull);
    expect(textures.atlas, isNull);
    expect(textures.ready, isFalse);
    await tester.runAsync(() async {
      gate.complete();
      await _until(() => textures.ready);
    });
    expect(textures.body_image, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late skin from a replaced bundle cannot replace the new skin', (
    tester,
  ) async {
    final first = (await tester.runAsync(_bundle))!;
    final replacement = (await tester.runAsync(_bundle))!;
    final gate = (await tester.runAsync(() async => Completer<void>()))!;
    first.gates[QuestTileSkin.asset] = gate;
    final textures = QuestShuffleTextures();
    addTearDown(textures.dispose);
    final host = GlobalKey<_TextureHostState>();
    await _pump(
      tester,
      MaterialApp(
        home: _TextureHost(key: host, textures: textures, bundle: first),
      ),
    );
    await tester.runAsync(() => _until(() => textures.image_of(0) != null));
    host.currentState!.replace(next_bundle: replacement);
    await _pump(tester);
    await tester.runAsync(() => _until(() => textures.ready));
    final current_body = textures.body_image!;
    final current_atlas = textures.atlas!;
    await tester.runAsync(() async {
      gate.complete();
      await _until(
        () => PaintingBinding.instance.imageCache.pendingImageCount == 0,
      );
    });
    expect(textures.body_image, same(current_body));
    expect(textures.atlas, same(current_atlas));
    expect(current_body.debugDisposed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose detaches a pending skin and does not notify late', (
    tester,
  ) async {
    final bundle = (await tester.runAsync(_bundle))!;
    final gate = (await tester.runAsync(() async => Completer<void>()))!;
    bundle.gates[QuestTileSkin.asset] = gate;
    final textures = QuestShuffleTextures();
    var notifications = 0;
    textures.addListener(() => notifications++);
    await _pump(
      tester,
      MaterialApp(
        home: _TextureHost(textures: textures, bundle: bundle),
      ),
    );
    await tester.runAsync(() => _until(() => textures.image_of(0) != null));
    textures.dispose();
    final before = notifications;
    await tester.runAsync(() async {
      gate.complete();
      await _until(
        () => PaintingBinding.instance.imageCache.pendingImageCount == 0,
      );
    });
    expect(notifications, before);
    expect(textures.body_image, isNull);
    expect(textures.atlas, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing skin bakes one fallback and recovers on bundle change', (
    tester,
  ) async {
    final missing = (await tester.runAsync(_bundle))!
      ..assets.remove(QuestTileSkin.asset);
    final replacement = (await tester.runAsync(_bundle))!;
    final textures = QuestShuffleTextures();
    addTearDown(textures.dispose);
    final host = GlobalKey<_TextureHostState>();
    await _pump(
      tester,
      MaterialApp(
        home: _TextureHost(key: host, textures: textures, bundle: missing),
      ),
    );
    await tester.runAsync(() => _until(() => textures.ready));
    final fallback = textures.atlas!;
    expect(textures.body_image, isNull);
    host.currentState!.replace(next_types: [0]);
    await _pump(tester);
    expect(textures.atlas, same(fallback));
    expect(
      missing.requests.where((key) => key == QuestTileSkin.asset),
      hasLength(1),
    );
    host.currentState!.replace(next_bundle: replacement);
    await _pump(tester);
    await tester.runAsync(() => _until(() => textures.ready));
    expect(fallback.debugDisposed, isTrue);
    expect(textures.body_image, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
