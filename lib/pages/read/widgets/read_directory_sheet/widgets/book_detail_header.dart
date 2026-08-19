import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 目录弹窗顶部书籍信息头组件。
class BookDetailHeader extends StatefulWidget {
  /// 书籍详情数据。
  final ReadDetail detail;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  const BookDetailHeader({
    super.key,
    required this.detail,
    required this.is_dark,
    this.on_focus_changed,
  });

  @override
  State<BookDetailHeader> createState() => _BookDetailHeaderState();
}

class _BookDetailHeaderState extends State<BookDetailHeader> {
  /// 当前关注状态。
  late bool _is_focused;

  /// 是否正在请求中。
  bool _is_loading = false;

  /// 随机选择的默认头像索引（0-9）。
  late final int _random_avatar_index;

  @override
  void initState() {
    super.initState();
    _is_focused = widget.detail.focus_on;
    _random_avatar_index = Random().nextInt(10);
  }

  @override
  void didUpdateWidget(BookDetailHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.focus_on != widget.detail.focus_on) {
      _is_focused = widget.detail.focus_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color title_color = ReadDirectorySheetStyle.getPrimaryTextColor(
      widget.is_dark,
    );
    final Color sub_text_color = ReadDirectorySheetStyle.getSubTextColor(
      widget.is_dark,
    );
    final double title_font_size = is_cjk
        ? ReadDirectorySheetStyle.book_title_font_size_cjk
        : ReadDirectorySheetStyle.book_title_font_size_alphabetic;
    final double author_font_size = is_cjk
        ? ReadDirectorySheetStyle.author_name_font_size_cjk
        : ReadDirectorySheetStyle.author_name_font_size_alphabetic;
    final double shadow_alpha = widget.is_dark ? 0.34 : 0.11;

    return Padding(
      padding: ReadDirectorySheetStyle.header_padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 书籍封面使用固定比例，避免不同封面尺寸撑动目录头部。
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadow_alpha),
                  blurRadius: ReadDirectorySheetStyle.cover_shadow_blur_radius,
                  offset: const Offset(
                    0,
                    ReadDirectorySheetStyle.cover_shadow_offset_y,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ReadDirectorySheetStyle.cover_border_radius,
              ),
              child: widget.detail.cover_url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.detail.cover_url,
                      width: ReadDirectorySheetStyle.cover_width,
                      height: ReadDirectorySheetStyle.cover_height,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: ReadDirectorySheetStyle.cover_width,
                      height: ReadDirectorySheetStyle.cover_height,
                      color: sub_text_color.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.book_rounded,
                        size: 26,
                        color: sub_text_color,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: ReadDirectorySheetStyle.header_content_spacing),
          // 书籍信息保持单行省略，避免长标题影响 Tab 区域。
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {},
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.detail.title,
                          style: TextStyle(
                            color: title_color,
                            fontSize: title_font_size,
                            height: 1.15,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: title_color.withValues(alpha: 0.3),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: ReadDirectorySheetStyle.title_author_spacing,
                ),
                if (widget.detail.author_avatar_url.isNotEmpty ||
                    widget.detail.author_name.trim().isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: widget.detail.author_avatar_url.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.detail.author_avatar_url,
                                  width: ReadDirectorySheetStyle.author_avatar_radius * 2,
                                  height: ReadDirectorySheetStyle.author_avatar_radius * 2,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      _buildFallbackAvatar(),
                                ),
                              )
                            : _buildFallbackAvatar(),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (widget.detail.author_name.trim().isNotEmpty)
                              Flexible(
                                child: Text(
                                  widget.detail.author_name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: sub_text_color,
                                    fontSize: author_font_size,
                                    fontWeight: FontConfig.adjustedWeight(
                                      FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            _buildFollowButton(is_cjk: is_cjk),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建随机 SVG 兜底头像。
  Widget _buildFallbackAvatar() {
    return SvgPicture.asset(
      'assets/svg/avatar_${_random_avatar_index.toString().padLeft(2, '0')}.svg',
      width: ReadDirectorySheetStyle.author_avatar_radius * 2,
      height: ReadDirectorySheetStyle.author_avatar_radius * 2,
    );
  }

  /// 构建作者关注按钮，文案遵循当前语种。
  Widget _buildFollowButton({required bool is_cjk}) {
    // 夜间模式使用主题色，日间模式使用品牌蓝色。
    final Color accent_color =
        widget.is_dark ? ColorConstants.themeColor : const Color(0xFF3D7DFF);
    final String follow_text = _is_focused
        ? tr('read.followed')
        : tr('read.follow');
    final double follow_font_size = is_cjk
        ? ReadDirectorySheetStyle.follow_button_font_size_cjk
        : ReadDirectorySheetStyle.follow_button_font_size_alphabetic;

    return GestureDetector(
      onTap: _is_loading ? null : _handle_follow_toggle,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 560),
        curve: Curves.elasticOut,
        tween: Tween<double>(
          begin: 0.6,
          end: _is_focused ? 1.0 : 1.0,
        ),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        key: ValueKey(_is_focused),
        child: Container(
          padding: ReadDirectorySheetStyle.follow_button_padding,
          decoration: BoxDecoration(
            color: _is_focused
                ? Colors.transparent
                : accent_color.withValues(alpha: 0.16),
            border: _is_focused
                ? Border.all(color: accent_color.withValues(alpha: 0.4), width: 1)
                : null,
            borderRadius: BorderRadius.circular(
              ReadDirectorySheetStyle.follow_button_radius,
            ),
          ),
          child: Text(
            follow_text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _is_focused
                  ? accent_color.withValues(alpha: 0.7)
                  : accent_color,
              fontSize: follow_font_size,
              height: 1,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理关注/取消关注操作（乐观更新）。
  ///
  /// 立即切换状态，请求失败时回退，请求期间防止重复点击。
  Future<void> _handle_follow_toggle() async {
    if (_is_loading) return;

    // 检查登录状态。
    final bool is_logged_in = await showLoginRequiredDialog(
      title: tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    _is_loading = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = _is_focused;
    setState(() {
      _is_focused = !previous_status;
    });
    widget.on_focus_changed?.call(_is_focused);

    final result = await toggle_focus_author(
      author_id: widget.detail.author_id,
    );

    if (!mounted) return;

    _is_loading = false;

    setState(() {
      if (result == null) {
        // 请求失败，回退状态。
        _is_focused = previous_status;
        widget.on_focus_changed?.call(_is_focused);
      } else if (result.focus != _is_focused) {
        // 服务端状态与乐观更新不一致，以服务端为准。
        _is_focused = result.focus;
        widget.on_focus_changed?.call(_is_focused);
      }
    });
  }
}
