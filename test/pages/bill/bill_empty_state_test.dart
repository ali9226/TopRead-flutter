// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/models/user_bill.dart';
import 'package:app/pages/bill/style.dart';
import 'package:app/pages/bill/utils/display_bill_number.dart';
import 'package:app/pages/bill/widgets/bill_empty_state.dart';
import 'package:app/pages/bill/widgets/bill_page_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 复用仓库内真实多语种资源，空态文案直接来自 i18n。
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

  testWidgets('空账单列表展示空态并可触发重新加载', (tester) async {
    final labels = _zh_bill_labels();
    var reloads = 0;

    await tester.pumpWidget(
      _localized_home(
        SizedBox(
          width: 400,
          height: 800,
          child: BillPageContent(
            isDark: false,
            loading: false,
            hasMore: false,
            list: const <UserBillItem>[],
            scrollController: ScrollController(),
            padding: EdgeInsets.zero,
            onRefresh: () async => reloads++,
            onLoadMore: () {},
            onCopySerialNumber: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 空列表且非加载态时展示空状态卡片。
    expect(find.text(labels['empty']!), findsOneWidget);
    expect(find.text(displayBillNumber(0)), findsOneWidget);

    // 点击重新加载按钮必须回调父页面。
    // 按钮文案键 `bill.reload` 目前未进多语种资源，这里按按钮类型定位。
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(reloads, 1);
  });

  testWidgets('空态组件深浅色均可渲染', (tester) async {
    for (final is_dark in <bool>[false, true]) {
      var tapped = false;
      await tester.pumpWidget(
        _localized_home(
          SizedBox(
            width: 400,
            child: BillEmptyState(
              isDark: is_dark,
              emptyNumberText: '0',
              onReload: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BillEmptyState), findsOneWidget);
      expect(tapped, isFalse);
    }
  });

  test('账单页样式常量导出并复用全局布局阶梯', () {
    // 单页条数同时驱动接口 page_size 与前端分页判断。
    expect(Style.pageSize, 20);
    // 页面横向边距引用全局配置。
    expect(Style.pageHorizontalPadding, greaterThan(0));
    // 首次加载骨架与列表间距可被子组件复用。
    expect(Style.heroBottomSpacing, greaterThan(0));
    expect(Style.listBottomSpacing, greaterThan(0));
    expect(Style.loadingCardRadius, greaterThan(0));
  });
}
