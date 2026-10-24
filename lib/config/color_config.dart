import 'package:flutter/material.dart';

/// 颜色配置。
///
/// 集中管理所有颜色常量，包括主题色、日间/夜间文字色、背景色等。
/// 如无特殊情况：红色指 [ColorConstants.dangerColor]，绿色指 [ColorConstants.successColor]，主题色指 [ColorConstants.themeColor]。
class ColorConstants {

  /// 阴影/遮罩专用近黑。
  ///
  /// 与文字墨色 [lightTextColor] 区分：阴影要在夜间底色上继续压暗出层次，
  /// 墨色比底色浅反而会发灰。不用 #000000 纯黑（调色板禁用），取近黑。
  static const Color shadowColor = Color(0xFF0A0A0A);

  /// 阴影浅压暗（约 6%），用于轻微悬浮层。
  static const Color shadow_soft_10 = Color(0x100A0A0A);

  /// 阴影中压暗（约 12%），用于弹层投影。
  static const Color shadow_soft_1f = Color(0x1F0A0A0A);

  /// 阴影强调压暗（20%），用于封面卡片投影。
  static const Color shadow_medium_33 = Color(0x330A0A0A);
  // 唯一调色板：同一 ARGB 只在此声明一次；业务代码直接引用对应变量。
  /// components/auth_page/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color auth_page_style_password_icon_color = Color(0xFFC8C9CC);

  /// config/color_config.dart、pages/read/widgets/unlock_ad_free_popup/style.dart、pages/read/widgets/rewarded_ad_loading_overlay/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color backgroundColor = Color(0xFF121212);

  /// common_style/submit_button/style.dart、pages/change_password/style.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color common_style_submit_button_style_tone = Color(0xFFF4BD33);

  /// common_style/submit_button/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color common_style_submit_button_style_tone_ff3d2e1a = Color(0xFF3D2E1A);

  /// components/app_wrapper/index.dart、pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart、pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_tab_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_app_wrapper_index_tone = Color(0x8AFFFFFF);

  /// components/auth_page/style.dart、pages/change_password/widgets/password_field.dart、pages/change_nickname/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_auth_page_style_tone = Color(0xFFBDBDBD);

  /// components/auth_page/style.dart、pages/change_password/widgets/password_field.dart、pages/change_nickname/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_auth_page_style_tone_ff757575 = Color(0xFF757575);

  /// components/authorized_login/apple_review/index.dart、pages/read/widgets/navigation_bars/bottom/index.dart、pages/read/widgets/read_directory_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_authorized_login_apple_review_index_tone = Color(0x26FFFFFF);

  /// components/authorized_login/index.dart、components/authorized_login/apple_review/index.dart、pages/short_story_read/widgets/next_story_preview.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_authorized_login_index_tone = Color(0x1AFFFFFF);

  /// components/back_to_top_button/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_back_to_top_button_style_tone = Color(0x3DFFFFFF);

  /// components/back_to_top_button/style.dart、pages/image_text/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_back_to_top_button_style_tone_24ffffff = Color(0x24FFFFFF);

  /// components/category_filter/category_filter_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_category_filter_bar_tone = Color(0xFFBBBBC0);

  /// components/category_filter/category_filter_bar.dart、pages/home/index.dart、pages/home/widgets/home_tab_bar/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_category_filter_bar_tone_fff6f7fb = Color(0xFFF6F7FB);

  /// components/category_filter/filter_popup.dart、components/no_internet/cute_no_internet_cloud.dart、components/paragraph_comment_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_filter_popup_tone = Color(0xFFE8E8EA);

  /// components/category_filter/filter_popup.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_filter_popup_tone_ff2a2d3c = Color(0xFF2A2D3C);

  /// components/category_filter/index.dart、pages/home/widgets/tab_contents/short_story_tab/index.dart、pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_index_tone = Color(0xFF252836);

  /// components/category_filter/index.dart、pages/home/widgets/tab_contents/short_story_tab/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_index_tone_ff2e3145 = Color(0xFF2E3145);

  /// components/category_filter/index.dart、pages/home/widgets/tab_contents/short_story_tab/index.dart、pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_index_tone_fff0f1f5 = Color(0xFFF0F1F5);

  /// components/category_filter/index.dart、pages/home/widgets/tab_contents/short_story_tab/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_category_filter_index_tone_fff8f8fa = Color(0xFFF8F8FA);

  /// components/comment_list/widgets/comment_avatar.dart、pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_comment_list_widgets_comment_avatar_tone = Color(0xFF2C2C2C);

  /// components/comment_list/widgets/comment_avatar.dart、components/share_sheet/style.dart、components/category_filter/filter_popup.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_comment_list_widgets_comment_avatar_tone_fff0f0f0 = Color(0xFFF0F0F0);

  /// components/comment_list/widgets/comment_report_sheet.dart、pages/comics/reader/widgets/chapter_end.dart、pages/interest_preference/widgets/top_bar/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_comment_list_widgets_comment_report_sheet_tone = Color(0x66F8D02D);

  /// components/comment_list/widgets/comment_report_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_comment_list_widgets_comment_report_sheet_tone_99222222 = Color(0x99222222);

  /// components/cute_mascot/index.dart、components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone = Color(0xFF3A3D4A);

  /// components/cute_mascot/index.dart、components/auth_page/style.dart、components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_33222222 = Color(0x33222222);

  /// components/cute_mascot/index.dart、components/authorized_login/apple_review/index.dart、pages/read/widgets/reading_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_4dffffff = Color(0x4DFFFFFF);

  /// components/cute_mascot/index.dart、components/category_filter/filter_popup.dart、components/paragraph_comment_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff1a1a1a = Color(0xFF1A1A1A);

  /// components/cute_mascot/index.dart、pages/published_long_novel_editor/widgets/skeleton_content.dart、pages/author_center/widgets/creator_work_tab.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff2a2a2a = Color(0xFF2A2A2A);

  /// components/cute_mascot/index.dart、components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff2a2d3a = Color(0xFF2A2D3A);

  /// components/cute_mascot/index.dart、pages/published_long_novel_editor/widgets/skeleton_content.dart、pages/author_center/widgets/creator_work_tab.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff3a3a3a = Color(0xFF3A3A3A);

  /// components/cute_mascot/index.dart、components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff4a4a4a = Color(0xFF4A4A4A);

  /// components/cute_mascot/index.dart、components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff4a4d5a = Color(0xFF4A4D5A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff5a5a5a = Color(0xFF5A5A5A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff6a4a4a = Color(0xFF6A4A4A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff6a5a5a = Color(0xFF6A5A5A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff6a6a6a = Color(0xFF6A6A6A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff7a6a6a = Color(0xFF7A6A6A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff8a7a7a = Color(0xFF8A7A7A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff8b6b6b = Color(0xFF8B6B6B);

  /// components/cute_mascot/index.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff8b7355 = Color(0xFF8B7355);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ff8b7a7a = Color(0xFF8B7A7A);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ffd4c8b0 = Color(0xFFD4C8B0);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ffe89090 = Color(0xFFE89090);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_ffe8a0a0 = Color(0xFFE8A0A0);

  /// components/cute_mascot/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_cute_mascot_index_tone_fff5f0e8 = Color(0xFFF5F0E8);

  /// components/empty_state/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_empty_state_index_tone = Color(0xFF4A4D60);

  /// components/empty_state/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_empty_state_index_tone_ff6b6e82 = Color(0xFF6B6E82);

  /// components/empty_state/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_empty_state_index_tone_ffaaaaaa = Color(0xFFAAAAAA);

  /// components/empty_state/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_empty_state_index_tone_ffbbbbcc = Color(0xFFBBBBCC);

  /// components/fixed_bottom_navigation/style.dart、components/work_introduction_hero/index.dart、components/authorized_login/apple_review/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone = Color(0x14222222);

  /// components/fixed_bottom_navigation/style.dart、pages/tile_quest/widgets/quest_controls.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone_38222222 = Color(0x38222222);

  /// components/fixed_bottom_navigation/style.dart、pages/comics/editor/style.dart、pages/comics/editor/widgets/language_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone_38f8d02d = Color(0x38F8D02D);

  /// components/fixed_bottom_navigation/style.dart、pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone_d1d0d4db = Color(0xD1D0D4DB);

  /// components/fixed_bottom_navigation/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone_ff20283a = Color(0xFF20283A);

  /// components/fixed_bottom_navigation/style.dart、pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_style_tone_ffd0d4db = Color(0xFFD0D4DB);

  /// components/fixed_bottom_navigation/widgets/navigation_item.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_widgets_navigation_item_tone = Color(0x4DF56C6C);

  /// components/fixed_bottom_navigation/widgets/night_panel_decor.dart、components/load_more_footer/index.dart、components/home_top_search_entry/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_widgets_night_panel_decor_tone = Color(0x1FFFFFFF);

  /// components/fixed_bottom_navigation/widgets/night_panel_decor.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_fixed_bottom_navigation_widgets_night_panel_decor_tone_5ffffff = Color(0x05FFFFFF);

  /// components/home_header_bar/index.dart、components/auth_page/style.dart、pages/change_password/widgets/password_field.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_home_header_bar_index_tone = Color(0xFF9E9E9E);

  /// components/home_top_search_entry/index.dart、components/authorized_login/index.dart、pages/short_story_read/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_home_top_search_entry_index_tone = Color(0x0D222222);

  /// components/home_top_search_entry/index.dart、pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_home_top_search_entry_index_tone_c7ffffff = Color(0xC7FFFFFF);

  /// components/home_top_search_entry/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_home_top_search_entry_index_tone_ff697180 = Color(0xFF697180);

  /// components/image_source_sheet/index.dart、pages/tile_quest/widgets/quest_controls.dart、pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone = Color(0x2EFFFFFF);

  /// components/image_source_sheet/index.dart、pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_8cffffff = Color(0x8CFFFFFF);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ff0a84c6 = Color(0xFF0A84C6);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ff111827 = Color(0xFF111827);

  /// components/image_source_sheet/index.dart、pages/customer_service_chat/style.dart、pages/customer_service_chat/widgets/image_picker_page.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ff191919 = Color(0xFF191919);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ff232323 = Color(0xFF232323);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ff4b5563 = Color(0xFF4B5563);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ffc58a00 = Color(0xFFC58A00);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ffcbd5e1 = Color(0xFFCBD5E1);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ffdff4ff = Color(0xFFDFF4FF);

  /// components/image_source_sheet/index.dart、pages/debug/widgets/debug_action_item.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_ffe7ecf3 = Color(0xFFE7ECF3);

  /// components/image_source_sheet/index.dart、pages/debug/widgets/debug_action_item.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_fff8fafd = Color(0xFFF8FAFD);

  /// components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_fffdfdfe = Color(0xFFFDFDFE);

