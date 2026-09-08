import 'package:app/util/device/web_browser_info.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../components/app_wrapper/utils/app_router.dart';

/// 统一路由跳转入口。
///
/// [path] 目标路径。
/// [type] 跳转方式：
/// - `push`：压入新页面。
/// - `go`：替换栈顶。
/// - `replace`：替换当前页面。
///
/// 注意：push 在 Web 与移动端都必须走 GoRouter.push，而不能为了"改 URL"改用 go。
/// go 会替换栈顶并销毁上一页，从某些页面提交后若无法 pop，
/// 只能 replace 回原页面，会重建页面并重复请求；移动端 push 则保留
/// 原页面在栈中，pop 后仍是原 State，行为不一致。
void routerUtil({String path = '/', String type = 'push'}) {
  switch (type) {
    case 'go':
      AppRouter.go(path);
      return;
    case 'push':
      if (isMobileWebChromeOrSafari()) {
        openWebPageInNewTab(path);
        return;
      }
      AppRouter.push(path);
      return;
    case 'replace':
      if (kIsWeb) {
        // 判断当前是否为移动端浏览器环境中的 Chrome 或 Safari，
        // 如果是，用新标签页打开，因为无法进行 AppRouter.replace(path)。
        if (isMobileWebChromeOrSafari()) {
          openWebPageInNewTab(path);
          return;
        }
        AppRouter.replace(path);
        return;
      }
      if (_isShellRoutePath(path)) {
        AppRouter.go(path);
      } else {
        AppRouter.replace(path);
      }
      return;
    default:
      AppRouter.push(path);
  }
}

/// 判断目标路径是否属于 ShellRoute 页面。
///
/// [path] 目标路由路径。
bool _isShellRoutePath(String path) {
  final String targetPath = Uri.tryParse(path)?.path ?? path;
  return targetPath == '/' ||
      targetPath == '/message' ||
      targetPath == '/bookshelf' ||
      targetPath == '/user_info';
}
