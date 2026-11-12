import 'dart:async';

import 'package:flutter_patcher/src/cli/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('默认长文件名进度逐行输出，未收齐字节不提前舍入到100%', () {
    final output = <String>[];
    final progress = CliProgress(
      'OBS 下载 compile-${'a' * 64}.tar.gz',
      total_bytes: 10000,
      write: output.add,
      interval: Duration.zero,
      automatic_heartbeat: false,
    );
    progress.set_bytes(9999);
    expect(progress.terminal, isFalse);
    expect(output.last, contains('99.9%'));
    expect(output.join(), isNot(contains('100.0%')));
    progress.set_bytes(10000);
    progress.complete();
    expect(output.last, contains('100.0%'));
    expect(
      output.every((line) => line.endsWith('\n') && !line.contains('\r')),
      isTrue,
    );
  });
  test('已知总量按真实字节显示百分比，失败不会补成百分之百', () {
    final output = <String>[];
    var now = DateTime.utc(2026, 11, 12);
    final progress = CliProgress(
      '上传 baseline.tar.gz',
      total_bytes: 1024 * 1024,
      terminal: false,
      write: output.add,
      now: () => now,
      automatic_heartbeat: false,
    );
    now = now.add(const Duration(seconds: 5));
    progress.add_bytes(256 * 1024);
    progress.fail();
    expect(output.last, contains('25.0% 0.25 / 1.00 MB'));
    expect(output.last, contains('0分05秒'));
    expect(output.last, contains('失败'));
    expect(output.join(), isNot(contains('100.0%')));
    expect(output.every((line) => line.startsWith('[进度] ')), isTrue);
  });

  testWidgets('未知总量与编译阶段不伪造百分比，心跳定时输出且结束后停止', (tester) async {
    final output = <String>[];
    final progress = CliProgress(
      '编译 iOS',
      show_bytes: false,
      terminal: false,
      write: output.add,
      now: tester.binding.clock.now,
    );
    await tester.pump(const Duration(seconds: 16));
    expect(output.length, 4);
    expect(output.last, contains('0分15秒'));
    expect(output.join(), isNot(contains('%')));
    expect(output.join(), isNot(contains('MB')));
    progress.complete();
    final finished = output.length;
    await tester.pump(const Duration(minutes: 1));
    expect(output.length, finished);
    expect(progress.is_closed, isTrue);
  });

  test('TTY刷新当前行，流计数保留原字节，成功完成后换行', () async {
    final output = <String>[];
    final progress = CliProgress(
      '下载 patch.fptc',
      terminal: true,
      write: output.add,
      automatic_heartbeat: false,
    );
    progress.set_total_bytes(5);
    final chunks = await progress
        .track_stream(
          Stream.fromIterable([
            [1, 2],
            [3, 4, 5],
          ]),
        )
        .toList();
    progress.set_note('校验文件');
    progress.complete();
    expect(chunks, [
      [1, 2],
      [3, 4, 5],
    ]);
    expect(progress.processed_bytes, 5);
    expect(output.last, startsWith('\r\x1b[2K[进度] '));
    expect(output.last, contains('100.0%'));
    expect(output.last, endsWith('\n'));
  });

  test('非TTY输出按间隔节流，未知长度不报告百分比', () {
    final output = <String>[];
    var now = DateTime.utc(2026, 11, 12);
    final progress = CliProgress(
      '回读 SHA256',
      terminal: false,
      write: output.add,
      now: () => now,
      automatic_heartbeat: false,
    );
    for (var chunk = 0; chunk < 100; chunk++) {
      progress.add_bytes(1024);
    }
    expect(output.length, 1);
    now = now.add(const Duration(seconds: 5));
    progress.heartbeat();
    expect(output.length, 2);
    expect(output.last, contains('大小未知'));
    expect(output.last, isNot(contains('%')));
    progress.complete();
  });
}