  /// components/image_source_sheet/index.dart、pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_image_source_sheet_index_tone_fffff3cc = Color(0xFFFFF3CC);

  /// components/load_more_footer/index.dart、pages/comics/detail/style.dart、pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone = Color(0x99FFFFFF);

  /// components/load_more_footer/index.dart、pages/change_password/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone_59ffffff = Color(0x59FFFFFF);

  /// components/load_more_footer/index.dart、components/work_hero_stats/style.dart、pages/comics/editor/widgets/basic_info_form.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone_bfffffff = Color(0xBFFFFFFF);

  /// components/load_more_footer/index.dart、pages/customer_service_chat/style.dart、pages/interest_preference/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone_ffbbbbbb = Color(0xFFBBBBBB);

  /// components/load_more_footer/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone_ffe5e6eb = Color(0xFFE5E6EB);

  /// components/load_more_footer/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_load_more_footer_index_tone_fff2f3f5 = Color(0xFFF2F3F5);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone = Color(0x996CA0DC);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_26ff9e80 = Color(0x26FF9E80);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_33ffb3a0 = Color(0x33FFB3A0);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_59999999 = Color(0x59999999);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_668b8b9e = Color(0x668B8B9E);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_804a4a4a = Color(0x804A4A4A);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_804a90d9 = Color(0x804A90D9);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_994a90d9 = Color(0x994A90D9);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_99e85d75 = Color(0x99E85D75);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_99e8e8ea = Color(0x99E8E8EA);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_b34a4a4a = Color(0xB34A4A4A);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_b36ca0dc = Color(0xB36CA0DC);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_b3ff6b6b = Color(0xB3FF6B6B);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_cce8e8ea = Color(0xCCE8E8EA);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ff4a90d9 = Color(0xFF4A90D9);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ff6ca0dc = Color(0xFF6CA0DC);

  /// components/no_internet/cute_no_internet_cloud.dart、components/paragraph_comment_sheet/style.dart、pages/short_story_read/widgets/native_ad_banner.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ff8b8b9e = Color(0xFF8B8B9E);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ffe0e0e8 = Color(0xFFE0E0E8);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_fff0f0f5 = Color(0xFFF0F0F5);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_fffafaff = Color(0xFFFAFAFF);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ffff6b6b = Color(0xFFFF6B6B);

  /// components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_no_internet_cute_no_internet_cloud_tone_ffffb3a0 = Color(0xFFFFB3A0);

  /// components/page_background_decor/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_page_background_decor_index_tone = Color(0x21FFD45A);

  /// components/page_background_decor/index.dart、pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart、pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_page_background_decor_index_tone_1af8d02d = Color(0x1AF8D02D);

  /// components/page_background_decor/index.dart、pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_page_background_decor_index_tone_1f8db7ff = Color(0x1F8DB7FF);

  /// components/page_background_decor/index.dart、pages/home/widgets/tab_contents/short_story_tab/widgets/short_story_card.dart、pages/comics/widgets/chapter_sheet/chapter_tile.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_page_background_decor_index_tone_ff8d02d = Color(0x0FF8D02D);

  /// components/paragraph_comment_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_paragraph_comment_sheet_style_tone = Color(0xFFCCCCDD);

  /// components/paragraph_comment_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_paragraph_comment_sheet_style_tone_ff333333 = Color(0xFF333333);

  /// components/paragraph_comment_sheet/widgets/comment_item.dart、pages/home/widgets/tab_bar_skeleton/index.dart、pages/bill/widgets/bill_loading_skeleton.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_paragraph_comment_sheet_widgets_comment_item_tone = Color(0x0A222222);

  /// components/reader_top_bar/style.dart、pages/comics/reader/style.dart、pages/read/widgets/auto_read_settings_button/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone = Color(0xFF161B22);

  /// components/reader_top_bar/style.dart、components/reader_bottom_action/style.dart、pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone_b3ffffff = Color(0xB3FFFFFF);

  /// components/reader_top_bar/style.dart、pages/comics/reader/style.dart、pages/read/widgets/auto_read_settings_button/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone_ff1f1a12 = Color(0xFF1F1A12);

  /// components/reader_top_bar/style.dart、components/paragraph_comment_sheet/style.dart、pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone_ff21262d = Color(0xFF21262D);

  /// components/reader_top_bar/style.dart、components/reader_bottom_action/style.dart、pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone_ff7a6a56 = Color(0xFF7A6A56);

  /// components/reader_top_bar/style.dart、components/customer_service_sheet/style.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_top_bar_style_tone_ffeeeeee = Color(0xFFEEEEEE);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone = Color(0x1AFFF3C4);

  /// components/reading_banner_slide/index.dart、components/home_top_search_entry/index.dart、pages/top_up/widgets/top_up_type_picker_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_29ffffff = Color(0x29FFFFFF);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_47222222 = Color(0x47222222);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_5c7a5b1f = Color(0x5C7A5B1F);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_9e222222 = Color(0x9E222222);

  /// components/reading_banner_slide/index.dart、pages/bill/widgets/bill_record_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_e0ffffff = Color(0xE0FFFFFF);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_ff1d2435 = Color(0xFF1D2435);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_ff7a5b1f = Color(0xFF7A5B1F);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_ffdde4ef = Color(0xFFDDE4EF);

  /// components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reading_banner_slide_index_tone_fffff3c4 = Color(0xFFFFF3C4);

  /// components/recommend_book_card/index.dart、pages/comics/mine/widgets/mine_comic_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_recommend_book_card_index_tone = Color(0xFF161C28);

  /// components/recommend_book_card/index.dart、pages/comics/mine/widgets/mine_comic_card.dart、pages/comics/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_recommend_book_card_index_tone_9effffff = Color(0x9EFFFFFF);

  /// components/recommend_book_card/index.dart、pages/comics/mine/style.dart、pages/comics/mine/widgets/mine_comic_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_recommend_book_card_index_tone_ff8b93a2 = Color(0xFF8B93A2);

  /// components/share_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_share_sheet_index_tone = Color(0xFF667EEA);

  /// components/share_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_share_sheet_index_tone_ffff8e53 = Color(0xFFFF8E53);

  /// components/share_sheet/widgets/share_poster_card.dart、components/share_sheet/widgets/text_selection_poster_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_share_sheet_widgets_share_poster_card_tone = Color(0xFF171717);

  /// components/share_sheet/widgets/share_poster_card.dart、components/share_sheet/widgets/text_selection_poster_card.dart、components/work_introduction_hero/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_share_sheet_widgets_share_poster_card_tone_f222222 = Color(0x0F222222);

  /// components/story_rank_card/index.dart、components/ranking_tab_content/story_rank_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_story_rank_card_index_tone = Color(0xFFB5B5B5);

  /// components/submit_button/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_submit_button_index_tone = Color(0x3DF8D02D);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone = Color(0xFFF3F3F5);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ff25262c = Color(0xFF25262C);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ff26272e = Color(0xFF26272E);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ff30313a = Color(0xFF30313A);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ff626570 = Color(0xFF626570);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ffb7bac4 = Color(0xFFB7BAC4);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_ffe9eaed = Color(0xFFE9EAED);

  /// components/work_about_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_about_section_style_tone_fff1f2f4 = Color(0xFFF1F2F4);

  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone = Color(0x2BFFFFFF);

  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_1f52617a = Color(0x1F52617A);

  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_3352617a = Color(0x3352617A);

  /// components/work_hero_stats/style.dart、pages/comics/reader/widgets/chapter_end.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_33ffffff = Color(0x33FFFFFF);

  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_ff202735 = Color(0xFF202735);

  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_ff626d80 = Color(0xFF626D80);

  /// components/work_hero_stats/style.dart、pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_style_tone_fff6f6f8 = Color(0xFFF6F6F8);

  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_reading_actions_style_tone = Color(0xFFFFE77A);

  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_reading_actions_style_tone_ff656e7a = Color(0xFF656E7A);

  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_reading_actions_style_tone_ff987416 = Color(0xFF987416);

  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_reading_actions_style_tone_ffe2e5eb = Color(0xFFE2E5EB);

  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_reading_actions_style_tone_fff2be27 = Color(0xFFF2BE27);

  /// config/color_config.dart、test/config/design_tokens_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color config_color_config_tone = Color(0xCC222222);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color config_color_config_tone_ff1c1c28 = Color(0xFF1C1C28);

  /// config/color_config.dart、components/customer_service_sheet/style.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color config_color_config_tone_fff5f5f5 = Color(0xFFF5F5F5);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_bubble_admin_bg_dark = Color(0xFF262626);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_emoji_panel_bg_light = Color(0xFFF7F7F7);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_history_text_color_dark = Color(0xFF686868);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_history_text_color_light = Color(0xFFA0A0A0);

  /// pages/customer_service_chat/style.dart、pages/customer_service_chat/widgets/image_picker_page.dart、pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_page_bg_color_dark = Color(0xFF111111);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_page_bg_color_light = Color(0xFFEDEDED);

  /// pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_chat_style_tool_icon_color_dark = Color(0xFFC7C7CC);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_background_color_dark = Color(0xFF1C1C2E);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart、pages/message/widgets/message_skeleton.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_bubble_admin_bg_dark = Color(0xFF2A2A3C);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_drag_bar_color_dark = Color(0xFF3A3A4A);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart、pages/customer_service_chat/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_drag_bar_color_light = Color(0xFFE0E0E0);

  /// components/customer_service_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_input_bar_bg_dark = Color(0xFF1A1A2A);

  /// components/customer_service_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_input_bar_bg_light = Color(0xFFF8F8F8);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart、components/load_more_footer/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_time_color_dark = Color(0xFF666666);

  /// components/customer_service_sheet/style.dart、components/share_sheet/style.dart、components/load_more_footer/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color customer_service_sheet_style_time_color_light = Color(0xFF999999);

  /// config/color_config.dart、components/fixed_bottom_navigation/widgets/navigation_item.dart、components/work_reading_actions/widgets/favorite_button.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dangerColor = Color(0xFFF56C6C);

  /// util/dialog/pop_up_input.dart、config/color_config.dart、components/fixed_bottom_navigation/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hintColor = Color(0xFF888888);

  /// config/color_config.dart、components/work_introduction_hero/index.dart、components/paragraph_selection/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color lightBackgroundColor = Color(0xFFFAFAFA);

  /// common_style/auth_text/style.dart、util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color lightTextColor = Color(0xFF222222);

  /// config/color_config.dart、components/customer_service_sheet/style.dart、components/page_background_decor/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list = Color(0xFFFFD45A);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ff7ec2ff = Color(0xFF7EC2FF);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ffa7d8a8 = Color(0xFFA7D8A8);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ffd6b0ff = Color(0xFFD6B0FF);

  /// config/color_config.dart、components/no_internet/cute_no_internet_cloud.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ffff9e80 = Color(0xFFFF9E80);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ffffb39a = Color(0xFFFFB39A);

