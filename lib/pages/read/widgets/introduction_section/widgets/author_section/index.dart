import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/pages/read/logic.dart';
import './style.dart';

/// 阅读页作者信息组件。
///
/// 用于在小说详情介绍区展示作者头像、姓名以及关注按钮。
class ReadAuthorSection extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  const ReadAuthorSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.on_focus_changed,
  });

  @override
  State<ReadAuthorSection> createState() => _ReadAuthorSectionState();
}

class _ReadAuthorSectionState extends State<ReadAuthorSection> {
  /// 当前关注状态。
  late bool _is_focused;

  /// 是否正在请求中。
  bool _is_loading = false;

  @override
  void initState() {
    super.initState();
    _is_focused = widget.detail.focus_on;
  }

  @override
  void didUpdateWidget(ReadAuthorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.focus_on != widget.detail.focus_on) {
      _is_focused = widget.detail.focus_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 作者信息在封面区中部展示，使用最小宽度避免占满整行。
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ReaderAuthorAvatar(is_dark: widget.is_dark, detail: widget.detail),
          const SizedBox(width: AuthorStyle.author_name_left_spacing),
          Flexible(
            child: _ReaderAuthorName(
              detail: widget.detail,
              is_dark: widget.is_dark,
            ),
          ),
          const SizedBox(width: AuthorStyle.follow_tag_left_spacing),
          _build_follow_tag(),
        ],
      ),
    );
  }

  /// 构建关注标签。
  Widget _build_follow_tag() {
    return GestureDetector(
      onTap: _is_loading ? null : _handle_focus_toggle,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AuthorStyle.follow_tag_horizontal_padding,
            vertical: AuthorStyle.follow_tag_vertical_padding,
          ),
          decoration: BoxDecoration(
            color: _is_focused
                ? Colors.transparent
                : AuthorStyle.brand_color.withValues(
                    alpha: AuthorStyle.follow_tag_background_alpha,
                  ),
            border: _is_focused
                ? Border.all(
                    color: AuthorStyle.brand_color.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(AuthorStyle.follow_tag_radius),
          ),
          child: Text(
            _is_focused ? easy.tr('read.followed') : easy.tr('read.follow'),
            style: TextStyle(
              color: _is_focused
                  ? AuthorStyle.brand_color.withValues(alpha: 0.7)
                  : AuthorStyle.brand_color,
              fontSize: AuthorStyle.follow_tag_font_size,
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
  Future<void> _handle_focus_toggle() async {
    if (_is_loading) return;

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

/// 作者头像组件。
class _ReaderAuthorAvatar extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;

  const _ReaderAuthorAvatar({required this.is_dark, required this.detail});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        detail.author_avatar_url,
        width: AuthorStyle.author_avatar_size,
        height: AuthorStyle.author_avatar_size,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stack_trace) {
              // 头像加载失败时展示作者名首字，保证视觉完整性与可识别性。
              final String fallback_text = detail.author_name.isNotEmpty
                  ? detail.author_name.characters.first
                  : '?';
              return Container(
                width: AuthorStyle.author_avatar_size,
                height: AuthorStyle.author_avatar_size,
                color: AuthorStyle.brand_color.withValues(
                  alpha: AuthorStyle.author_avatar_fallback_background_alpha,
                ),
                alignment: Alignment.center,
                child: Text(
                  fallback_text,
                  style: TextStyle(
                    color: is_dark
                        ? AuthorStyle.author_name_color_dark
                        : AuthorStyle.author_name_color_light,
                    fontSize: AuthorStyle.author_name_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                  ),
                ),
              );
            },
      ),
    );
  }
}

/// 作者名字组件。
class _ReaderAuthorName extends StatelessWidget {
  /// 详情数据。
  final ReadDetail detail;

  /// 当前是否为夜间主题。
  final bool is_dark;

  const _ReaderAuthorName({required this.detail, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    return Text(
      detail.author_name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: is_dark
            ? AuthorStyle.author_name_color_dark
            : AuthorStyle.author_name_color_light,
        fontSize: AuthorStyle.author_name_font_size,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      ),
    );
  }
}
