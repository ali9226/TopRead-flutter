// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/pages/bill/utils/display_bill_number.dart';
import 'package:app/pages/bill/utils/format_bill_amount.dart';
import 'package:app/pages/bill/utils/format_bill_update_time.dart';
import 'package:app/pages/bill/utils/get_bill_type_icon.dart';
import 'package:app/pages/bill/utils/get_bill_type_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复用仓库内真实多语种资源，账单类型文案断言比较映射结果。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

Map<String, String> _zh_bill_labels() {
  final Map<String, dynamic> json = Map<String, dynamic>.from(
    jsonDecode(File('assets/i18n/zh.json').readAsStringSync()) as Map,
  );
  return Map<String, String>.from(json['bill'] as Map);
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

  /// 在 EasyLocalization 作用域内读取文案，保证工具层 tr() 能取到译文。
  Future<String> label_in_context(WidgetTester tester, String Function() read) async {
    String value = '';
    await tester.pumpWidget(
      EasyLocalization(
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
            home: Builder(
              builder: (context) {
                value = read();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return value;
  }

  group('账单金额正负号', () {
    test('收入补 +、支出补 -、零金额不加符号', () {
      expect(formatBillAmount(12.5), '+12.5');
      expect(formatBillAmount(-12.5), '-12.5');
      expect(formatBillAmount(0), '0');
      // 绝对值负责千分位，符号单独拼接。
      expect(formatBillAmount(-1766.38), '-1,766.38');
      expect(formatBillAmount(1766.38), '+1,766.38');
    });

    test('displayBillNumber 与金额格式化保持同一套规则', () {
      expect(displayBillNumber(12.30), '12.3');
      expect(displayBillNumber(1766.38), '1,766.38');
      expect(displayBillNumber(0), '0');
    });
  });

  group('收支类型映射', () {
    test('提现/充值类型优先按业务编码取图标', () {
      // 105 提现、106 充值不受金额正负影响。
      expect(getBillTypeIcon(type: 105, amount: 12), 'withdraw_02');
      expect(getBillTypeIcon(type: 105, amount: -12), 'withdraw_02');
      expect(getBillTypeIcon(type: 106, amount: -12), 'recharge');
      expect(getBillTypeIcon(type: 106, amount: 12), 'recharge');
      // 其余类型按金额方向兜底：正为入账、负为出账。
      expect(getBillTypeIcon(type: 3, amount: 8), 'recharge');
      expect(getBillTypeIcon(type: 3, amount: -8), 'withdraw_02');
      // 金额为 0 视为入账兜底。
      expect(getBillTypeIcon(type: 3, amount: 0), 'recharge');
    });

    testWidgets('账单类型文案按业务编码映射到对应多语种键', (tester) async {
      final labels = _zh_bill_labels();

      String text_of(int type) => getBillTypeText(type);
      final Map<int, String> expected = {
        3: labels['type_3']!,
        103: labels['type_103']!,
        104: labels['type_104']!,
        105: labels['type_105']!,
        106: labels['type_106']!,
        108: labels['type_108']!,
        109: labels['type_109']!,
        110: labels['type_110']!,
      };

      for (final entry in expected.entries) {
        expect(
          await label_in_context(tester, () => text_of(entry.key)),
          entry.value,
          reason: '账单类型 ${entry.key} 应映射到对应文案',
        );
      }

      // 未知类型走默认文案，不能把业务编码直接抛给用户。
      expect(
        await label_in_context(tester, () => text_of(999)),
        labels['type_default'],
      );
    });
  });

  group('账单时间展示', () {
    test('空值原样返回，非法时间不抛异常', () {
      expect(formatBillUpdateTime(''), '');
      expect(formatBillUpdateTime('not-a-time'), 'not-a-time');
    });

    test('UTC 时间字符串统一补齐时区标记后转本地显示', () {
      // 空格分隔的后端格式会被补成标准 UTC 再转本地。
      final text = formatBillUpdateTime('2026-01-01 00:00:00');
      expect(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(text), isTrue);

      // 已带 T/Z 的 ISO 串同样能解析。
      final iso = formatBillUpdateTime('2026-01-01T00:00:00Z');
      expect(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(iso), isTrue);
    });
  });
}