  /// config/color_config.dart、pages/read/widgets/background_glow/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color message_type_accent_color_list_ffffc76a = Color(0xFFFFC76A);

  /// common_style/auth_text/style.dart、config/color_config.dart、components/work_section_card/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color nightBackgroundColor = Color(0xFF12121C);

  /// util/dialog/show_message.dart、util/dialog/pop_up_input.dart、config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color nightHighlightColor = Color(0xFF171926);

  /// common_style/auth_text/style.dart、config/color_config.dart、components/customer_service/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color nightTextColor = Color(0xFF68697E);

  /// pages/about_topread/index.dart、pages/user_info/widgets/operation_list/operation_li.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_about_topread_index_tone = Color(0x0DF8D02D);

  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_author_style_tone = Color(0xFFF1F2F5);

  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_author_style_tone_13ffffff = Color(0x13FFFFFF);

  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_author_style_tone_a8ffffff = Color(0xA8FFFFFF);

  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_author_style_tone_ff765600 = Color(0xFF765600);

  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_author_style_tone_ffe7e7e2 = Color(0xFFE7E7E2);

  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_backend_work_card_tone = Color(0xFFFFF5DB);

  /// pages/author_center/widgets/creator_empty_state.dart、pages/author_center/widgets/creator_header.dart、pages/work_editor/_shared/widgets/editor_step_indicator.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_empty_state_tone = Color(0xFF1A1A18);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone = Color(0xFFF2F7FF);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff101721 = Color(0xFF101721);

  /// pages/author_center/widgets/creator_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff171010 = Color(0xFF171010);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff17140e = Color(0xFF17140E);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff18222f = Color(0xFF18222F);

  /// pages/author_center/widgets/creator_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff1d1b14 = Color(0xFF1D1B14);

  /// pages/author_center/widgets/creator_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff261515 = Color(0xFF261515);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_ff262113 = Color(0xFF262113);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_fffbfdff = Color(0xFFFBFDFF);

  /// pages/author_center/widgets/creator_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_fffff0f0 = Color(0xFFFFF0F0);

  /// pages/author_center/widgets/creator_header.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_fffff4d3 = Color(0xFFFFF4D3);

  /// pages/author_center/widgets/creator_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_fffff8f8 = Color(0xFFFFF8F8);

  /// pages/author_center/widgets/creator_header.dart、pages/change_nickname/style.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_header_tone_fffffcf0 = Color(0xFFFFFCF0);

  /// pages/author_center/widgets/creator_work_tab.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_author_center_widgets_creator_work_tab_tone = Color(0xFF1E1E1E);

  /// pages/bill/widgets/bill_loading_skeleton.dart、pages/top_up/widgets/top_up_loading_skeleton.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_loading_skeleton_tone = Color(0x12FFFFFF);

  /// pages/bill/widgets/bill_page_loading_overlay.dart、pages/top_up/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_page_loading_overlay_tone = Color(0xFF1A1D2B);

  /// pages/bill/widgets/bill_record_card.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_record_card_tone = Color(0xFF1C2230);

  /// pages/bill/widgets/bill_record_card.dart、pages/withdraw/logic.dart、pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_record_card_tone_24f8d02d = Color(0x24F8D02D);

  /// pages/bill/widgets/bill_record_card.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_record_card_tone_4ffffff = Color(0x04FFFFFF);

  /// pages/bill/widgets/bill_record_card.dart、pages/selection_language/widgets/language_card.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_record_card_tone_affffff = Color(0x0AFFFFFF);

  /// pages/bill/widgets/bill_record_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bill_widgets_bill_record_card_tone_fffffbf0 = Color(0xFFFFFBF0);

  /// pages/bookshelf/logic.dart、pages/ranking_full_list/logic.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_logic_tone = Color(0xFF7ED9B1);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart、pages/ranking_full_list/widgets/bookshelf_book_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone = Color(0xFF2B2F36);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart、pages/about_topread/index.dart、pages/selection_language/widgets/language_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone_73222222 = Color(0x73222222);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart、pages/ranking_full_list/widgets/bookshelf_book_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone_85ffffff = Color(0x85FFFFFF);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone_b8ffffff = Color(0xB8FFFFFF);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone_ff23262d = Color(0xFF23262D);

  /// pages/bookshelf/widgets/bookshelf_book_card.dart、pages/ranking_full_list/widgets/bookshelf_book_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_book_card_tone_ff6f7785 = Color(0xFF6F7785);

  /// pages/bookshelf/widgets/bookshelf_grid_content.dart、pages/ranking_full_list/widgets/bookshelf_grid_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_grid_content_tone = Color(0xFF1A2130);

  /// pages/bookshelf/widgets/bookshelf_grid_content.dart、pages/ranking_full_list/widgets/bookshelf_grid_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_bookshelf_grid_content_tone_ffedeff4 = Color(0xFFEDEFF4);

  /// pages/bookshelf/widgets/focus_tab_content.dart、pages/bookshelf/widgets/bookshelf_grid_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone = Color(0xFF9BA3B1);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff1a1d26 = Color(0xFF1A1D26);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff1c2030 = Color(0xFF1C2030);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff252b3b = Color(0xFF252B3B);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff6b8cff = Color(0xFF6B8CFF);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff6baaee = Color(0xFF6BAAEE);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff6bccaa = Color(0xFF6BCCAA);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff6bcccb = Color(0xFF6BCCCB);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff8b6bcc = Color(0xFF8B6BCC);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff8e95a2 = Color(0xFF8E95A2);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ff9b6bff = Color(0xFF9B6BFF);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffcc6b8b = Color(0xFFCC6B8B);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffcc8b6b = Color(0xFFCC8B6B);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffe8ecf2 = Color(0xFFE8ECF2);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffee8b6b = Color(0xFFEE8B6B);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffeecb6b = Color(0xFFEECB6B);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffeff1f5 = Color(0xFFEFF1F5);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_fff2f4f8 = Color(0xFFF2F4F8);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffff6b8c = Color(0xFFFF6B8C);

  /// pages/bookshelf/widgets/focus_tab_content.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_bookshelf_widgets_focus_tab_content_tone_ffff9b6b = Color(0xFFFF9B6B);

  /// pages/change_nickname/index.dart、pages/change_nickname/style.dart、pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_index_tone = Color(0x73FFFFFF);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone = Color(0xF01C2436);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_2ef6d76a = Color(0x2EF6D76A);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_80f6d76a = Color(0x80F6D76A);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_99e8a830 = Color(0x99E8A830);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_d9888888 = Color(0xD9888888);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_e6161d2a = Color(0xE6161D2A);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_f5fffbf2 = Color(0xF5FFFBF2);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_faffffff = Color(0xFAFFFFFF);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ff161d2a = Color(0xFF161D2A);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ff1c2436 = Color(0xFF1C2436);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ff2a3040 = Color(0xFF2A3040);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ff5a4a36 = Color(0xFF5A4A36);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ffd4a840 = Color(0xFFD4A840);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ffe0d4c0 = Color(0xFFE0D4C0);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ffe8a830 = Color(0xFFE8A830);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_ffe8dcc8 = Color(0xFFE8DCC8);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_fff8e4b8 = Color(0xFFF8E4B8);

  /// pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_nickname_style_tone_fffffbf2 = Color(0xFFFFFBF2);

  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone = Color(0xFFFFF8EE);

  /// pages/change_password/style.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_1fbfa55a = Color(0x1FBFA55A);

  /// pages/change_password/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_a6ffffff = Color(0xA6FFFFFF);

  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_cc1a1e2e = Color(0xCC1A1E2E);

  /// pages/change_password/style.dart、pages/change_password/widgets/password_field.dart、pages/change_nickname/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_d9ffffff = Color(0xD9FFFFFF);

  /// pages/change_password/style.dart、pages/change_password/widgets/password_field.dart、test/components/back_to_top_layout_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_e0222222 = Color(0xE0222222);

  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_e6888888 = Color(0xE6888888);

  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_e6fff8ee = Color(0xE6FFF8EE);

  /// pages/change_password/style.dart、pages/user_info_input/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_ff121a25 = Color(0xFF121A25);

  /// pages/change_password/style.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_ffe8e0c8 = Color(0xFFE8E0C8);

  /// pages/change_password/style.dart、pages/user_info_input/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_fff6d76a = Color(0xFFF6D76A);

  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_ffffd861 = Color(0xFFFFD861);

  /// pages/change_password/style.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_fffffcf2 = Color(0xFFFFFCF2);

  /// pages/comics/detail/style.dart、pages/withdraw/widgets/confirm_tips.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone = Color(0x94222222);

  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone_52222222 = Color(0x52222222);

  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone_ff1a1a2e = Color(0xFF1A1A2E);

  /// pages/comics/detail/style.dart、pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone_ff1a1e2e = Color(0xFF1A1E2E);

  /// pages/comics/detail/style.dart、pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone_ff777985 = Color(0xFF777985);

  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_style_tone_ffffcf18 = Color(0xFFFFCF18);

  /// pages/comics/detail/widgets/detail_sheets.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_widgets_detail_sheets_tone = Color(0xFF242428);

  /// pages/comics/detail/widgets/reading_action_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_widgets_reading_action_bar_tone = Color(0xFFFFD655);

  /// pages/comics/editor/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_editor_style_tone = Color(0xFFF5F6F8);

  /// pages/comics/editor/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_editor_style_tone_fff0f1f4 = Color(0xFFF0F1F4);

  /// pages/comics/editor/widgets/basic_info_form.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_editor_widgets_basic_info_form_tone = Color(0xA6F8D02D);

  /// pages/comics/mine/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_mine_style_tone = Color(0xFFE0A106);

  /// pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_reader_style_tone = Color(0xFF9398A4);

  /// pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_reader_style_tone_ff777e88 = Color(0xFF777E88);

  /// pages/comics/reader/widgets/chapter_end.dart、pages/comics/editor/index.dart、pages/comics/editor/widgets/chapter_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_reader_widgets_chapter_end_tone = Color(0x29F8D02D);

  /// pages/comics/widgets/chapter_sheet/catalog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_catalog_tone = Color(0xFF2C3039);

  /// pages/comics/widgets/chapter_sheet/catalog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_catalog_tone_ff4a4028 = Color(0xFF4A4028);

  /// pages/comics/widgets/chapter_sheet/catalog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_catalog_tone_ffeeedeb = Color(0xFFEEEDEB);

  /// pages/comics/widgets/chapter_sheet/catalog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_catalog_tone_fffff4cf = Color(0xFFFFF4CF);

  /// pages/comics/widgets/chapter_sheet/chapter_tile.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_chapter_tile_tone = Color(0x1FF56C6C);

  /// pages/customer_service_chat/widgets/image_picker_page.dart、test/pages/tile_quest/board_corner_transparency_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_customer_service_chat_widgets_image_picker_page_tone = Color(0xFFF44336);

