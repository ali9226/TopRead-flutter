// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/pages/customer_service_chat/logic.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';

void main() {
  tearDown(Get.reset);

  test('反向列表下拉到历史边缘时触发加载', () {
    final _FakeCustomerServiceChatHistoryStore store =
        _FakeCustomerServiceChatHistoryStore();
    Get.put<CustomerServiceChatHistoryStore>(store);
    final ChatLogic logic = ChatLogic(() {});

    logic.handle_scroll_notification(
      ScrollStartNotification(metrics: _metrics(pixels: 1000), context: null),
    );

    expect(store.load_more_count, 1);
    logic.dispose();
  });

  test('未到历史边缘时不发起分页请求', () {
    final _FakeCustomerServiceChatHistoryStore store =
        _FakeCustomerServiceChatHistoryStore();
    Get.put<CustomerServiceChatHistoryStore>(store);
    final ChatLogic logic = ChatLogic(() {});

    logic.handle_scroll_notification(
      ScrollStartNotification(metrics: _metrics(pixels: 300), context: null),
    );

    expect(store.load_more_count, 0);
    logic.dispose();
  });

  test('聊天数据变化只刷新消息区域，不触发页面级重建', () {
    final _FakeCustomerServiceChatHistoryStore store =
        _FakeCustomerServiceChatHistoryStore();
    Get.put<CustomerServiceChatHistoryStore>(store);
    int page_update_count = 0;
    final ChatLogic logic = ChatLogic(() => page_update_count++);

    store.add_local_message(message_type: 1, content: '测试消息');

    expect(page_update_count, 0);
    logic.dispose();
  });
}

FixedScrollMetrics _metrics({required double pixels}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 1000,
    pixels: pixels,
    viewportDimension: 600,
    axisDirection: AxisDirection.up,
    devicePixelRatio: 1,
  );
}

class _FakeCustomerServiceChatHistoryStore
    extends CustomerServiceChatHistoryStore {
  int load_more_count = 0;

  @override
  bool get has_more_history => true;

  @override
  bool get is_loading_more => false;

  @override
  Future<void> open_conversation() async {}

  @override
  void close_conversation() {}

  @override
  Future<void> load_more_history() async {
    load_more_count++;
  }
}
