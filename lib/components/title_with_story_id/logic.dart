import 'package:get/get.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 是否展示小说 ID 徽标。
///
/// 仅已登录且用户信息 debug 字段为 2 的内部账号可见；
/// 必须无条件读取响应式变量，保证 Obx 在任何分支下都能建立订阅。
bool should_show_story_id_badge(int story_id) {
  final UserInformation user_information = Get.find<UserInformation>();

  // 无条件读取登录态与用户资料，确保 Obx 始终追踪到响应式变量。
  final bool is_logged_in = user_information.isLoggedIn.value;
  final int debug_flag = user_information.userInfo.value?.debug ?? 0;

  // ID 非法、未登录或非 debug = 2 的内部账号均不展示。
  return story_id > 0 && is_logged_in && debug_flag == 2;
}

/// 复制小说 ID 到剪贴板并提示结果。
///
/// [story_id] 需要复制的小说 ID。
Future<void> copy_story_id(int story_id) async {
  final bool copied = await copyToClipboard('$story_id');
  showBottomTip(copied ? '小说 ID $story_id 已复制' : '复制小说 ID 失败');
}
