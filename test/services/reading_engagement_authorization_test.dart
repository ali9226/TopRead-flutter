import 'dart:async';
import 'dart:io';

import 'package:app/api/dio_client.dart';
import 'package:app/config/constant.dart';
import 'package:app/services/reading_engagement/index.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'reading_auth_boundary_',
    );
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  tearDown(() => DioClient().instance.interceptors.remove(interceptor));
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  test(
    'a heartbeat keeps its owner token when account switches during async request preparation',
    () async {
      GetStorage().writeInMemory(Constant.tokenKey, 'original-reader');
      ReadingIdentity? current = (user_id: 1, novel_id: 7);
      final captured = <String>[];
      final requested = Completer<void>();
      interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add(options.headers['Authorization']?.toString() ?? '');
          // Intercept every request; no real network or real stored credentials are used.
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{},
            ),
          );
          if (!requested.isCompleted) requested.complete();
        },
      );
      DioClient().instance.interceptors.add(interceptor);
      final controller = ReadingEngagementController(
        identity: () => current,
        is_body_visible: () => true,
        monotonic_ms: () => 0,
        schedule_timer: false,
      );
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      // The default sender has begun but postRequest still awaits locale preparation.
      current = (user_id: 2, novel_id: 7);
      GetStorage().writeInMemory(Constant.tokenKey, 'replacement-reader');
      await requested.future;
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      expect(captured, <String>['Bearer original-reader']);
    },
  );
}
