// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/models/app_global_config.dart';
import 'package:app/models/transaction_inquire_type.dart';
import 'package:app/pages/top_up/logic.dart';
import 'package:app/pages/top_up/utils/format_top_up_amount_text.dart';
import 'package:app/pages/top_up/utils/get_top_up_type_display_text.dart';
import 'package:app/pages/top_up/widgets/top_up_amount_section.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 复用仓库内真实多语种资源，充值方式文案断言比较映射结果。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// 把 MaterialApp + EasyLocalization 挂好，译文就绪后再读取文案。
Widget _localized_home(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _Assets(),
    startLocale: const Locale('zh'),
    saveLocale: false,
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: Material(child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });
  tearDown(Get.reset);

  group('充值金额边界格式化', () {
    test('formatTopUpAmountText 补美元符号并去尾零', () {
      // 0 与整数不保留小数。
      expect(formatTopUpAmountText(0), r'$0');
      expect(formatTopUpAmountText(12), r'$12');
      // 去除无意义尾零，保留有效小数。
      expect(formatTopUpAmountText(12.30), r'$12.3');
      expect(formatTopUpAmountText(12.34), r'$12.34');
      // 大额走千分位。
      expect(formatTopUpAmountText(1766.38), r'$1,766.38');
    });
  });

  group('充值金额列表校验', () {
    test('非法金额（0/负数）被过滤，兼容字符串数字', () {
      final response = TransactionInquireTypeResponse.fromJson({
        'data_list': [
          {'id': 1, 'label': 'USDT', 'language_variables': ''},
        ],
        'amount_list': [10, 0, -5, '20', '0', 30.5],
      });

      // 0 与负数不属于可充值金额，必须从可选列表剔除。
      expect(response.amountList, [10, 20, 30.5]);
      expect(response.dataList, hasLength(1));
    });

    test('金额列表缺失时返回空列表，页面可据此判定充值不可用', () {
      final response = TransactionInquireTypeResponse.fromJson({'data_list': []});
      expect(response.amountList, isEmpty);
      expect(response.dataList, isEmpty);
    });
  });

  group('充值方式展示文案', () {
    testWidgets('优先使用多语种键，缺省回退 label', (tester) async {
      final with_key = TransactionInquireTypeItem(
        id: 1,
        label: 'fallback',
        languageVariables: 'top_up_page.type_hint',
      );
      final without_key = TransactionInquireTypeItem(
        id: 2,
        label: '仅接口文案',
        languageVariables: '',
      );

      String via_key = '';
      String via_label = '';
      await tester.pumpWidget(
        _localized_home(
          Builder(
            builder: (context) {
              via_key = getTopUpTypeDisplayText(with_key);
              via_label = getTopUpTypeDisplayText(without_key);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 多语种键命中时返回译文，而不是接口兜底文案。
      expect(via_key, isNot('fallback'));
      expect(via_key, isNotEmpty);
      // 没有多语种键时直接用接口 label。
      expect(via_label, '仅接口文案');
    });
  });

  group('充值配置读取', () {
    testWidgets('配置为空时返回 null，配置齐全时回传金额列表', (tester) async {
      final store = Get.put(AppGlobalConfigStore());
      store.configLoaded.value = true;

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

      final logic = Logic(page_context);

      // 未加载任何配置时充值能力不可用。
      expect(await logic.getRechargeInquireType(), isNull);

      store.saveConfig(
        AppGlobalConfig(
          payTypeList: [
            TransactionInquireTypeItem(id: 9, label: 'USDT', languageVariables: ''),
          ],
          payAmountList: const [10, 50],
          businessConfig: const BusinessConfig(),
        ),
      );
      final results = await logic.getRechargeInquireType();
      expect(results, isNotNull);
      expect(results!.amountList, [10, 50]);
      expect(results.dataList.single.id, 9);
    });
  });

  group('充值金额选择组件', () {
    testWidgets('点击金额项回调携带选中金额', (tester) async {
      double? tapped;
      await tester.pumpWidget(
        _localized_home(
          SizedBox(
            width: 400,
            child: TopUpAmountSection(
              isDark: false,
              amountList: const [10, 50, 100],
              selectedAmount: 10,
              amountTextBuilder: formatTopUpAmountText,
              onTapAmount: (amount) => tapped = amount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tapped, isNull);
      await tester.tap(find.text(r'$50'));
      await tester.pump();
      expect(tapped, 50);
    });
  });
}
