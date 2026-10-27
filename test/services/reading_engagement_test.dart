import 'dart:async';

import 'package:app/services/reading_engagement/index.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only consecutive foreground body samples accrue monotonic seconds', () {
    final tracker = ReadingEngagementTracker(user_id: 1, novel_id: 7);
    tracker.sample(active: false, monotonic_ms: 0);
    tracker.sample(active: false, monotonic_ms: 100000);
    expect(tracker.seconds, 0);
    tracker.sample(active: true, monotonic_ms: 100000);
    for (var time = 100250; time <= 105000; time += 250) {
      tracker.sample(active: true, monotonic_ms: time);
    }
    expect(tracker.seconds, 5);
    tracker.sample(active: false, monotonic_ms: 105250);
    tracker.sample(active: false, monotonic_ms: 205250);
    tracker.sample(active: true, monotonic_ms: 205250);
    tracker.sample(active: true, monotonic_ms: 205500);
    expect(tracker.seconds, 5);
    tracker.sample(active: true, monotonic_ms: 305500);
    expect(
      tracker.seconds,
      6,
      reason: 'a suspended timer cannot credit a long gap',
    );
    tracker.sample(active: true, monotonic_ms: 100);
    expect(
      tracker.seconds,
      6,
      reason: 'clock reversal never subtracts or adds time',
    );
  });

  test(
    'introduction, popup/covered route, background and pause never accrue',
    () async {
      var now = 0;
      var visible = false;
      final sent = <ReadingHeartbeat>[];
      final controller = ReadingEngagementController(
        identity: () => (user_id: 1, novel_id: 7),
        is_body_visible: () => visible,
        monotonic_ms: () => now,
        schedule_timer: false,
        sender: (heartbeat) async {
          sent.add(heartbeat);
          return true;
        },
      );
      void advance(int milliseconds) {
        final end = now + milliseconds;
        while (now < end) {
          now += 250;
          controller.sample();
        }
      }

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      advance(10000);
      expect(sent, isEmpty);
      visible = true;
      controller.sample();
      await Future<void>.delayed(Duration.zero);
      expect(
        sent.single.seconds,
        0,
        reason: 'register a zero-time server anchor before counting',
      );
      advance(10000);
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.seconds, 10);
      visible = false;
      controller.sample();
      advance(10000);
      visible = true;
      controller.sample();
      advance(5000);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.seconds, 15);
      advance(60000);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      advance(5000);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.seconds, 20);
      expect(
        sent.map((heartbeat) => heartbeat.session_id).toSet(),
        hasLength(1),
      );
    },
  );

  test(
    'switching stories snapshots the original work, account switches drop old requests',
    () async {
      var now = 0;
      ReadingIdentity? current = (user_id: 1, novel_id: 7);
      final sent = <ReadingHeartbeat>[];
      final controller = ReadingEngagementController(
        identity: () => current,
        is_body_visible: () => true,
        monotonic_ms: () => now,
        schedule_timer: false,
        sender: (heartbeat) async {
          sent.add(heartbeat);
          return true;
        },
      );
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      for (var i = 0; i < 20; i++) {
        now += 250;
        controller.sample();
      }
      current = (user_id: 1, novel_id: 8);
      controller.sample();
      await Future<void>.delayed(Duration.zero);
      expect(
        sent.any((event) => event.novel_id == 7 && event.seconds == 5),
        isTrue,
      );
      expect(sent.last.novel_id, 8);
      expect(sent.last.seconds, 0);
      current = (user_id: 2, novel_id: 8);
      controller.sample();
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.user_id, 2);
      expect(sent.map((event) => event.session_id).toSet(), hasLength(3));
      controller.dispose();
    },
  );

  test(
    'failed heartbeats retry cumulative values and in-flight snapshots stay immutable',
    () async {
      var now = 0;
      final gate = Completer<bool>();
      final sent = <ReadingHeartbeat>[];
      final controller = ReadingEngagementController(
        identity: () => (user_id: 1, novel_id: 7),
        is_body_visible: () => true,
        monotonic_ms: () => now,
        schedule_timer: false,
        sender: (heartbeat) async {
          sent.add(heartbeat);
          return sent.length == 1 ? await gate.future : true;
        },
      );
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      for (var i = 0; i < 40; i++) {
        now += 250;
        controller.sample();
      }
      expect(sent, hasLength(1));
      expect(sent.single.seconds, 0);
      gate.complete(false);
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 40; i++) {
        now += 250;
        controller.sample();
      }
      await Future<void>.delayed(Duration.zero);
      expect(sent.last.seconds, 20);
      expect(sent.last.session_id, sent.first.session_id);
      controller.dispose();
    },
  );

  test(
    'failed old-account request cannot delay the new-account zero-second anchor',
    () async {
      ReadingIdentity? current = (user_id: 1, novel_id: 7);
      final old_request = Completer<bool>();
      final sent = <ReadingHeartbeat>[];
      final controller = ReadingEngagementController(
        identity: () => current,
        is_body_visible: () => true,
        monotonic_ms: () => 0,
        schedule_timer: false,
        sender: (heartbeat) async {
          sent.add(heartbeat);
          return heartbeat.user_id == 1 ? await old_request.future : true;
        },
      );
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      current = (user_id: 2, novel_id: 7);
      controller.sample();
      expect(sent, hasLength(1));
      old_request.complete(false);
      await Future<void>.delayed(Duration.zero);
      expect(sent, hasLength(2));
      expect(sent.last.user_id, 2);
      expect(sent.last.seconds, 0);
      controller.dispose();
    },
  );
}
