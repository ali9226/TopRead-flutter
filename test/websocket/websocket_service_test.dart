import 'dart:async';
import 'dart:convert';

import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/websocket/websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test('设备 UUID 并发初始化只准备一次，所有调用获得同一持久身份', () async {
    final Completer<String> pending = Completer<String>();
    int loads = 0;
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => null,
      channel_factory: (_) => _TestChannel(),
      visitor_id_loader: () {
        loads++;
        return pending.future;
      },
    );
    addTearDown(service.dispose);
    final Future<String> first = service.get_or_create_visitor_uuid();
    final Future<String> second = service.get_or_create_visitor_uuid();
    expect(loads, 1);
    pending.complete('stable-device');
    expect(await first, 'stable-device');
    expect(await second, 'stable-device');
    expect(await service.get_or_create_visitor_uuid(), 'stable-device');
    expect(loads, 1);
  });

  test('设备 UUID 准备失败后可以重新准备', () async {
    int loads = 0;
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => null,
      channel_factory: (_) => _TestChannel(),
      visitor_id_loader: () async {
        if (++loads == 1) throw StateError('storage unavailable');
        return 'stable-device';
      },
    );
    addTearDown(service.dispose);
    await expectLater(service.get_or_create_visitor_uuid(), throwsStateError);
    expect(await service.get_or_create_visitor_uuid(), 'stable-device');
    expect(loads, 2);
  });

  test('旧通道关闭期间的迟到消息不能进入新连接消息流', () async {
    final List<_TestChannel> channels = <_TestChannel>[];
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => 'token',
      channel_factory: (Uri uri) {
        final _TestChannel channel = _TestChannel();
        channels.add(channel);
        return channel;
      },
    );
    addTearDown(() async {
      service.dispose();
      for (final _TestChannel channel in channels) {
        await channel.incoming.close();
      }
    });
    final List<int> received_ids = <int>[];
    service.message_stream.listen((Map<String, dynamic> message) {
      received_ids.add(message['id'] as int);
    });
    await service.connect();
    channels[0].incoming.add(jsonEncode(<String, dynamic>{'id': 1}));
    service.disconnect();
    await service.connect();
    channels[0].incoming.add(jsonEncode(<String, dynamic>{'id': 2}));
    channels[1].incoming.add(jsonEncode(<String, dynamic>{'id': 3}));
    await Future<void>.delayed(Duration.zero);

    expect(received_ids, <int>[1, 3]);
    expect(service.is_connected, isTrue);
  });

  test('身份切换后即使旧连接尚未关闭也不能收发旧账号消息', () async {
    final UserInformation user_information = Get.put(UserInformation());
    user_information.saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 1}),
    );
    final _TestChannel channel = _TestChannel();
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => 'first-token',
      channel_factory: (Uri uri) => channel,
    );
    addTearDown(() async {
      service.dispose();
      await channel.incoming.close();
    });
    final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];
    service.message_stream.listen(messages.add);
    await service.connect();
    expect(service.send(<String, dynamic>{'type': 'first'}), isTrue);
    user_information.saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 2}),
    );
    channel.incoming.add(jsonEncode(<String, dynamic>{'type': 'old-unread'}));

    expect(service.send(<String, dynamic>{'type': 'new-chat'}), isFalse);
    expect(messages, isEmpty);
    expect(channel.output.values, hasLength(1));
  });

  test('迟到访客身份准备不会改写已连接用户的模式或创建旧通道', () async {
    final Completer<String> visitor_id = Completer<String>();
    int token_reads = 0;
    final List<Uri> requested_uris = <Uri>[];
    final _TestChannel channel = _TestChannel();
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => ++token_reads == 1 ? null : 'user-token',
      visitor_id_loader: () => visitor_id.future,
      channel_factory: (Uri uri) {
        requested_uris.add(uri);
        return channel;
      },
    );
    addTearDown(() async {
      service.dispose();
      await channel.incoming.close();
    });
    final Future<void> visitor_connect = service.connect();
    await Future<void>.delayed(Duration.zero);
    service.disconnect();
    await service.connect();
    expect(service.is_visitor, isFalse);
    visitor_id.complete('late-visitor');
    await visitor_connect;

    expect(service.is_visitor, isFalse);
    expect(service.is_connected, isTrue);
    expect(requested_uris, hasLength(1));
    expect(requested_uris.single.queryParameters['token'], 'user-token');
  });

  test('旧通道握手完成和关闭回调不会断开替换后的连接', () async {
    final _TestChannel old_channel = _TestChannel(ready: false);
    final _TestChannel new_channel = _TestChannel();
    int connections = 0;
    final WebSocketService service = WebSocketService.for_test(
      token_loader: () async => 'token',
      channel_factory: (Uri uri) =>
          ++connections == 1 ? old_channel : new_channel,
    );
    addTearDown(() async {
      service.dispose();
      await old_channel.incoming.close();
      await new_channel.incoming.close();
    });
    final Future<void> old_connect = service.connect();
    await Future<void>.delayed(Duration.zero);
    service.disconnect();
    await service.connect();
    old_channel.handshake.complete();
    await old_connect;
    await old_channel.incoming.close();

    expect(service.is_connected, isTrue);
    expect(service.send(<String, dynamic>{'type': 'current'}), isTrue);
    expect(new_channel.output.values, hasLength(1));
  });
}

/// 保持关闭期间仍可投递的入站流，用于复现真实 socket 的排队回调。
class _TestChannel implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>(
    sync: true,
  );
  final Completer<void> handshake = Completer<void>();
  final _TestSink output = _TestSink();

  _TestChannel({bool ready = true}) {
    if (ready) handshake.complete();
  }

  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  WebSocketSink get sink => output;
  @override
  Future<void> get ready => handshake.future;
  @override
  String? get protocol => null;
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSink implements WebSocketSink {
  final List<dynamic> values = <dynamic>[];
  @override
  void add(dynamic data) => values.add(data);
  @override
  Future<void> close([int? close_code, String? close_reason]) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
