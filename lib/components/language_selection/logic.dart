import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_back.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/log_util.dart';

/* TODO
 * LanguageSelection 的逻辑层。
 *
 * 这个文件看起来很小，但这里的返回事件非常关键：
 * 顶部左侧返回按钮不能直接自己 pop，
 * 必须走统一的 routerBack(context)，
 * 这样才能确保自定义按钮和系统返回按钮共用同一套后退判断。
 */
class Logic {
  // TODO 当前组件的 BuildContext。
  // 这里主要是为了保持接口一致，便于未来如果需要读取上下文能力时直接扩展。
  final BuildContext context;

  Logic(this.context);

  /* TODO
   * 点击左侧返回/关闭按钮。
   *
   * 不直接写 Navigator.pop(context) 的原因：
   * 1. 那样会绕过全局 _handleBackButtonSync。
   * 2. 首页双击退出、弹窗优先关闭、底部面板优先收起这些规则就会失效。
   */
  void onLeftTap() {
    // TODO 打日志，方便排查用户点击顶部返回按钮时是否进入了统一后退链路。
    logUtil(msg: "后退一步路由");

    // TODO 所有自定义返回按钮统一走这里，保证和系统后退按钮行为一致。
    routerBack(context);
  }

  /* TODO
   * 点击右侧语言入口。
   *
   * 这里是前进跳转，不属于后退逻辑，因此直接正常跳转到语言选择页即可。
   */
  void onRightTap() {
    // TODO 跳转到切换语言的页面
    routerUtil(path: '/selection_language');
  }

  /// TODO 在离线兜底场景下，确保当前语种仍然是应用支持的语种。
  ///
  /// 这里不能只判断“是否在离线兜底列表里”，否则像中文这类正常支持的语种，
  /// 在进入登录页时也会被错误切成英文。
  Future<void> ensure_offline_language_fallback() async {
    if (!Get.isRegistered<LanguageStore>()) {
      return;
    }

    final LanguageStore language_store = Get.find<LanguageStore>();
    final String current_language_code = context.locale.languageCode;

    /// 当前语种本来就是应用支持的，就不要再做任何回退。
    if (LanguageUtil.is_supported_language_code(current_language_code)) {
      return;
    }

    final String fallback_language_code =
        LanguageUtil.get_fallback_language_code();
    await LanguageChangeHandler.change_language(
      context,
      fallback_language_code,
    );
    language_store.loaded.value = true;
    logUtil(msg: '离线语种兜底：自动切换到 $fallback_language_code');
  }
}
