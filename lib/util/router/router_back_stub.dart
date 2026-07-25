import 'package:flutter/material.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';

/* TODO
 * 这是非 Web 平台使用的 routerBack 实现。
 *
 * 页面里不应该再直接写 Navigator.pop() 或 context.pop()，
 * 而应该统一调用这个方法。
 *
 * 原因是我们要保证“任何来源的后退动作”，都先经过 AppRouter.back()，
 * 从而进入全局的 _handleBackButtonSync 判断。
 */
void routerBack(BuildContext context) {
  // TODO 这里故意不直接使用 context。
  // 因为真正的后退逻辑已经被提升到全局 AppRouter 中统一处理。
  AppRouter.back();
}
