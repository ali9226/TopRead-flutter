import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/util/log_util.dart';

/// FCM 推送消息处理。
///
/// 负责处理用户点击推送通知后的业务逻辑。
/// 根据推送数据中的 type 字段，执行不同的操作。
///
/// 推送类型定义：
/// - type=1: 无操作，仅展示通知，点击后打开 App 首页
/// - type=2: 跳转页面，需要 route 参数
/// - type=3: 跳转到小说详情页
/// - type=4: 跳转到小说详情页并打开评论列表，定位到指定评论
class FcmHandler {
  /// 推送类型常量
  static const String typeNoAction = '1';
  static const String typeNavigate = '2';
  static const String typeNovelDetail = '3';
  static const String typeNovelComment = '4';

  /// 处理用户点击推送通知。
  ///
  /// [data] 推送消息中的自定义数据。
  /// 当用户点击通知打开 App 时调用（前台/后台/终止状态）。
  static void onMessageTap(Map<String, dynamic> data) {
    logUtil(msg: 'FCM: 用户点击通知，数据: $data');

    final String type = data['type'] ?? typeNoAction;

    switch (type) {
      case typeNoAction:
        _handleNoAction(data);
        break;
      case typeNavigate:
        _handleNavigate(data);
        break;
      case typeNovelDetail:
        _handleNovelDetail(data);
        break;
      case typeNovelComment:
        _handleNovelComment(data);
        break;
      default:
        logUtil(msg: 'FCM: 未知的推送类型: $type');
        _handleNoAction(data);
        break;
    }
  }

  /// 处理无操作类型的推送。
  ///
  /// 仅展示通知，点击后打开 App 首页。
  static void _handleNoAction(Map<String, dynamic> data) {
    logUtil(msg: 'FCM: 无操作类型，打开首页');
    _navigateTo('/');
  }

  /// 处理跳转页面类型的推送。
  ///
  /// 根据 data 中的 route 参数跳转到指定页面。
  static void _handleNavigate(Map<String, dynamic> data) {
    final String route = data['route'] ?? '/';
    logUtil(msg: 'FCM: 跳转到路由: $route');
    _navigateTo(route);
  }

  /// 处理跳转到小说详情页类型的推送。
  ///
  /// 根据 data 中的 novel_id 和 publish_status 跳转到小说详情页。
  static void _handleNovelDetail(Map<String, dynamic> data) {
    final String novelId = data['novel_id'] ?? '';
    final String publishStatus = data['publish_status'] ?? '1';

    if (novelId.isEmpty) {
      logUtil(msg: 'FCM: novel_id 为空，跳过跳转');
      return;
    }

    logUtil(msg: 'FCM: 跳转到小说详情页，novelId=$novelId, publishStatus=$publishStatus');

    // 根据发布状态决定跳转路径
    // publish_status: 1=连载中, 2=已完结, 3=下架, 4=短篇小说
    if (publishStatus == '4') {
      _navigateTo('/short_story_read?id=$novelId');
    } else {
      _navigateTo('/read?id=$novelId');
    }
  }

  /// 处理跳转到小说详情页并打开评论列表类型的推送。
  ///
  /// 根据 data 中的 novel_id、publish_status 和 top_comment_id 跳转到小说详情页，
  /// 并自动打开评论列表，定位到指定评论（顶层评论置顶显示）。
  static void _handleNovelComment(Map<String, dynamic> data) {
    final String novelId = data['novel_id'] ?? '';
    final String publishStatus = data['publish_status'] ?? '1';
    final String parentId = data['parent_id'] ?? '';
    final String commentId = data['comment_id'] ?? '';
    final String messageId = data['message_id'] ?? '';

    if (novelId.isEmpty) {
      logUtil(msg: 'FCM: novel_id 为空，跳过跳转');
      return;
    }

    // comment_id 用于定位具体评论（后端 inquire 会自动找到其顶层父评论并置顶）
    final String targetCommentId = commentId.isNotEmpty ? commentId : parentId;
    final int commentIdInt = int.tryParse(targetCommentId) ?? 0;
    final int novelIdInt = int.tryParse(novelId) ?? 0;

    logUtil(msg: 'FCM: 跳转到小说详情页并打开评论，'
        'novelId=$novelId, publishStatus=$publishStatus, '
        'targetCommentId=$targetCommentId');

    // 根据发布状态决定跳转路径
    final String basePath = publishStatus == '4'
        ? '/short_story_read'
        : '/read';
    final String targetPath = '$basePath?id=$novelId';

    // 检查当前是否已在目标小说的阅读页面
    final String currentPath = AppRouter.currentPath();
    final bool is_same_novel = currentPath.startsWith(basePath) &&
        currentPath.contains('id=$novelId');

    if (is_same_novel) {
      // 已在目标页面，通过 store 直接触发打开评论（无需重建页面）
      logUtil(msg: 'FCM: 已在目标小说页面，直接触发打开评论');
      CommentNavigation.open_comment(novel_id: novelIdInt, comment_id: commentIdInt);
    } else {
      // 不在目标页面，replace 替换当前路由（后退时回到跳转前的页面，不是回到小说A）
      logUtil(msg: 'FCM: 替换当前路由到: $targetPath');
      AppRouter.replace('$targetPath&comment_id=$targetCommentId');
    }

    // 标记消息为已读并更新角标
    final int messageIdInt = int.tryParse(messageId) ?? 0;
    if (messageIdInt > 0) {
      try {
        MessageStore.to.mark_as_read(messageIdInt);
      } catch (_) {}
    }
  }

  /// 执行路由跳转。
  ///
  /// 使用 AppRouter 进行跳转。
  static void _navigateTo(String location) {
    try {
      AppRouter.push(location);
      logUtil(msg: 'FCM: 跳转成功: $location');
    } catch (e) {
      logUtil(msg: 'FCM: 跳转失败: $e', type: 'e');
    }
  }
}
