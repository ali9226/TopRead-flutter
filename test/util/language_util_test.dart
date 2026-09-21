// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/models/language_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late GetStorage storage;
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'novel_language_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    storage = GetStorage('GetStorage', storage_directory.path);
    await storage.initStorage;
    await LanguageUtil.load_asset_language_code_list();
  });

  setUp(() {
    Get.testMode = true;
    storage.writeInMemory(LanguageStore.language_key, 'sw');
    storage.writeInMemory(LanguageStore.language_list_key, <dynamic>[]);
  });

  tearDown(() => Get.reset());
  tearDownAll(() => storage_directory.delete(recursive: true));

  test('语种列表未加载时斯瓦希里语请求仍使用 language_id=3', () async {
    expect(await LanguageUtil.get_language(), 'sw');
    expect(await LanguageUtil.get_language_id(), 3);
  });

  test('语种列表缺少斯瓦希里语时不会改用默认英语 ID', () async {
    Get.put(
      LanguageStore(asset_language_code_list: <String>['en', 'sw']),
    ).save_language_list(
      const <LanguageInfo>[
        LanguageInfo(id: 1, title: 'English', code: 'en', default_language: 2),
      ],
      persist: false,
    );

    expect(await LanguageUtil.get_language_id(), 3);
  });

  test('已加载语种列表时优先使用服务端配置的 ID', () async {
    Get.put(
      LanguageStore(asset_language_code_list: <String>['en', 'sw']),
    ).save_language_list(
      const <LanguageInfo>[
        LanguageInfo(id: 1, title: 'English', code: 'en', default_language: 2),
        LanguageInfo(id: 30, title: 'Kiswahili', code: 'sw'),
      ],
      persist: false,
    );

    expect(await LanguageUtil.get_language_id(), 30);
  });
}
