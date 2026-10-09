// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/user_info/widgets/top_user_info/logic.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late UserInformation user;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'profile_refresh_test_',
    );
    // 这里只验证读取原凭证，预建文件避免 GetStorage 初始化的异步备份。
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });
  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    GetStorage().writeInMemory(Constant.tokenKey, 'existing-token');
    user = Get.put(UserInformation())
      ..saveUserInfo(UserInfo.fromJson({'id': 1}));
  });
  tearDown(Get.reset);
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  for (final bool missing_token in [false, true]) {
    testWidgets(
      missing_token ? '资料刷新响应缺少token时保留原凭证和登录状态' : '离线或解析失败的资料刷新不会清除原凭证或退出登录',
      (tester) async {
        late BuildContext page_context;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                page_context = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final int revision = user.auth_revision;
        final result = ResultsType<Login>();
        if (missing_token) {
          result.status = true;
          result.content = Login(
            userInfo: UserInfo.fromJson({'id': 1, 'balance': 99}),
          );
        }
        final logic = Logic(page_context, info_loader: () async => result);
        await logic.updateUserInformation();
        expect(await StorageUtil.getData(Constant.tokenKey), 'existing-token');
        expect(user.isLoggedIn.value, isTrue);
        expect(user.auth_revision, revision);
        expect(user.userInfo.value!.balance, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
