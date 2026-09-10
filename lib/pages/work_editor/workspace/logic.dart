import 'package:flutter/foundation.dart';
import 'package:app/api/creator_workspace.dart';

// TODO 数字兼容MySQL返回的大整数与字符串统计值。
int creatorNumber(dynamic value) => int.tryParse('$value') ?? 0;
Map<String, dynamic> creatorMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> creatorRows(dynamic value) =>
    value is List ? value.map(creatorMap).toList() : [];

/* TODO 作品管理只保存元数据；目录按页加载，正文打开时另外请求。 */
class WorkspaceController extends ChangeNotifier {
  WorkspaceController(this.novelId);
  final int novelId;
  Map<String, dynamic> data = {};
  List<Map<String, dynamic>> chapters = [];
  bool busy = false;
  String? error;
  String filter = 'all';
  String keyword = '';
  int page = 1;
  bool hasMore = false;
  bool _disposed = false;
  int get languageId => creatorNumber(novel['novel_language_id']);
  Map<String, dynamic> get novel => creatorMap(data['novel']);
  Map<String, dynamic> get draft => creatorMap(data['draft']);
  Map<String, dynamic> get pending => creatorMap(data['pending_submission']);
  bool get isLong => creatorNumber(novel['work_type']) == 1;
  bool get isPublished => creatorNumber(novel['public_status']) == 2;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> refresh() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      data = await CreatorWorkspaceApi.call('creator_work/workspace', {
        'novel_id': novelId,
      });
      page = 1;
      if (isLong) await _directory(false);
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _directory(bool append) async {
    final result = await CreatorWorkspaceApi.call('creator_chapter/directory', {
      'novel_id': novelId,
      'novel_language_id': languageId,
      'page': page,
      'page_size': 50,
      'state': filter,
      'keyword': keyword,
    });
    chapters = [if (append) ...chapters, ...creatorRows(result['list'])];
    hasMore = result['has_more'] == true;
    data['counts'] = result['counts'];
  }

  Future<void> loadChapters({
    bool more = false,
    String? state,
    String? search,
  }) async {
    if (busy) return;
    final oldPage = page;
    busy = true;
    error = null;
    if (state != null) filter = state;
    if (search != null) keyword = search;
    page = more ? page + 1 : 1;
    notifyListeners();
    try {
      await _directory(more);
    } catch (e) {
      page = oldPage;
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
