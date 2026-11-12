import 'dart:async';
import 'dart:convert';

import 'package:flutter_patcher/src/cli/build_progress.dart';
import 'package:flutter_patcher/src/cli/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('总体进度按完成阶段前进，失败不会显示全部完成', () {
    final output = StringBuffer();
    final progress = BuildProgress(
      ['prepare', 'ipa', 'archive'],
      write: output.write,
      terminal: false,
      automatic_heartbeat: false,
    );
    progress.enter('prepare');
    progress.enter('prepare');
    progress.enter('ipa');
    progress.fail();
    expect('步骤 1/3'.allMatches(output.toString()).length, 1);
    expect(output.toString(), contains('1/3 · 当前阶段未完成'));
    expect(output.toString(), isNot(contains('3/3 · 构建')));
    expect(output.toString(), isNot(contains('MB')));
  });

  test('归档完成后才显示总体完成，完成操作幂等', () {
    final output = StringBuffer();
    final progress = BuildProgress(
      ['prepare', 'archive', 'publish-output'],
      write: output.write,
      terminal: false,
      automatic_heartbeat: false,
    );
    for (final phase in progress.phases) {
      progress.enter(phase);
    }
    expect(output.toString(), isNot(contains('3/3 · 构建')));
    progress.complete();
    progress.complete();
    expect('3/3 · 构建'.allMatches(output.toString()).length, 1);
  });

  test('桥接进度在流结束前透传，跨UTF8分块不损坏，保留预期404诊断', () async {
    final source = StreamController<List<int>>();
    final output = StringBuffer();
    final first_progress = Completer<void>();
    final captured = collect_progress_output(
      source.stream,
      write: (text) {
        output.write(text);
        if (!first_progress.isCompleted) first_progress.complete();
      },
    );
    const text = '[进度] 上传基线 [==  ] 50.0%\n';
    final bytes = utf8.encode(text);
    source.add(bytes.sublist(0, 3));
    source.add(bytes.sublist(3, 5));
    source.add(bytes.sublist(5));
    await first_progress.future.timeout(const Duration(seconds: 2));
    expect(output.toString(), text);
    source.add(utf8.encode('An error occurred (NoSuchKey)\n'));
    source.add(utf8.encode('\r\x1b[2K[进度] 上传完成\n'));
    await source.close();
    final diagnostic = await captured;
    expect(output.toString(), contains('[进度] 上传完成'));
    expect(output.toString(), isNot(contains('NoSuchKey')));
    expect(diagnostic, contains('NoSuchKey'));
    expect(diagnostic, isNot(contains('�')));
  });
}