  /// pages/customer_service_chat/widgets/message_bubble.dart、pages/read/widgets/read_directory_sheet/index.dart、test/pages/comics/reader/controls_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_customer_service_chat_widgets_message_bubble_tone = Color(0x61222222);

  /// pages/customer_service_chat/widgets/message_bubble.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_customer_service_chat_widgets_message_bubble_tone_85222222 = Color(0x85222222);

  /// pages/home/widgets/tab_bar_skeleton/index.dart、pages/customer_service_chat/widgets/message_bubble.dart、pages/read/widgets/navigation_bars/bottom/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_home_widgets_tab_bar_skeleton_index_tone = Color(0x40FFFFFF);

  /// pages/home/widgets/tab_bar_skeleton/index.dart、pages/short_story_read/widgets/auto_read_settings_sheet.dart、pages/short_story_read/widgets/bottom_comment_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_home_widgets_tab_bar_skeleton_index_tone_26222222 = Color(0x26222222);

  /// pages/home/widgets/tab_contents/recommend_tab/index.dart、pages/comics/mine/widgets/mine_comic_card.dart、pages/message/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_home_widgets_tab_contents_recommend_tab_index_tone = Color(0xFF171C28);

  /// pages/home/widgets/tab_contents/short_story_tab/widgets/short_story_card.dart、pages/comics/widgets/chapter_sheet/chapter_tile.dart、pages/bill/widgets/bill_record_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_home_widgets_tab_contents_short_story_tab_widgets_short_story_card_tone = Color(0x1FF8D02D);

  /// pages/image_text/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_image_text_index_tone = Color(0xF2FFFFFF);

  /// pages/interest_preference/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_interest_preference_style_tone = Color(0xFF12141F);

  /// pages/interest_preference/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_interest_preference_style_tone_fff5f6fa = Color(0xFFF5F6FA);

  /// pages/message/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_message_index_tone = Color(0x1AF56C6C);

  /// pages/message/widgets/message_item_card.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_message_widgets_message_item_card_tone = Color(0xA3FFFFFF);

  /// pages/message/widgets/message_item_card.dart、pages/user_info_input/style.dart、pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_message_widgets_message_item_card_tone_14f8d02d = Color(0x14F8D02D);

  /// pages/published_long_novel_editor/widgets/skeleton_content.dart、pages/author_center/widgets/creator_work_tab.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_published_long_novel_editor_widgets_skeleton_content_tone = Color(0xFFE8E8E8);

  /// pages/ranking_full_list/widgets/starfield_decoration.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_ranking_full_list_widgets_starfield_decoration_tone = Color(0xFFFFC94D);

  /// pages/read/widgets/auto_read_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_auto_read_settings_sheet_index_tone = Color(0x147A6A56);

  /// pages/read/widgets/auto_read_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_auto_read_settings_sheet_index_tone_ffe54d4d = Color(0xFFE54D4D);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone = Color(0xFFCBCDD8);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff2b2930 = Color(0xFF2B2930);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff414352 = Color(0xFF414352);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff646773 = Color(0xFF646773);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff77643c = Color(0xFF77643C);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffa16a0a = Color(0xFFA16A0A);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffdadbe2 = Color(0xFFDADBE2);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffe1e2e9 = Color(0xFFE1E2E9);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffe4d5aa = Color(0xFFE4D5AA);

  /// pages/read/widgets/introduction_section/widgets/comment_item/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_item_style_tone_fff3f0e8 = Color(0xFFF3F0E8);

  /// pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_section_style_tone = Color(0xFFF0F0F4);

  /// pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ff1b1c29 = Color(0xFF1B1C29);

  /// pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ff2b2c3a = Color(0xFF2B2C3A);

  /// pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ffa5a7b7 = Color(0xFFA5A7B7);

  /// pages/read/widgets/introduction_section/widgets/comment_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ffe9e9ee = Color(0xFFE9E9EE);

  /// pages/read/widgets/navigation_bars/bottom/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_navigation_bars_bottom_index_tone = Color(0x667A6A56);

  /// pages/read/widgets/navigation_bars/bottom/index.dart、pages/read/widgets/auto_read_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_navigation_bars_bottom_index_tone_267a6a56 = Color(0x267A6A56);

  /// pages/read/widgets/navigation_bars/bottom/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_navigation_bars_bottom_index_tone_ccffffff = Color(0xCCFFFFFF);

  /// pages/read/widgets/read_directory_sheet/index.dart、pages/user_info_input/style.dart、pages/about_topread/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_index_tone = Color(0x61FFFFFF);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone = Color(0xFF171B25);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_29f56c6c = Color(0x29F56C6C);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_effffff = Color(0x0EFFFFFF);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_ff202633 = Color(0xFF202633);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_ff252216 = Color(0xFF252216);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_ff3a2f12 = Color(0xFF3A2F12);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_ff9a9a9a = Color(0xFF9A9A9A);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_fff1eee8 = Color(0xFFF1EEE8);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_fff4f4f4 = Color(0xFFF4F4F4);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_fff5f2ec = Color(0xFFF5F2EC);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_fffffcf1 = Color(0xFFFFFCF1);

  /// pages/read/widgets/read_directory_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_style_tone_fffffefb = Color(0xFFFFFEFB);

  /// pages/read/widgets/read_directory_sheet/widgets/book_detail_header.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_read_directory_sheet_widgets_book_detail_header_tone = Color(0xFF3D7DFF);

  /// pages/read/widgets/reading_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_reading_settings_sheet_index_tone = Color(0x1A7A6A56);

  /// pages/read/widgets/reading_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_reading_settings_sheet_index_tone_4d7a6a56 = Color(0x4D7A6A56);

  /// pages/read/widgets/reading_settings_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_reading_settings_sheet_index_tone_d7a6a56 = Color(0x0D7A6A56);

  /// pages/read/widgets/unlock_ad_free_popup/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_unlock_ad_free_popup_style_tone = Color(0x4D888888);

  /// pages/read/widgets/unlock_ad_free_popup/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_read_widgets_unlock_ad_free_popup_style_tone_4d68697e = Color(0x4D68697E);

  /// pages/selection_language/widgets/language_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_selection_language_widgets_language_card_tone = Color(0x0AF8D02D);

  /// pages/short_story_read/index.dart、pages/short_story_read/widgets/next_story_preview.dart、pages/author_center/author_view.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_index_tone = Color(0x2E222222);

  /// pages/short_story_read/index.dart、pages/top_up/widgets/top_up_hero_card.dart、pages/tile_quest/widgets/quest_controls.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_index_tone_6bffffff = Color(0x6BFFFFFF);

  /// pages/short_story_read/widgets/auto_read_settings_sheet.dart、pages/short_story_read/widgets/bottom_comment_bar.dart、pages/read/widgets/navigation_bars/bottom/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_auto_read_settings_sheet_tone = Color(0x66222222);

  /// pages/short_story_read/widgets/auto_read_settings_sheet.dart、pages/short_story_read/widgets/bottom_comment_bar.dart、pages/read/widgets/navigation_bars/bottom/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_auto_read_settings_sheet_tone_bf222222 = Color(0xBF222222);

  /// pages/short_story_read/widgets/bottom_comment_bar.dart、pages/read/widgets/navigation_bars/bottom/index.dart、pages/read/widgets/back_button/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_bottom_comment_bar_tone = Color(0xDD222222);

  /// pages/short_story_read/widgets/collapse_button.dart、pages/short_story_read/widgets/story_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_collapse_button_tone = Color(0x4D222222);

  /// pages/short_story_read/widgets/collapse_button.dart、pages/top_up/widgets/top_up_type_picker_sheet.dart、pages/read/widgets/read_directory_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_collapse_button_tone_1a222222 = Color(0x1A222222);

  /// pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_full_appbar_tone = Color(0xFF384356);

  /// pages/short_story_read/widgets/full_appbar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_full_appbar_tone_fff7f9fc = Color(0xFFF7F9FC);

  /// pages/short_story_read/widgets/native_ad_banner.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_native_ad_banner_tone = Color(0xFF1E2430);

  /// pages/short_story_read/widgets/next_story_preview.dart、pages/message/widgets/message_skeleton.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_next_story_preview_tone = Color(0x47FFFFFF);

  /// pages/short_story_read/widgets/next_story_preview.dart、pages/top_up/widgets/top_up_bottom_action_bar.dart、pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_next_story_preview_tone_9222222 = Color(0x09222222);

  /// pages/short_story_read/widgets/scroll_to_bottom_button.dart、pages/short_story_read/widgets/auto_read_settings_button.dart、pages/read/widgets/auto_read_settings_button/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_short_story_read_widgets_scroll_to_bottom_button_tone = Color(0x59222222);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone = Color(0x42F56C6C);

  /// pages/tile_quest/style.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_29222222 = Color(0x29222222);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_40accae5 = Color(0x40ACCAE5);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff0b1430 = Color(0xFF0B1430);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff142544 = Color(0xFF142544);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff172a59 = Color(0xFF172A59);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff172c52 = Color(0xFF172C52);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff174653 = Color(0xFF174653);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff264972 = Color(0xFF264972);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff355b88 = Color(0xFF355B88);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ff477c83 = Color(0xFF477C83);

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_style_tone_ffaccae5 = Color(0xFFACCAE5);

  /// pages/top_up_qr_code/widgets/top_up_qr_content_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_qr_code_widgets_top_up_qr_content_card_tone = Color(0xFFFFF8DD);

  /// pages/top_up_qr_code/widgets/top_up_qr_content_card.dart、pages/withdraw/widgets/confirm_dialog.dart、pages/selection_language/widgets/language_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_qr_code_widgets_top_up_qr_content_card_tone_8222222 = Color(0x08222222);

  /// pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_qr_code_widgets_top_up_qr_hero_card_tone = Color(0xB8222222);

  /// pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_qr_code_widgets_top_up_qr_hero_card_tone_a3222222 = Color(0xA3222222);

  /// pages/top_up_record/index.dart、pages/top_up_record/widgets/empty_state.dart、pages/top_up/widgets/top_up_type_picker_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_record_index_tone = Color(0xFF171A27);

  /// pages/top_up/widgets/top_up_amount_section.dart、pages/top_up/widgets/top_up_type_section.dart、pages/withdraw/widgets/confirm_dialog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_amount_section_tone = Color(0x94FFFFFF);

  /// pages/top_up/widgets/top_up_amount_section.dart、pages/top_up_qr_code/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_amount_section_tone_ff121521 = Color(0xFF121521);

  /// pages/top_up/widgets/top_up_amount_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_amount_section_tone_fff8f8f4 = Color(0xFFF8F8F4);

  /// pages/top_up/widgets/top_up_bottom_action_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_bottom_action_bar_tone = Color(0xF5171A27);

