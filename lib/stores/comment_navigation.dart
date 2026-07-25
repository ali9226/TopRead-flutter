import 'package:get/get.dart';

/// 评论导航 store。
///
/// FCM 推送点击时写入 comment_id，阅读页面监听后打开评论列表。
/// 解决"用户已在阅读页面时收到推送"的场景——无需重建页面。
class CommentNavigation extends GetxController {
  static final CommentNavigation _instance = Get.put(CommentNavigation(), permanent: true);

  /// 待打开的评论ID（0 表示无待处理的评论）。
  static final pending_comment_id = 0.obs;

  /// 当前关联的小说ID（防止不同小说之间互相干扰）。
  static final pending_novel_id = 0.obs;

  /// 触发打开评论列表。
  static void open_comment({required int novel_id, required int comment_id}) {
    pending_novel_id.value = novel_id;
    pending_comment_id.value = comment_id;
  }

  /// 消费待处理的评论ID（阅读页面调用后重置）。
  static void consume() {
    pending_comment_id.value = 0;
    pending_novel_id.value = 0;
  }
}
