// ignore_for_file: non_constant_identifier_names

import 'package:app/components/app_wrapper/utils/app_router.dart';

/// TODO 处理海报点击跳转逻辑。
///
/// 根据jump字段判断跳转类型:
/// 1. 如果jump为空,不执行任何操作
/// 2. 如果是外部网址(http://或https://开头),跳转到WebView页面
/// 3. 如果是内部路由(如/ranking_full_list),直接路由跳转
/// 4. 如果带参数(如/ranking_full_list?type=1),解析参数后跳转
///
/// 参数 [jump]:
/// 跳转字段,可能是空字符串、外部网址或内部路由路径。
void handle_banner_jump(String jump) {
  /// TODO 如果jump为空,不需要跳转。
  if (jump.trim().isEmpty) {
    return;
  }

  /// TODO 判断是否为外部网址。
  final bool is_external_url = jump.startsWith('http://') ||
                               jump.startsWith('https://');

  if (is_external_url) {
    /// TODO 跳转到WebView页面,URL编码后作为参数传递。
    /// 使用 push 因为 WebView 是独立页面,需要保留在路由栈中供后退返回。
    final encoded_url = Uri.encodeComponent(jump);
    AppRouter.push('/web_view?url=$encoded_url');
  } else {
    /// TODO 内部路由跳转。
    /// 解析路径和查询参数,使用 go 而不是 push,
    /// 因为 ShellRoute 架构下 push 会破坏路由栈,导致后退行为异常。
    final Uri uri = Uri.parse(jump);
    final String path = uri.path;
    final String query = uri.query;
    final String location = query.isNotEmpty ? '$path?$query' : path;
    AppRouter.go(location);
  }
}