  /// pages/top_up/widgets/top_up_bottom_action_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_bottom_action_bar_tone_8fffffff = Color(0x8FFFFFFF);

  /// pages/top_up/widgets/top_up_bottom_action_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_bottom_action_bar_tone_f5ffffff = Color(0xF5FFFFFF);

  /// pages/top_up/widgets/top_up_hero_card.dart、pages/top_up_qr_code/widgets/top_up_qr_notice_card.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_hero_card_tone = Color(0xADFFFFFF);

  /// pages/top_up/widgets/top_up_hero_card.dart、pages/tile_quest/widgets/quest_controls.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_hero_card_tone_57ffffff = Color(0x57FFFFFF);

  /// pages/top_up/widgets/top_up_type_picker_sheet.dart、pages/interest_preference/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_picker_sheet_tone = Color(0x66FFFFFF);

  /// pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_section_tone = Color(0x7AFFFFFF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone = Color(0xFFFFF5DF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_118db7ff = Color(0x118DB7FF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_14f6d76a = Color(0x14F6D76A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_228db7ff = Color(0x228DB7FF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_22d8b24a = Color(0x22D8B24A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_22f6d76a = Color(0x22F6D76A);

  /// pages/user_info_input/style.dart、pages/withdraw/widgets/type_selector.dart、pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_24222222 = Color(0x24222222);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_268db7ff = Color(0x268DB7FF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_29f6d76a = Color(0x29F6D76A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_33f6d76a = Color(0x33F6D76A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_90f172a = Color(0x090F172A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_9ffffff = Color(0x09FFFFFF);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_e0141c28 = Color(0xE0141C28);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_e61a2432 = Color(0xE61A2432);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_eb141c28 = Color(0xEB141C28);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_eb888888 = Color(0xEB888888);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_f0141c28 = Color(0xF0141C28);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_f0fff4de = Color(0xF0FFF4DE);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_f5fff4de = Color(0xF5FFF4DE);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_f5fff6e4 = Color(0xF5FFF6E4);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fafff4de = Color(0xFAFFF4DE);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fbfa55a = Color(0x0FBFA55A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ff0f1520 = Color(0xFF0F1520);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ff0f172a = Color(0xFF0F172A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ff141c28 = Color(0xFF141C28);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ff1a2432 = Color(0xFF1A2432);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ffbfa55a = Color(0xFFBFA55A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ffefd784 = Color(0xFFEFD784);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fff8e28e = Color(0xFFF8E28E);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_ffffe08a = Color(0xFFFFE08A);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fffff3c8 = Color(0xFFFFF3C8);

  /// pages/user_info_input/style.dart、pages/change_nickname/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fffff4de = Color(0xFFFFF4DE);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fffff6e4 = Color(0xFFFFF6E4);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fffff8e6 = Color(0xFFFFF8E6);

  /// pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_input_style_tone_fffffbeb = Color(0xFFFFFBEB);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone = Color(0x22FFD45A);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone_1aff9e80 = Color(0x1AFF9E80);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone_e6ffffff = Color(0xE6FFFFFF);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone_fff5f8ff = Color(0xFFF5F8FF);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone_fff8fbff = Color(0xFFF8FBFF);

  /// pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_operation_list_index_tone_fffffaf2 = Color(0xFFFFFAF2);

  /// pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_statistics_index_tone = Color(0x8F222222);

  /// pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_statistics_index_tone_ff1a120f = Color(0xFF1A120F);

  /// pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_statistics_index_tone_ff2b1b17 = Color(0xFF2B1B17);

  /// pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_statistics_index_tone_ffffefea = Color(0xFFFFEFEA);

  /// pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_statistics_index_tone_fffffbf9 = Color(0xFFFFFBF9);

  /// pages/user_info/widgets/top_user_info/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_top_user_info_index_tone = Color(0x59F8D02D);

  /// pages/user_info/widgets/top_user_info/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_top_user_info_index_tone_d1222222 = Color(0xD1222222);

  /// pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_user_info_top_tone = Color(0x388DB7FF);

  /// pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_user_info_top_tone_408db7ff = Color(0x408DB7FF);

  /// pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_user_info_top_tone_ebffffff = Color(0xEBFFFFFF);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone = Color(0xFF1A2634);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff141c27 = Color(0xFF141C27);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff334559 = Color(0xFF334559);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff3a3220 = Color(0xFF3A3220);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff5b6472 = Color(0xFF5B6472);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff64748b = Color(0xFF64748B);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff6a4d00 = Color(0xFF6A4D00);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ff94a3b8 = Color(0xFF94A3B8);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_ffa9b5c6 = Color(0xFFA9B5C6);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_fff1f5f9 = Color(0xFFF1F5F9);

  /// pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_amount_panel_tone_fff5f7fb = Color(0xFFF5F7FB);

  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone = Color(0xFFE7C866);

  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_5222222 = Color(0x05222222);

  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_ff7a5a00 = Color(0xFF7A5A00);

  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_fff6c542 = Color(0xFFF6C542);

  /// pages/withdraw/widgets/type_selector.dart、pages/withdraw/widgets/confirm_dialog.dart、pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_ffffe8a3 = Color(0xFFFFE8A3);

  /// pages/work_editor/_shared/widgets/chapter_publish_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_work_editor_shared_widgets_chapter_publish_sheet_tone = Color(0x80222222);

  /// pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_work_editor_shared_widgets_steps_step_basic_step_basic_tone = Color(0x4DF8D02D);

  /// config/color_config.dart、components/auth_form_widgets/auth_account_status_hint.dart、components/auth_page/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color successColor = Color(0xFF67C23A);

  /// config/color_config.dart、pages/author_center/author_view.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_color_list = Color(0xFF5C9DFF);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_color_list_ff4cbf8a = Color(0xFF4CBF8A);

  /// config/color_config.dart、components/no_internet/cute_no_internet_cloud.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_color_list_ffe85d75 = Color(0xFFE85D75);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_color_list_ffff7a59 = Color(0xFFFF7A59);

  /// config/color_config.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_color_list_ffffb020 = Color(0xFFFFB020);

  /// test/components/fullbleed_surfaces_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_components_fullbleed_surfaces_test_tone = Color(0xFF0D1117);

  /// test/components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_components_work_introduction_hero_test_tone = Color(0xCC252A36);

  /// test/components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_components_work_introduction_hero_test_tone_ff252a36 = Color(0xFF252A36);

  /// test/components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_components_work_introduction_hero_test_tone_ffffd84c = Color(0xFFFFD84C);

  /// test/pages/tile_quest/match_particles_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_pages_tile_quest_match_particles_test_tone = Color(0xFF233F62);

  /// test/pages/tile_quest/modal_full_window_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_pages_tile_quest_modal_full_window_test_tone = Color(0xB8061126);

  /// test/pages/tile_quest/modal_full_window_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_pages_tile_quest_modal_full_window_test_tone_ff061126 = Color(0xFF061126);

  /// test/pages/tile_quest/reveal_pixel_preview_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_pages_tile_quest_reveal_pixel_preview_test_tone = Color(0xFF233A56);

  /// test/pages/tile_quest/tile_surface_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color test_pages_tile_quest_tile_surface_test_tone = Color(0xFF18324C);

  /// common_style/submit_button/style.dart、util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color themeColor = Color(0xFFF8D02D);

  /// tool/tile_quest_performance.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tool_tile_quest_performance_tone = Color(0xFF132743);

  /// common_style/selection_chip/index.dart、common_style/submit_button/index.dart、util/dialog/show_upgrade_dialog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color transparent = Color(0x00000000);

  /// pages/read/widgets/unlock_ad_free_popup/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unlock_ad_free_popup_style_barrier_color = Color(0x8A222222);

  /// util/dialog/pop_up_input.dart、test/components/app_modal_full_window_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone = Color(0x57222222);

  /// util/dialog/pop_up_input.dart、pages/withdraw/widgets/amount_panel.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone_ffe2e8f0 = Color(0xFFE2E8F0);

  /// util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone_ffe7e5de = Color(0xFFE7E5DE);

  /// util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone_fff0e3b2 = Color(0xFFF0E3B2);

  /// util/dialog/pop_up_input.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone_fffffcf7 = Color(0xFFFFFCF7);

  /// util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_pop_up_input_tone_fffffdf8 = Color(0xFFFFFDF8);

  /// util/dialog/show_bottom_tip.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_bottom_tip_tone = Color(0xE6222222);

  /// util/dialog/show_bottom_tip.dart、pages/short_story_read/widgets/scroll_to_bottom_button.dart、pages/short_story_read/widgets/auto_read_settings_button.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_bottom_tip_tone_1f222222 = Color(0x1F222222);

  /// util/dialog/show_bottom_tip.dart、pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_bottom_tip_tone_b3222222 = Color(0xB3222222);

  /// util/dialog/show_message.dart、pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_book_item.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_message_tone = Color(0xBDFFFFFF);

  /// util/dialog/show_message.dart、components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_message_tone_ff6b7280 = Color(0xFF6B7280);

  /// util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_message_tone_ff6e5312 = Color(0xFF6E5312);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone = Color(0x248DB7FF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_14ffffff = Color(0x14FFFFFF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_1a8db7ff = Color(0x1A8DB7FF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_298db7ff = Color(0x298DB7FF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_2ed8e0ec = Color(0x2ED8E0EC);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_2ef8d02d = Color(0x2EF8D02D);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、components/reading_banner_slide/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_42222222 = Color(0x42222222);

  /// util/dialog/show_upgrade_dialog.dart、components/story_rank_card/index.dart、components/ranking_tab_content/story_rank_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_80ffffff = Color(0x80FFFFFF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_8ffffff = Color(0x08FFFFFF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_dffffff = Color(0x0DFFFFFF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、util/dialog/pop_up_input.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_ff8db7ff = Color(0xFF8DB7FF);

  /// util/dialog/show_upgrade_dialog.dart、components/image_source_sheet/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_ff9ca3af = Color(0xFF9CA3AF);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、pages/user_info/widgets/operation_list/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_ffd8e0ec = Color(0xFFD8E0EC);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_ffe0e6ef = Color(0xFFE0E6EF);

  /// util/dialog/show_upgrade_dialog.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_ffe5e7eb = Color(0xFFE5E7EB);

  /// util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart、components/fixed_bottom_navigation/widgets/night_panel_decor.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color util_dialog_show_upgrade_dialog_tone_fffffff = Color(0x0FFFFFFF);

  /// common_style/auth_text/style.dart、util/dialog/show_upgrade_dialog.dart、util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color whiteColor = Color(0xFFFFFFFF);


  /// 原生瀑布流广告在夜间模式下的卡片底色。
  static const Color native_card_dark = ColorConstants.pages_home_widgets_tab_contents_recommend_tab_index_tone;

  /// 原生瀑布流广告在日间模式下的标题色。
  static const Color native_primary_light = ColorConstants.components_recommend_book_card_index_tone;

