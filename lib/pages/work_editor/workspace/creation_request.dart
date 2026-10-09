import 'package:app/api/creator_workspace.dart';
import '../single_chapter/logic.dart';
import 'logic.dart';

/// 创建结果未知时固定原请求，不能因编辑参数而重复创建另一部作品。
class WorkspaceCreationRequest {
  WorkspaceCreationRequest({this.call = CreatorWorkspaceApi.call});

  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
  call;
  Map<String, dynamic>? _pending;

  /// 未确认的请求期间锁定表单，仅开放同一操作的重试。
  bool get has_pending => _pending != null;

  Future<Map<String, dynamic>> create({
    required String title,
    required int work_type,
    required int language_id,
  }) async {
    _pending ??= {
      'title': title,
      'work_type': work_type,
      'work_language_id': language_id,
      'request_key': creatorRequestKey(),
    };
    try {
      final result = await call('creator_work/create_draft', Map.of(_pending!));
      if (creatorNumber(result['novel_id']) <= 0) {
        throw const CreatorWorkspaceException('作品创建结果尚未确认，请重试');
      }
      _pending = null;
      return result;
    } catch (error) {
      if (error is CreatorWorkspaceException && error.serverRejected) {
        _pending = null;
      }
      rethrow;
    }
  }
}
