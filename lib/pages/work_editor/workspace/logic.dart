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
  WorkspaceController(this.novelId, {this.call = CreatorWorkspaceApi.call});
  final int novelId;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
  call;
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
    if (_disposed || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next_data = await call('creator_work/workspace', {
        'novel_id': novelId,
      });
      if (_disposed) return;
      final next_novel = creatorMap(next_data['novel']);
      final directory = creatorNumber(next_novel['work_type']) == 1
          ? await _directory(
              requested_page: 1,
              requested_filter: filter,
              requested_keyword: keyword,
              language_id: creatorNumber(next_novel['novel_language_id']),
            )
          : null;
      if (_disposed) return;
      // 详情和目录一起提交，刷新失败不能让旧章节附着到新的作品语种。
      data = next_data;
      page = 1;
      if (directory != null) {
        _commit_directory(directory, append: false);
      } else {
        chapters = [];
        hasMore = false;
      }
    } catch (e) {
      if (!_disposed) error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// 查询使用不可变参数，成功前不改变当前目录的筛选和分页坐标。
  Future<Map<String, dynamic>> _directory({
    required int requested_page,
    required String requested_filter,
    required String requested_keyword,
    required int language_id,
  }) async {
    final result = await call('creator_chapter/directory', {
      'novel_id': novelId,
      'novel_language_id': language_id,
      'page': requested_page,
      'page_size': 50,
      'state': requested_filter,
      'keyword': requested_keyword,
    });
    if (result['list'] is! List) {
      throw const CreatorWorkspaceException('章节目录加载失败，请重试');
    }
    return result;
  }

  void _commit_directory(Map<String, dynamic> result, {required bool append}) {
    chapters = [if (append) ...chapters, ...creatorRows(result['list'])];
    hasMore = result['has_more'] == true;
    data['counts'] = result['counts'];
  }

  Future<void> loadChapters({
    bool more = false,
    String? state,
    String? search,
  }) async {
    if (_disposed || busy) return;
    final next_filter = state ?? filter;
    final next_keyword = search ?? keyword;
    final append = more && next_filter == filter && next_keyword == keyword;
    if (append && !hasMore) return;
    final next_page = append ? page + 1 : 1;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await _directory(
        requested_page: next_page,
        requested_filter: next_filter,
        requested_keyword: next_keyword,
        language_id: languageId,
      );
      if (_disposed) return;
      _commit_directory(result, append: append);
      page = next_page;
      filter = next_filter;
      keyword = next_keyword;
    } catch (e) {
      if (!_disposed) error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