  /// 原生广告夜间模式下的次要文案色。
  static const Color native_secondary_dark = Color(0xFFB0B5C0);

  /// 原生广告日间模式下的次要文案色。
  static const Color native_secondary_light = Color(0xFF747C8A);

  /// 原生广告归因标签的蓝色。
  static const Color native_attribution = Color(0xFF5F8BFF);

  /// 原生广告广告主标签的绿色。
  static const Color native_advertiser = Color(0xFF2FBF9B);

  /// 原生瀑布流广告金色按钮上的深色文字。
  static const Color native_cta_text = Color(0xFF2A2410);

  /// 沉浸式原生广告叠层上的次要文字。
  static const Color native_overlay_caption = Color(0xFFCCCCCC);

  /// 沉浸式原生广告未指定分类色时的归因标签色。
  static const Color native_default_tag = Color(0xFFFF4D4D);

  /// Web 安装清单的主题色；打包资源通过同步脚本从此处生成。
  static const Color web_manifest_theme = Color(0xFF0175C2);

  /// 原生广告统一接收 ARGB 色板，不在 Kotlin / Swift 中复制主题色。
  ///
  /// [tag_color] 沿用短篇列表随机分类色；未提供时使用统一默认标签色。
  /// 所有平台使用相同的 alpha 和颜色编码，避免昼夜主题跨端漂移。
  static Map<String, int> native_ad_palette(
    bool is_dark, {
    Color? tag_color,
  }) {
    final tag = tag_color ?? native_default_tag;
    return <String, Color>{
      'card_background': is_dark ? native_card_dark : ColorConstants.whiteColor,
      'primary_text': is_dark ? ColorConstants.whiteColor : native_primary_light,
      'secondary_text': is_dark ? native_secondary_dark : native_secondary_light,
      'attribution_text': native_attribution.withValues(alpha: 0.96),
      'attribution_background': native_attribution.withValues(alpha: 0.16),
      'advertiser_text': native_advertiser.withValues(alpha: 0.96),
      'advertiser_background': native_advertiser.withValues(alpha: 0.16),
      'cta_text': native_cta_text,
      'cta_background': ColorConstants.themeColor,
      'overlay_background': ColorConstants.lightTextColor,
      'overlay_scrim': ColorConstants.config_color_config_tone,
      'overlay_headline': ColorConstants.whiteColor,
      'overlay_caption': native_overlay_caption,
      'overlay_tag': tag,
      'overlay_tag_background': tag.withValues(alpha: 0.15),
      'overlay_cta_text': ColorConstants.lightTextColor,
    }.map((key, color) => MapEntry(key, color.toARGB32()));
  }

