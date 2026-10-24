import 'dart:math';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/services/bookshelf_sync_service.dart';
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
  final bool hero;
  final VoidCallback? on_author_tap;

  const ReadAuthorSection({
    super.key,
    required this.is_dark,
    required this.detail,
    this.on_focus_changed,
    this.hero = false,
    this.on_author_tap,
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
    if (oldWidget.detail.author_id != widget.detail.author_id ||
        oldWidget.detail.story_id != widget.detail.story_id ||
        oldWidget.detail.focus_on != widget.detail.focus_on) {
      _is_focused = widget.detail.focus_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final name_painter = TextPainter(
          text: TextSpan(
            text: widget.detail.author_name,
            style: TextStyle(
              fontSize: cjk
                  ? AuthorStyle.hero_name_size_cjk
                  : AuthorStyle.hero_name_size_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final follow_painter = TextPainter(
          text: TextSpan(
            text: easy.tr(_is_focused ? 'read.followed' : 'read.follow'),
            style: TextStyle(
              fontSize: AuthorStyle.follow_tag_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        final required_width =
            AuthorStyle.author_avatar_size +
            AuthorStyle.author_name_left_spacing +
            name_painter.width +
            AuthorStyle.follow_tag_left_spacing +
            follow_painter.width +
            AuthorStyle.follow_tag_horizontal_padding * 2;
        final compact = constraints.maxWidth < required_width;
        name_painter.dispose();
        follow_painter.dispose();
        final author = InkWell(
          onTap: widget.on_author_tap,
          child: Row(
            children: [
              _ReaderAuthorAvatar(
                is_dark: widget.is_dark,
                detail: widget.detail,
              ),
              const SizedBox(width: AuthorStyle.author_name_left_spacing),
              Expanded(
                child: _ReaderAuthorName(
                  detail: widget.detail,
                  is_dark: widget.is_dark,
                  hero: widget.hero,
                ),
              ),
            ],
          ),
        );
        final follow = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: compact
                ? constraints.maxWidth
                : constraints.maxWidth * AuthorStyle.hero_follow_width_ratio,
          ),
          child: _build_follow_tag(),
        );
        // 封面旁的窄列和大字号下将关注按钮另起一行，保留完整作者名。
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              author,
              const SizedBox(height: AuthorStyle.follow_tag_top_spacing),
              follow,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: author),
            const SizedBox(width: AuthorStyle.follow_tag_left_spacing),
            follow,
          ],
        );
      },
    );
  }

  /// 构建关注标签。
  Widget _build_follow_tag() {
    // 夜间模式使用主题色，日间模式使用品牌蓝色。
    final Color accent_color = widget.hero || widget.is_dark
        ? ColorConstants.themeColor
        : AuthorStyle.brand_color;

    return GestureDetector(
      onTap: _is_loading ? null : _handle_focus_toggle,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 560),
        curve: Curves.elasticOut,
        tween: Tween<double>(begin: 0.6, end: _is_focused ? 1.0 : 1.0),
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
                ? ColorConstants.transparent
                : accent_color.withValues(
                    alpha: AuthorStyle.follow_tag_background_alpha,
                  ),
            border: _is_focused
                ? Border.all(
                    color: accent_color.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
            borderRadius: BorderRadius.circular(AuthorStyle.follow_tag_radius),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _is_focused ? easy.tr('read.followed') : easy.tr('read.follow'),
              maxLines: 1,
              style: TextStyle(
                color: _is_focused
                    ? accent_color.withValues(alpha: 0.7)
                    : accent_color,
                fontSize: AuthorStyle.follow_tag_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
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

    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!mounted || !is_logged_in || _is_loading) return;

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

    if (result != null) {
      await BookshelfSyncService.focus_changed();
    }

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
class _ReaderAuthorAvatar extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 详情数据。
  final ReadDetail detail;

  const _ReaderAuthorAvatar({required this.is_dark, required this.detail});

  @override
  State<_ReaderAuthorAvatar> createState() => _ReaderAuthorAvatarState();
}

class _ReaderAuthorAvatarState extends State<_ReaderAuthorAvatar> {
  /// 随机选择的默认头像索引（0-9）。
  late final int _random_avatar_index;

  @override
  void initState() {
    super.initState();
    _random_avatar_index = Random().nextInt(10);
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: widget.detail.author_avatar_url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: widget.detail.author_avatar_url,
              width: AuthorStyle.author_avatar_size,
              height: AuthorStyle.author_avatar_size,
              fit: BoxFit.cover,
              errorWidget: (BuildContext context, String url, Object error) {
                return SvgPicture.asset(
                  'assets/svg/avatar_${_random_avatar_index.toString().padLeft(2, '0')}.svg',
                  width: AuthorStyle.author_avatar_size,
                  height: AuthorStyle.author_avatar_size,
                );
              },
            )
          : SvgPicture.asset(
              'assets/svg/avatar_${_random_avatar_index.toString().padLeft(2, '0')}.svg',
              width: AuthorStyle.author_avatar_size,
              height: AuthorStyle.author_avatar_size,
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
  final bool hero;

  const _ReaderAuthorName({
    required this.detail,
    required this.is_dark,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      detail.author_name,
      style: TextStyle(
        color: hero || is_dark
            ? AuthorStyle.author_name_color_dark
            : AuthorStyle.author_name_color_light,
        fontSize: hero
            ? (LanguageUtil.is_cjk_language(
                    Localizations.localeOf(context).languageCode,
                  )
                  ? AuthorStyle.hero_name_size_cjk
                  : AuthorStyle.hero_name_size_alphabetic)
            : (LanguageUtil.is_cjk_language(
                    Localizations.localeOf(context).languageCode,
                  )
                  ? AuthorStyle.author_name_size_cjk
                  : AuthorStyle.author_name_size_alphabetic),
        height:
            LanguageUtil.is_cjk_language(
              Localizations.localeOf(context).languageCode,
            )
            ? AuthorStyle.author_name_height_cjk
            : AuthorStyle.author_name_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
        shadows: hero ? WorkIntroductionHeroStyle.title_shadows : null,
      ),
    );
  }
}
