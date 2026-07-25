import 'package:get/get.dart';

// TODO Shell 内部常驻 tab 状态仓库：
// TODO - 专门负责首页和个人中心这两个 shell 级页面的激活状态；
// TODO - 因为这两个页面现在常驻在 IndexedStack 中，不能再依赖 initState 判断“页面被重新打开”；
// TODO - 通过激活路径和激活次数，可以让页面在重新切回前台时执行必要的刷新或状态恢复。
class ShellTabInfo extends GetxController {
  // TODO 当前 shell 层前台展示的 path。
  final RxString activePath = '/'.obs;

  // TODO 当前 shell 层前台 tab 的索引：
  // TODO - 首页固定为 0；
  // TODO - 书架页固定为 1；
  // TODO - 消息页固定为 2；
  // TODO - 个人中心固定为 3。
  final RxInt activeIndex = 0.obs;

  // TODO 首页每次重新成为前台时都会自增一次。
  // TODO 需要监听“首页激活事件”的页面，可以只关心这个 tick 是否变化。
  final RxInt homeActivationTick = 0.obs;

  // TODO 书架页每次重新成为前台时都会自增一次。
  final RxInt bookshelfActivationTick = 0.obs;

  // TODO 消息页每次重新成为前台时都会自增一次。
  final RxInt messageActivationTick = 0.obs;

  // TODO 个人中心每次重新成为前台时都会自增一次。
  // TODO UserInfo 后续就依赖这个 tick 判断“是否需要重新刷新资料”。
  final RxInt userInfoActivationTick = 0.obs;

  // TODO 更新当前 shell 激活 path。
  // TODO 只有在 path 真的发生变化时才会推进 tick，避免同一路径重复 set 导致无意义刷新。
  void updateActivePath(String path) {
    if (activePath.value == path) {
      return;
    }

    activePath.value = path;
    if (path == '/bookshelf') {
      activeIndex.value = 1;
      bookshelfActivationTick.value++;
      return;
    }

    if (path == '/message') {
      activeIndex.value = 2;
      messageActivationTick.value++;
      return;
    }

    if (path == '/user_info') {
      activeIndex.value = 3;
      userInfoActivationTick.value++;
      return;
    }

    activeIndex.value = 0;
    homeActivationTick.value++;
  }
}