  /// 解析外部十六进制色值；所有 Color 构造统一留在本配置文件中。
  static Color parse_hex(String value) {
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  

  

  

  

  

  

  

  

  

  

  

  /// 弹窗/BottomSheet 背景色（统一变量，所有弹窗共用）。
  static Color sheetBackground(bool isDark) =>
      isDark ? ColorConstants.nightBackgroundColor : ColorConstants.whiteColor;

  /// 弹窗内输入框背景色（比 sheetBackground 略亮，形成层次感）。
  static Color sheetInputBackground(bool isDark) =>
      isDark ? ColorConstants.config_color_config_tone_ff1c1c28 : ColorConstants.config_color_config_tone_fff5f5f5;

  /// 消息分类主色列表。
  ///
  /// 后续新增消息类型时，优先从这里扩展颜色，页面直接按索引读取。
  static final List<Color> messageTypeAccentColorList = <Color>[
    ColorConstants.message_type_accent_color_list, // 1 主题金（原消息中心色）
    ColorConstants.util_dialog_show_upgrade_dialog_tone_ff8db7ff, // 2 清透蓝（原消息中心色）
    ColorConstants.message_type_accent_color_list_ffff9e80, // 3 暖珊瑚（原消息中心色）
    ColorConstants.message_type_accent_color_list_ffffc76a, // 4 琥珀金（同系扩展）
    ColorConstants.message_type_accent_color_list_ff7ec2ff, // 5 天空蓝（同系扩展）
    ColorConstants.message_type_accent_color_list_ffffb39a, // 6 蜜桃珊瑚（同系扩展）
    ColorConstants.message_type_accent_color_list_ffa7d8a8, // 7 薄荷绿（同系扩展）
    ColorConstants.message_type_accent_color_list_ffd6b0ff, // 8 淡紫（同系扩展）
  ];

  /// 小说标签颜色列表。
  static final List<Color> tagColorList = <Color>[
    ColorConstants.tag_color_list, // 活力蓝
    ColorConstants.tag_color_list_ffff7a59, // 珊瑚橙
    ColorConstants.tag_color_list_ff4cbf8a, // 翡翠绿
    ColorConstants.tag_color_list_ffffb020, // 琥珀黄
    ColorConstants.tag_color_list_ffe85d75, // 玫瑰红
  ];

  /// 根据索引读取消息类型主色，越界时循环取值。
  static Color resolveMessageTypeAccentColor(int index) {
    if (messageTypeAccentColorList.isEmpty) {
      return ColorConstants.themeColor;
    }
    final int safeIndex = index % messageTypeAccentColorList.length;
    return messageTypeAccentColorList[safeIndex];
  }

  /// 根据索引读取标签颜色，越界时循环取值。
  static Color resolveTagColor(int index) {
    if (tagColorList.isEmpty) {
      return ColorConstants.themeColor;
    }
    final int safeIndex = index % tagColorList.length;
    return tagColorList[safeIndex];
  }

  /// 判断消息强调色是否属于主题金系。
  ///
  /// 目前将主主题金和琥珀金都归入该类别。
  static bool isMessageGoldAccent(Color color) {
    return color.value == ColorConstants.message_type_accent_color_list.value ||
        color.value == ColorConstants.message_type_accent_color_list_ffffc76a.value;
  }

  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_0007142d = Color(0x0007142d);
  /// pages/tile_quest/widgets/tile_surface_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_shadow_color_00120d0a = Color(0x00120d0a);
  /// pages/comics/mine/widgets/mine_comic_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color meta_color_00222222 = Color(0x00222222);
  /// components/work_hero_stats/style.dart、pages/change_nickname/index.dart、pages/tile_quest/widgets/quest_controls.dart、pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color transparent_white = Color(0x00ffffff);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color transparent_white_0cffffff = Color(0x0cffffff);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_0d07142d = Color(0x0d07142d);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_10222222 = Color(0x10222222);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color ripple_light_12f8d02d = Color(0x12f8d02d);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color ripple_dark_18f8d02d = Color(0x18f8d02d);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_1a07142d = Color(0x1a07142d);
  /// pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_light_shimmer_base_color_1a9e9e9e = Color(0x1a9e9e9e);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_1fe7edf6 = Color(0x1fe7edf6);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_24232c40 = Color(0x24232c40);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_24e8effa = Color(0x24e8effa);
  /// pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_light_color_269e9e9e = Color(0x269e9e9e);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color transparent_white_28ffffff = Color(0x28ffffff);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_2907142d = Color(0x2907142d);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_2be4ebf4 = Color(0x2be4ebf4);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color blocked_veil_324a4038 = Color(0x324a4038);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_36121e32 = Color(0x36121e32);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color shadow_color_382a1c14 = Color(0x382a1c14);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color contact_color_3d37271f = Color(0x3d37271f);
  /// components/recommend_book_card/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color scrim_close_button = Color(0x40222222);
  /// pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_light_shimmer_highlight_color_409e9e9e = Color(0x409e9e9e);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_4207142d = Color(0x4207142d);
  /// pages/tile_quest/widgets/tile_surface_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_shadow_color_42120d0a = Color(0x42120d0a);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_highlight_42ffffff = Color(0x42ffffff);
  /// pages/short_story_read/widgets/collapse_button.dart、pages/short_story_read/widgets/story_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color shadow_color_4c222222 = Color(0x4c222222);
  /// components/authorized_login/apple_review/index.dart、components/cute_mascot/index.dart、pages/read/widgets/reading_settings_sheet/index.dart、pages/user_info/widgets/user_info_top.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_authorized_login_apple_review_index_tone_4cffffff = Color(0x4cffffff);
  /// pages/tile_quest/widgets/tile_surface_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_shadow_color_4d563d2d = Color(0x4d563d2d);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color transparent_white_50ffffff = Color(0x50ffffff);
  /// components/work_hero_stats/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_color_52ffffff = Color(0x52ffffff);
  /// pages/tile_quest/widgets/tile_surface_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_contact_color_6650392a = Color(0x6650392a);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color trailing_border_66fff6c9 = Color(0x66fff6c9);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color trailing_background_66fffade = Color(0x66fffade);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_star_shadow_a9eca936 = Color(0xa9eca936);
  /// components/reader_bottom_action/style.dart、components/reader_top_bar/style.dart、pages/comics/reader/style.dart、pages/read/widgets/auto_read_settings_button/index.dart 等 7 处 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_reader_bottom_action_style_tone_b2ffffff = Color(0xb2ffffff);
  /// components/work_introduction_hero/style.dart、pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color backdrop_scrim_night = Color(0xb3242428);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color primary_edge_bffff0af = Color(0xbffff0af);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color top_highlight_d9fff8d5 = Color(0xd9fff8d5);
  /// pages/tile_quest/widgets/layout_debug_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color panel_color_dd091628 = Color(0xdd091628);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color session_scrim_e807152d = Color(0xe807152d);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_mint = Color(0xff00b980);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff050506 = Color(0xff050506);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color modal_barrier_ff07152d = Color(0xff07152d);
  /// pages/comics/reader/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color canvas_background_ff0a0b0e = Color(0xff0a0b0e);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color slot_well_background_ff0b1931 = Color(0xff0b1931);
  /// pages/comics/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color reader_background_ff0c0d10 = Color(0xff0c0d10);
  /// pages/image_text/index.dart、pages/top_up/index.dart、pages/top_up_qr_code/index.dart、pages/top_up_record/style.dart 等 5 处 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_gradient_deepest = Color(0xff0c0d14);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_statistics_background_ff0c1d36 = Color(0xff0c1d36);
  /// components/auth_page/style.dart、pages/bill/widgets/bill_page_background.dart、pages/change_nickname/style.dart、pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_gradient_end = Color(0xff0d0e14);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_paper_color_dark_ff111214 = Color(0xff111214);
  /// pages/image_text/index.dart、pages/top_up/index.dart、pages/top_up_qr_code/index.dart、pages/top_up_record/style.dart 等 5 处 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_gradient_deep = Color(0xff11131d);
  /// pages/top_up/widgets/top_up_type_picker_sheet.dart、pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_sheet_gradient_end = Color(0xff111420);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color ink_ff14213e = Color(0xff14213e);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_scrim_ff142846 = Color(0xff142846);
  /// pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_loading_card_color_ff151826 = Color(0xff151826);
  /// pages/tile_quest/tile_preview/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_tile_preview_style_tone_ff15284c = Color(0xff15284c);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_primary_text_ff17191f = Color(0xff17191f);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart、pages/top_up/widgets/top_up_type_picker_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_sheet_gradient_start = Color(0xff171b28);
  /// components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_introduction_hero_test_tone_ff172b3d = Color(0xff172b3d);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_blue = Color(0xff176fff);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_surface_ff181a24 = Color(0xff181a24);
  /// pages/bill/widgets/bill_hero_card.dart、pages/top_up_qr_code/index.dart、pages/top_up_record/style.dart、pages/withdraw/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_hero_gradient_start = Color(0xff181b29);
  /// components/work_introduction_hero/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_background_ff181c23 = Color(0xff181c23);
  /// pages/top_up/widgets/top_up_hero_card.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_hero_gradient_deep = Color(0xff181c29);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unlock_card_dark_color_ff181e27 = Color(0xff181e27);
  /// components/novel_cover/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_dark_text_color_ff182034 = Color(0xff182034);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ff182c45 = Color(0xff182c45);
  /// pages/image_text/index.dart、pages/top_up/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_gradient_mid = Color(0xff191c2a);
  /// components/auth_page/style.dart、pages/bill/widgets/bill_page_background.dart、pages/change_nickname/style.dart、pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_gradient_start = Color(0xff1a1d2c);
  /// pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_loading_card_color_ff1a1e2d = Color(0xff1a1e2d);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_placeholder_dark_end_ff1a1f2b = Color(0xff1a1f2b);
  /// pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_section_tone_ff1a1f2d = Color(0xff1a1f2d);
  /// pages/read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_navigation_bar_color_ff1b2231 = Color(0xff1b2231);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_dark_bg_ff1c2333 = Color(0xff1c2333);
  /// pages/tile_quest/tile_preview/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_tile_preview_style_tone_ff1c3d62 = Color(0xff1c3d62);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff1d1e21 = Color(0xff1d1e21);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color purple_ff1d1e29 = Color(0xff1d1e29);
  /// components/catalog_card/style.dart、components/category_filter/style.dart、pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_popup_surface = Color(0xff1e2130);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_surface_secondary_ff202330 = Color(0xff202330);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff213d35 = Color(0xff213d35);
  /// components/home/style.dart、pages/home/widgets/tab_contents/common_tab_placeholder/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_dark_base = Color(0xff222a39);
  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_ff232a38 = Color(0xff232a38);
  /// components/network_cover_image/style.dart、components/novel_cover/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_skeleton_dark_base = Color(0xff232b39);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unlock_button_text_color_ff24210e = Color(0xff24210e);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color indicator_ring_color_ff242424 = Color(0xff242424);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_surface_ff242630 = Color(0xff242630);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_highlight_ff24272e = Color(0xff24272e);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff252d40 = Color(0xff252d40);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ff252d53 = Color(0xff252d53);
  /// pages/bill/widgets/bill_hero_card.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_hero_card_top = Color(0xff262b3f);
  /// pages/top_up/widgets/top_up_hero_card.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_hero_card_top_warm = Color(0xff263046);
  /// pages/bookshelf/style.dart、pages/ranking_full_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color filter_idle_dark_bg = Color(0xff263247);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color celebration_lilac_ff263e64 = Color(0xff263e64);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff269373 = Color(0xff269373);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_cyan = Color(0xff26c6da);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff2775d8 = Color(0xff2775d8);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color card_tag_dark_bg_ff282b3a = Color(0xff282b3a);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ff28345b = Color(0xff28345b);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color primary_text_ff29240f = Color(0xff29240f);
  /// components/work_introduction_hero/style.dart、pages/comics/detail/style.dart、pages/short_story_read/widgets/introduction/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color backdrop_placeholder_dark = Color(0xff29292c);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff292a2e = Color(0xff292a2e);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_base_ff292d35 = Color(0xff292d35);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_scrim_ff29476d = Color(0xff29476d);
  /// components/novel_cover/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_warm_text_color_ff2a1a10 = Color(0xff2a1a10);
  /// pages/home/widgets/tab_contents/common_tab_placeholder/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color divider_dark_ff2a2f3d = Color(0xff2a2f3d);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_placeholder_dark_start_ff2a3244 = Color(0xff2a3244);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unlock_border_dark_color_ff2a3340 = Color(0xff2a3340);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color purple_ff2b2515 = Color(0xff2b2515);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color emoji_panel_divider_dark_color_ff2b2b2b = Color(0xff2b2b2b);
  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_ff2c3444 = Color(0xff2c3444);
  /// components/recommend_book_card/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_dark_highlight_color_ff2f3346 = Color(0xff2f3346);
  /// components/work_hero_stats_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_test_tone_ff306ead = Color(0xff306ead);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color input_border_dark_color_ff343434 = Color(0xff343434);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color celebration_lilac_ff344f78 = Color(0xff344f78);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_highlight_ff363b44 = Color(0xff363b44);
  /// components/home/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_dark_highlight = Color(0xff374255);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff382d43 = Color(0xff382d43);
  /// components/comment_list/widgets/comment_actions_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color separator_dark_ff38383a = Color(0xff38383a);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_highlight_ff393e48 = Color(0xff393e48);
  /// components/app_modal_full_window_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_app_modal_full_window_test_tone_ff3a7bbe = Color(0xff3a7bbe);
  /// pages/read/widgets/content/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color reading_text_color_light_ff3b3226 = Color(0xff3b3226);
  /// common_style/selection_chip/style.dart、components/category_filter/style.dart、pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_accent_deep_bg = Color(0xff3d3520);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color content_light_color_ff3d3d3d = Color(0xff3d3d3d);
  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color strength_strong_ff409eff = Color(0xff409eff);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_ink_ff42a5f5 = Color(0xff42a5f5);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff443124 = Color(0xff443124);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dislike_drag_handle_dark_color_ff444444 = Color(0xff444444);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color like_disabled_color_dark_ff4a4a4e = Color(0xff4a4a4e);
  /// components/work_reading_actions/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color trailing_foreground_ff4e3d0e = Color(0xff4e3d0e);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff516889 = Color(0xff516889);
  /// components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_introduction_hero_test_tone_ff537894 = Color(0xff537894);
  /// components/no_internet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color icon_dark_color_ff555555 = Color(0xff555555);
  /// pages/home/widgets/tab_contents/common_tab_placeholder/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color number_dark_ff555566 = Color(0xff555566);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff557aa0 = Color(0xff557aa0);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff557d60 = Color(0xff557d60);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color green_ff55b98a = Color(0xff55b98a);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff577d70 = Color(0xff577d70);
  /// components/expandable_synopsis/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color embedded_text_light_ff5f626c = Color(0xff5f626c);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff60bbff = Color(0xff60bbff);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ff637fe6 = Color(0xff637fe6);
  /// pages/tile_quest/shuffle_textures_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_shuffle_textures_test_tone_ff63bca4 = Color(0xff63bca4);
  /// components/bottom_sheet_drag_handle/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_color_ff65656a = Color(0xff65656a);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_crest_glow_edge_ff657bb6 = Color(0xff657bb6);
  /// pages/author_center/author_style.dart、pages/user_info/widgets/statistics/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color accent_sky_blue = Color(0xff6596ff);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_green = Color(0xff66bb6a);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color arrow_background_ff6f5003 = Color(0xff6f5003);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff70dda0 = Color(0xff70dda0);
  /// pages/read/widgets/introduction_section/widgets/hero/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color status_light_ff72737e = Color(0xff72737e);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hint_grey_dark = Color(0xff737373);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff765d91 = Color(0xff765d91);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_card_meta_text = Color(0xff777788);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_secondary_text_ff777a84 = Color(0xff777a84);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color slot_well_border_ff7796ba = Color(0xff7796ba);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color wall_bottom_ff786058 = Color(0xff786058);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color card_more_dark_text_ff7aa3ff = Color(0xff7aa3ff);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_placeholder_light_icon_ff7c664a = Color(0xff7c664a);
  /// pages/tile_quest/widgets/layout_debug_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color open_color_ff7cffce = Color(0xff7cffce);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_purple = Color(0xff7e57c2);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff80688d = Color(0xff80688d);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_ink_ff824bff = Color(0xff824bff);
  /// components/share_poster_card_test.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ff8a755d = Color(0xff8a755d);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_secondary_text_color_ff8a8985 = Color(0xff8a8985);
  /// components/recommend_book_card/animated_waterfall.dart、pages/ranking_full_list/widgets/bookshelf_grid_content.dart、pages/search/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_violet = Color(0xff8b7cff);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color comment_secondary_grey = Color(0xff8c8c8c);
  /// components/comment_list/widgets/comment_actions_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color subtitle_color_ff8e8e93 = Color(0xff8e8e93);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color action_light_color_ff8f8f8f = Color(0xff8f8f8f);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color wall_floor_ff90776d = Color(0xff90776d);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color wall_mid_ff907868 = Color(0xff907868);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color comment_meta_grey = Color(0xff929292);
  /// components/network_cover_image/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_error_foreground_color_ff97a3b6 = Color(0xff97a3b6);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff9960c6 = Color(0xff9960c6);
  /// components/recommend_book_card/style.dart、pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_secondary_text = Color(0xff999aaa);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color deep_gold_ff9a7300 = Color(0xff9a7300);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color purple_ff9a86ff = Color(0xff9a86ff);
  /// pages/author_center/widgets/backend_work_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color desc_color_ff9b7a58 = Color(0xff9b7a58);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tray_well_border_ff9dbcdc = Color(0xff9dbcdc);
  /// comics/detail/layout_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color comics_detail_layout_test_tone_ff9e947c = Color(0xff9e947c);
  /// pages/tile_quest/tile_preview/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color section_title_ff9fc2e8 = Color(0xff9fc2e8);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ff9fe9cc = Color(0xff9fe9cc);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_secondary_text_ffa6a9b4 = Color(0xffa6a9b4);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffa86758 = Color(0xffa86758);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color wall_top_ffa89080 = Color(0xffa89080);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_secondary_text_color_dark_ffa9a7a1 = Color(0xffa9a7a1);
  /// components/work_hero_stats_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_hero_stats_test_tone_ffad713b = Color(0xffad713b);
  /// components/network_cover_image/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dark_error_foreground_color_ffadb9cb = Color(0xffadb9cb);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_crest_glow_ffadbbe8 = Color(0xffadbbe8);
  /// common_style/input_bar/style.dart、components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hint_grey_light = Color(0xffb2b2b2);
  /// components/bottom_sheet_drag_handle/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_color_ffb8b8bd = Color(0xffb8b8bd);
  /// pages/tile_quest/tile_preview/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color caption_ffb8cce8 = Color(0xffb8cce8);
  /// pages/bill/widgets/bill_record_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_glow_color_ffb8ccff = Color(0xffb8ccff);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffbbdcf7 = Color(0xffbbdcf7);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color wall_ledge_ffc0a898 = Color(0xffc0a898);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color celebration_lilac_ffc1b4ff = Color(0xffc1b4ff);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffc6e6d7 = Color(0xffc6e6d7);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffc8a96b = Color(0xffc8a96b);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color blocked_multiply_ffc8beb2 = Color(0xffc8beb2);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffc8d7e8 = Color(0xffc8d7e8);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffc9ddcd = Color(0xffc9ddcd);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pale_ffcfdff7 = Color(0xffcfdff7);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffcfe8ec = Color(0xffcfe8ec);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffd0dcf7 = Color(0xffd0dcf7);
  /// components/comment_list/widgets/comment_actions_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color separator_light_ffd1d1d6 = Color(0xffd1d1d6);
  /// common_style/selection_chip/style.dart、components/category_filter/style.dart、pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_accent_text = Color(0xffd4920a);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffd7c7f6 = Color(0xffd7c7f6);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffd7cbe8 = Color(0xffd7cbe8);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color face_bottom_ffd8b898 = Color(0xffd8b898);
  /// components/share_poster_card_test.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffd8d1c4 = Color(0xffd8d1c4);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color result_moon_ffd8dff7 = Color(0xffd8dff7);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_placeholder_light_end_ffdabf9a = Color(0xffdabf9a);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffdce6f1 = Color(0xffdce6f1);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffdce9de = Color(0xffdce9de);
  /// pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color dislike_drag_handle_light_color_ffdddddd = Color(0xffdddddd);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color mint_ffde91ee = Color(0xffde91ee);
  /// pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pending_status_light_color_ffe2a400 = Color(0xffe2a400);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe2d7f4 = Color(0xffe2d7f4);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color content_dark_color_ffe3e3e3 = Color(0xffe3e3e3);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe4effa = Color(0xffe4effa);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_placeholder_light_start_ffe5d2b6 = Color(0xffe5d2b6);
  /// components/recommend_book_card/animated_waterfall.dart、pages/ranking_full_list/widgets/bookshelf_grid_content.dart、pages/search/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_amber = Color(0xffe6a23c);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffe6def0 = Color(0xffe6def0);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unlock_border_light_color_ffe6e9ef = Color(0xffe6e9ef);
  /// pages/change_nickname/style.dart、pages/change_password/style.dart、pages/user_info_input/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_button_gradient_end = Color(0xffe7bc3c);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe7d4ba = Color(0xffe7d4ba);
  /// components/share_poster_card_test.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffe7e2d8 = Color(0xffe7e2d8);
  /// pages/tile_quest/shuffle_textures_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_tile_quest_shuffle_textures_test_tone_ffe8be90 = Color(0xffe8be90);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_ffe8c9c0 = Color(0xffe8c9c0);
  /// components/network_cover_image/style.dart、components/novel_cover/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_skeleton_light_base = Color(0xffe8ecf3);
  /// pages/bookshelf/style.dart、pages/ranking_full_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color filter_idle_light_bg = Color(0xffe8edf7);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe8eeff = Color(0xffe8eeff);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe8f6f0 = Color(0xffe8f6f0);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_base_ffe9e9e7 = Color(0xffe9e9e7);
  /// components/home/style.dart、pages/home/widgets/tab_contents/common_tab_placeholder/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color skeleton_light_base = Color(0xffe9edf4);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_ffe9f5f7 = Color(0xffe9f5f7);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ffe9f7ff = Color(0xffe9f7ff);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_pink = Color(0xffec407a);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color input_border_light_color_ffececed = Color(0xffececed);
  /// common_style/selection_chip/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color unselected_light_bg_ffeceef3 = Color(0xffeceef3);
  /// components/work_introduction_hero_test.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color components_work_introduction_hero_test_tone_ffedd39b = Color(0xffedd39b);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ffeef1ff = Color(0xffeef1ff);
  /// pages/user_info/widgets/tile_quest_entry/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_user_info_widgets_tile_quest_entry_style_tone_ffeef2ff = Color(0xffeef2ff);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_ink_ffef5350 = Color(0xffef5350);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color emoji_panel_divider_light_color_ffefeff0 = Color(0xffefeff0);
  /// pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_gradient_end_alt = Color(0xfff0d86b);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff0ddd7 = Color(0xfff0ddd7);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff0eafe = Color(0xfff0eafe);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff0f4f8 = Color(0xfff0f4f8);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff0f5f1 = Color(0xfff0f5f1);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color tag_light_bg_fff0f7ff = Color(0xfff0f7ff);
  /// pages/bill/widgets/bill_hero_card.dart、pages/top_up/widgets/top_up_hero_card.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_gradient_end = Color(0xfff1d875);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff2e0a6 = Color(0xfff2e0a6);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color face_main_fff2e2cc = Color(0xfff2e2cc);
  /// pages/search/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hot_keyword_light_background_fff2e8d8 = Color(0xfff2e8d8);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color title_dark_color_fff2f2f2 = Color(0xfff2f2f2);
  /// components/comment_list/widgets/comment_actions_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color spacer_light_fff2f2f7 = Color(0xfff2f2f7);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff3d2c7 = Color(0xfff3d2c7);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff3eefb = Color(0xfff3eefb);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_primary_text_color_dark_fff3f0e9 = Color(0xfff3f0e9);
  /// components/share_poster_card_test.dart、components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff3f0ea = Color(0xfff3f0ea);
  /// components/network_cover_image/style.dart、components/novel_cover/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color cover_fallback_light_bg = Color(0xfff3f5f9);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color celebration_lilac_fff4bc54 = Color(0xfff4bc54);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_brand_surface_color_dark_fff4f0e7 = Color(0xfff4f0e7);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff4f0f8 = Color(0xfff4f0f8);
  /// components/work_detail_skeleton/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_highlight_fff5f5f3 = Color(0xfff5f5f3);
  /// pages/bill/widgets/bill_page_background.dart、pages/image_text/index.dart、pages/top_up/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_page_gradient_start = Color(0xfff6f0d8);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color light_background_fff6f7fa = Color(0xfff6f7fa);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff7c9c0 = Color(0xfff7c9c0);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff7d1d7 = Color(0xfff7d1d7);
  /// pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_section_tone_fff7f5ee = Color(0xfff7f5ee);
  /// pages/top_up/widgets/top_up_type_picker_sheet.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_picker_sheet_tone_fff7f6ef = Color(0xfff7f6ef);
  /// pages/top_up_qr_code/index.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_page_gradient_end_alt = Color(0xfff7f7f2);
  /// pages/bill/widgets/bill_page_background.dart、pages/withdraw/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_page_gradient_end = Color(0xfff7f7f3);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fff8eee0 = Color(0xfff8eee0);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_qr_color_fff8f0ed = Color(0xfff8f0ed);
  /// components/auth_page/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color password_icon_color_fff8f6ef = Color(0xfff8f6ef);
  /// components/comment_list/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color like_active_color_fffa5151 = Color(0xfffa5151);
  /// pages/tile_quest/widgets/tile_quest_tile_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color face_center_fffaf2e4 = Color(0xfffaf2e4);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fffcebec = Color(0xfffcebec);
  /// stores/bookshelf_store.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color stores_bookshelf_store_tone_fffdeeea = Color(0xfffdeeea);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_ink_ffff4088 = Color(0xffff4088);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color coral_ffff8a72 = Color(0xffff8a72);
  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color strength_fair_ffff9e3d = Color(0xffff9e3d);
  /// components/recommend_book_card/animated_waterfall.dart、pages/ranking_full_list/widgets/bookshelf_grid_content.dart、pages/search/index.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_orange = Color(0xffff9f5a);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color hero_ink_ffffa100 = Color(0xffffa100);
  /// pages/comics/detail/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color palette_tangerine = Color(0xffffa726);
  /// pages/tile_quest/widgets/layout_debug_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color blocked_color_ffffae7c = Color(0xffffae7c);
  /// pages/short_story_read/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color favorite_active_color_ffffb800 = Color(0xffffb800);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_surface_ffffbc32 = Color(0xffffbc32);
  /// pages/comics/widgets/chapter_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_style_tone_ffffcc25 = Color(0xffffcc25);
  /// pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pending_status_dark_color_ffffd166 = Color(0xffffd166);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_ffffd879 = Color(0xffffd879);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_surface_ffffdb27 = Color(0xffffdb27);
  /// pages/comics/detail/widgets/reading_action_bar.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_detail_widgets_reading_action_bar_tone_ffffdf42 = Color(0xffffdf42);
  /// pages/tile_quest/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color celebration_lilac_ffffe6a0 = Color(0xffffe6a0);
  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_ffffeaa5 = Color(0xffffeaa5);
  /// pages/comics/widgets/chapter_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_comics_widgets_chapter_sheet_style_tone_ffffec75 = Color(0xffffec75);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color purple_fffff0b8 = Color(0xfffff0b8);
  /// pages/comics/detail/widgets/reading_action_bar_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color night_surface_fffff295 = Color(0xfffff295);
  /// pages/bill/widgets/bill_hero_card.dart、pages/top_up/widgets/top_up_hero_card.dart、pages/top_up_qr_code/widgets/top_up_qr_hero_card.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_gradient_start = Color(0xfffff2b2);
  /// pages/withdraw/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_style_tone_fffff2be = Color(0xfffff2be);
  /// pages/tile_quest/style.dart、pages/tile_quest/tile_preview/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color game_cream = Color(0xfffff2cf);
  /// pages/top_up_qr_code/index.dart、pages/top_up_record/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color gold_page_gradient_start = Color(0xfffff3c1);
  /// common_style/selection_chip/style.dart、components/category_filter/style.dart、pages/home/widgets/tab_contents/short_story_tab/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_accent_soft_bg = Color(0xfffff3d6);
  /// pages/change_password/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_change_password_style_tone_fffff3e0 = Color(0xfffff3e0);
  /// components/auth_page/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color password_icon_color_fffff6d6 = Color(0xfffff6d6);
  /// pages/withdraw/widgets/type_selector.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_withdraw_widgets_type_selector_tone_fffff7d8 = Color(0xfffff7d8);
  /// pages/author_center/author_style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color purple_fffffbec = Color(0xfffffbec);
  /// pages/top_up/widgets/top_up_type_section.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color pages_top_up_widgets_top_up_type_section_tone_fffffcf4 = Color(0xfffffcf4);
  /// pages/withdraw/style.dart、util/dialog/pop_up_input.dart、util/dialog/show_message.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color warm_card_gradient_start = Color(0xfffffcf6);
  /// components/share_sheet/style.dart 共用的颜色；修改此处会同步所有同色引用。
  static const Color poster_paper_color_fffffefc = Color(0xfffffefc);

}
