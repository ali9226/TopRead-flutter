// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/pages/customer_service_chat/logic.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/models/user_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserInformation user;
  setUp(() {
    user = Get.put(UserInformation())
      ..saveUserInfo(UserInfo.fromJson({'id': 1}));
  });
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

  for (final bool fail_upload in [true, false]) {
    test('换号后旧图片上传${fail_upload ? '失败' : '成功'}不得改动或发送新会话', () async {
      final store = _FakeCustomerServiceChatHistoryStore();
      Get.put<CustomerServiceChatHistoryStore>(store);
      final upload = Completer<String?>();
      final sent = <String>[];
      final logic = ChatLogic(
        () {},
        image_uploader: (_) => upload.future,
        message_sender: ({required message_type, required content}) =>
            sent.add(content),
      );
      addTearDown(logic.dispose);
      logic.send_image_messages(['/old-user-image.jpg']);
      user.saveUserInfo(UserInfo.fromJson({'id': 2}));
      if (fail_upload) {
        upload.complete(null);
      } else {
        upload.complete('https://example.com/old-user-image.jpg');
      }
      await Future<void>.delayed(Duration.zero);
      expect(sent, isEmpty);
      expect(store.upload_updates, 0);
    });
  }

  test('同用户离开聊天页后图片上传仍可完成并发送', () async {
    final store = _FakeCustomerServiceChatHistoryStore();
    Get.put<CustomerServiceChatHistoryStore>(store);
    final upload = Completer<String?>();
    final sent = <String>[];
    final logic = ChatLogic(
      () {},
      image_uploader: (_) => upload.future,
      message_sender: ({required message_type, required content}) =>
          sent.add(content),
    );
    logic.send_image_messages(['/current-user-image.jpg']);
    logic.dispose();
    upload.complete('https://example.com/current-user-image.jpg');
    await Future<void>.delayed(Duration.zero);
    expect(sent, ['https://example.com/current-user-image.jpg']);
    expect(store.upload_updates, 1);
  });

  test('访客身份未变化时仍支持上传客服图片', () async {
    user.clearUserInfo();
    final store = _FakeCustomerServiceChatHistoryStore();
    Get.put<CustomerServiceChatHistoryStore>(store);
    final sent = <String>[];
    final logic = ChatLogic(
      () {},
      image_uploader: (_) async => 'https://example.com/visitor-image.jpg',
      message_sender: ({required message_type, required content}) =>
          sent.add(content),
    );
    addTearDown(logic.dispose);
    logic.send_image_messages(['/visitor-image.jpg']);
    await Future<void>.delayed(Duration.zero);
    expect(sent, ['https://example.com/visitor-image.jpg']);
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
  int upload_updates = 0;

  @override
  void mark_image_upload_complete(int local_id, String server_url) {
    upload_updates++;
  }

  @override
  void mark_image_upload_failed(int local_id) {
    upload_updates++;
  }

  @override
  void register_pending_confirmation(int local_id) {}

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
