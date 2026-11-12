import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

/// TODO 真实字节进度输出；未知总量仅显示活动条，stdout 始终留给机器协议。
class CliProgress {
  CliProgress(
    this.label, {
    int? total_bytes,
    this.show_bytes = true,
    bool? terminal,
    void Function(String)? write,
    DateTime Function()? now,
    Duration? interval,
    bool automatic_heartbeat = true,
  }) : _total_bytes = total_bytes,
       // TODO 默认逐行输出，避免长文件名换行和父子进程刷新造成覆盖、拼接。
       terminal = terminal ?? false,
       _write = write ?? stderr.write,
       _now = now ?? DateTime.now {
    if (total_bytes != null && total_bytes < 0) {
      throw ArgumentError.value(total_bytes, 'total_bytes', '不能小于零');
    }
    _interval = interval ?? Duration(seconds: this.terminal ? 1 : 5);
    if (_interval.isNegative) {
      throw ArgumentError.value(interval, 'interval', '不能小于零');
    }
    _started = _now();
    _last_output = _started;
    _render(force: true);
    if (automatic_heartbeat && _interval > Duration.zero) {
      _heartbeat = Timer.periodic(_interval, (_) => heartbeat());
    }
  }

  final String label;
  final bool show_bytes;
  int? _total_bytes;
  final bool terminal;
  final void Function(String) _write;
  final DateTime Function() _now;
  late final Duration _interval;
  late final DateTime _started;
  late DateTime _last_output;
  Timer? _heartbeat;
  int _bytes = 0;
  int _tick = 0;
  bool _closed = false;
  String _note = '开始';

  int get processed_bytes => _bytes;
  int? get total_bytes => _total_bytes;
  bool get is_closed => _closed;

  /// TODO 收到响应头后补充服务端给出的总量；未知长度不推算百分比。
  void set_total_bytes(int? count) {
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'count', '不能小于零');
    }
    if (_closed) return;
    _total_bytes = count;
    _render(force: true);
  }

  /// TODO 仅记录调用方实际处理的字节，完成不会把未传输的字节补成总量。
  void add_bytes(int count) => set_bytes(_bytes + count);

  void set_bytes(int count) {
    if (count < _bytes) {
      throw ArgumentError.value(count, 'count', '进度不能倒退，请为重试新建进度条');
    }
    if (_closed) return;
    _bytes = count;
    if (_note == '开始') _note = '进行中';
    _render();
  }

  /// TODO 在等待响应或校验阶段显示真实状态，不用伪造百分比表示等待。
  void set_note(String note) {
    if (_closed) return;
    _note = note;
    _render(force: true);
  }

  /// TODO 即使没有新字节也定时输出耗时，让网络等待与编译等待保持可见。
  void heartbeat() {
    if (_closed) return;
    _tick++;
    if (_note == '开始') _note = '进行中';
    _render(force: true);
  }

  Stream<List<int>> track_stream(Stream<List<int>> source) =>
      source.map((chunk) {
        add_bytes(chunk.length);
        return chunk;
      });

  void complete([String? note]) => _finish(note ?? '完成');
  void fail([String? note]) => _finish(note ?? '失败');

  void _finish(String note) {
    if (_closed) return;
    _closed = true;
    _heartbeat?.cancel();
    _note = note;
    _render(force: true, finished: true);
  }

  void _render({bool force = false, bool finished = false}) {
    final current = _now();
    if (!force && current.difference(_last_output) < _interval) return;
    _last_output = current;
    const width = 16;
    final total = total_bytes;
    final ratio = total == null
        ? null
        : total == 0
        ? 1.0
        : (_bytes / total).clamp(0.0, 1.0);
    final bar = ratio == null
        ? '${' ' * (_tick % width)}>${' ' * (width - 1 - _tick % width)}'
        : '${'=' * (ratio * width).floor()}${' ' * (width - (ratio * width).floor())}';
    final amount = !show_bytes
        ? ''
        : total == null
        ? '${_megabytes(_bytes)} MB / 大小未知'
        : '${(ratio! >= 1 ? 100.0 : math.min(99.9, ratio * 100)).toStringAsFixed(1)}% ${_megabytes(_bytes)} / ${_megabytes(total)} MB';
    final elapsed = math.max(0, current.difference(_started).inSeconds);
    final time =
        '${elapsed ~/ 60}分${(elapsed % 60).toString().padLeft(2, '0')}秒';
    final line =
        '[进度] ${_clean(label)} [$bar]${amount.isEmpty ? '' : ' $amount'} · $time · ${_clean(_note)}';
    _write(terminal ? '\r\x1b[2K$line${finished ? '\n' : ''}' : '$line\n');
  }

  String _megabytes(int count) => (count / (1024 * 1024)).toStringAsFixed(2);
  String _clean(String text) =>
      text.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ');
}
// TODO 当前应用脚本统一使用 snake_case，保留与发布流程一致的公开接口。
// ignore_for_file: non_constant_identifier_names
