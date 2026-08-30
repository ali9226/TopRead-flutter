/// 判断已预加载的原生广告是否已进入安全可视区域。
///
/// 只要广告与视口交集达到 [minimum_visible_extent]，就可以挂载
/// 原生平台视图，无需等到广告移动到屏幕中央。
bool should_attach_native_ad({
  required double slot_top,
  required double slot_height,
  required double viewport_top,
  required double viewport_bottom,
  required double minimum_visible_extent,
}) {
  if (!slot_top.isFinite ||
      !slot_height.isFinite ||
      !viewport_top.isFinite ||
      !viewport_bottom.isFinite ||
      !minimum_visible_extent.isFinite ||
      slot_height <= 0 ||
      viewport_bottom <= viewport_top ||
      minimum_visible_extent < 0) {
    return false;
  }

  final double slot_bottom = slot_top + slot_height;
  return slot_top <= viewport_bottom - minimum_visible_extent &&
      slot_bottom >= viewport_top + minimum_visible_extent;
}
