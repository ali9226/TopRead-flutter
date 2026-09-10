import 'package:app/api/post_request.dart';

/* TODO 创作工作台统一请求边界。请求失败抛出可读错误，客户端不能把失败当作保存成功。 */
class CreatorWorkspaceApi {
  static Future<Map<String, dynamic>> call(
    String path,
    Map<String, dynamic> parameters,
  ) async {
    final result = await postRequest<Map<String, dynamic>>(
      path: path,
      showTips: false,
      parameter: parameters,
      fromJson: (json) => json,
    );
    if (!result.status || result.content == null) {
      throw CreatorWorkspaceException(
        result.message.trim().isEmpty ? '保存失败，请保留本机内容后重试' : result.message,
        serverRejected: result.serverRejected,
      );
    }
    return result.content!;
  }
}

// TODO 请求失败和版本冲突统一保留服务端说明。
class CreatorWorkspaceException implements Exception {
  const CreatorWorkspaceException(this.message, {this.serverRejected = false});
  final bool serverRejected;
  final String message;
  @override
  String toString() => message;
}
