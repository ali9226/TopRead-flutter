// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:app/config/font_config.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/router/router_util.dart';

import 'logic.dart';
import 'style.dart';

/// 用户信息编辑输入页。
class UserInfoInputPage extends StatefulWidget {
  /// 当前页面视图配置。
  final UserInfoInputViewConfig config;

  /// 关闭当前页面时的目标路由。
  final String close_path;

  const UserInfoInputPage({
    super.key,
    required this.config,
    this.close_path = '/user_info',
  });

  @override
  State<UserInfoInputPage> createState() => _UserInfoInputPageState();
}

class _UserInfoInputPageState extends State<UserInfoInputPage> {
  /// 所有输入框控制器映射。
  final Map<String, TextEditingController> _text_controller_map =
      <String, TextEditingController>{};

  /// 所有输入框焦点映射。
  final Map<String, FocusNode> _focus_node_map = <String, FocusNode>{};

  /// 所有密码输入框当前是否隐藏内容。
  final Map<String, bool> _obscure_state_map = <String, bool>{};

  /// 设备主题仓库。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 当前是否正在提交。
  bool _submit_loading = false;

  @override
  void initState() {
    super.initState();

    /// 初始化全部输入状态集合。
    _init_input_state();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    /// 释放所有文本控制器。
    for (final TextEditingController controller
        in _text_controller_map.values) {
      controller.dispose();
    }

    /// 释放所有焦点节点。
    for (final FocusNode focus_node in _focus_node_map.values) {
      focus_node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 当前是否深色模式。
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    /// 当前页面配置对象。
    final UserInfoInputViewConfig config = widget.config;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismiss_keyboard,
      child: Scaffold(
        backgroundColor: Style.background_color(is_dark: is_dark),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    /// 页面主背景渐变。
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Style.page_background_gradient(is_dark: is_dark),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  /// 背景纹理层。
                  painter: _BackgroundTexturePainter(
                    line_color: Style.texture_line_color(is_dark: is_dark),
                    dot_color: Style.texture_dot_color(is_dark: is_dark),
                  ),
                ),
              ),
            ),
            Positioned(
              top: Style.top_glow_top,
              right: Style.top_glow_right,
              child: IgnorePointer(
                child: _GlowDecor(
                  /// 顶部装饰光斑。
                  size: Style.top_glow_size,
                  colors: Style.top_glow_gradient(is_dark: is_dark),
                ),
              ),
            ),
            Positioned(
              left: Style.bottom_glow_left,
              bottom: Style.bottom_glow_bottom,
              child: IgnorePointer(
                child: _GlowDecor(
                  /// 底部装饰光斑。
                  size: Style.bottom_glow_size,
                  colors: Style.bottom_glow_gradient(is_dark: is_dark),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Style.page_horizontal_padding,
                  Style.page_top_spacing,
                  Style.page_horizontal_padding,
                  Style.page_bottom_spacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      /// 页面标题区。
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        bottom: Style.title_bottom_spacing,
                      ),
                      padding: Style.title_wrap_padding,
                      decoration: BoxDecoration(
                        gradient: Style.title_wrap_gradient(is_dark: is_dark),
                        borderRadius: BorderRadius.circular(
                          Style.title_wrap_radius,
                        ),
                        border: Border.all(
                          color: Style.title_wrap_border_color(
                            is_dark: is_dark,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: Style.title_accent_width,
                            height: Style.title_accent_height,
                            decoration: BoxDecoration(
                              color: Style.title_chip_background_color(
                                is_dark: is_dark,
                              ),
                              borderRadius: BorderRadius.circular(
                                Style.title_accent_radius,
                              ),
                            ),
                          ),
                          const SizedBox(height: Style.title_text_top_spacing),
                          Text(
                            config.title,
                            style: TextStyle(
                              fontSize: Style.page_title_font_size,
                              fontWeight: Style.page_title_font_weight,
                              color: Style.page_title_color(is_dark: is_dark),
                              height: 1.08,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      /// 表单主体卡片。
                      width: double.infinity,
                      padding: Style.form_card_padding,
                      decoration: BoxDecoration(
                        color: Style.card_background_color(is_dark: is_dark),
                        gradient: Style.card_gradient(is_dark: is_dark),
                        borderRadius: BorderRadius.circular(
                          Style.form_card_radius,
                        ),
                        border: Border.all(
                          color: Style.card_border_color(is_dark: is_dark),
                        ),
                        boxShadow: Style.card_shadow(is_dark: is_dark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (config.helper_text.trim().isNotEmpty) ...<Widget>[
                            Container(
                              /// 顶部辅助说明卡。
                              width: double.infinity,
                              padding: Style.helper_card_padding,
                              decoration: BoxDecoration(
                                gradient: Style.helper_card_gradient(
                                  is_dark: is_dark,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Style.helper_card_radius,
                                ),
                                border: Border.all(
                                  color: Style.helper_card_border_color(
                                    is_dark: is_dark,
                                  ),
                                ),
                              ),
                              child: Text(
                                config.helper_text,
                                style: TextStyle(
                                  fontSize: Style.helper_text_font_size,
                                  fontWeight: Style.helper_text_font_weight,
                                  color: Style.helper_text_color(
                                    is_dark: is_dark,
                                  ),
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: Style.helper_bottom_spacing),
                          ],
                          for (
                            int index = 0;
                            index < config.field_list.length;
                            index++
                          ) ...<Widget>[
                            _InputFieldCard(
                              is_dark: is_dark,
                              field_config: config.field_list[index],
                              controller:
                                  _text_controller_map[config
                                      .field_list[index]
                                      .field_key]!,
                              focus_node:
                                  _focus_node_map[config
                                      .field_list[index]
                                      .field_key]!,
                              obscure_text:
                                  _obscure_state_map[config
                                      .field_list[index]
                                      .field_key] ??
                                  config.field_list[index].obscure_text,
                              enabled: !_submit_loading,
                              on_clear_tap: () {
                                /// 点击清空按钮时清空当前输入框内容。
                                _text_controller_map[config
                                        .field_list[index]
                                        .field_key]
                                    ?.clear();
                                setState(() {});
                              },
                              on_visibility_tap:
                                  config.field_list[index].obscure_text
                                  ? () {
                                      setState(() {
                                        /// 切换当前密码输入框显隐状态。
                                        _obscure_state_map[config
                                                .field_list[index]
                                                .field_key] =
                                            !(_obscure_state_map[config
                                                    .field_list[index]
                                                    .field_key] ??
                                                true);
                                      });
                                    }
                                  : null,
                              on_changed: (_) {
                                if (!mounted) return;

                                /// 输入变化时刷新局部状态。
                                setState(() {});
                              },
                              on_submitted: (_) async {
                                /// 键盘提交时跳到下一项或直接提交。
                                await _handle_field_submitted(index);
                              },
                            ),
                            if (index != config.field_list.length - 1)
                              const SizedBox(height: Style.input_spacing),
                          ],
                          const SizedBox(height: Style.submit_top_spacing),
                          SizedBox(
                            width: double.infinity,
                            height: Style.submit_button_height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: Style.submit_button_gradient(
                                  is_dark: is_dark,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Style.submit_button_radius,
                                ),
                                boxShadow: Style.submit_button_shadow(
                                  is_dark: is_dark,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _submit_loading
                                    ? null
                                    : _handle_submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Style.submit_button_radius,
                                    ),
                                  ),
                                ),
                                child: _submit_loading
                                    ? SizedBox(
                                        width: Style.submit_loading_size,
                                        height: Style.submit_loading_size,
                                        child: CircularProgressIndicator(
                                          strokeWidth:
                                              Style.submit_loading_stroke_width,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                ColorConstants.lightTextColor,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        config.submit_button_text,
                                        style: TextStyle(
                                          fontSize:
                                              Style.submit_button_font_size,
                                          fontWeight:
                                              Style.submit_button_font_weight,
                                          color: ColorConstants.lightTextColor,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LanguageSelection(
                title: '',
                showLeftIcon: true,
                useSafeAreaTop: true,
                topOffset: 0,
                horizontalPadding: Style.page_horizontal_padding,
                onLeftTapOverride: _handle_close,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 初始化输入框状态集合。
  void _init_input_state() {
    for (final UserInfoInputFieldConfig field_config
        in widget.config.field_list) {
      final TextEditingController text_controller = TextEditingController();
      text_controller.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
      _text_controller_map[field_config.field_key] = text_controller;
      _focus_node_map[field_config.field_key] = FocusNode();
      _obscure_state_map[field_config.field_key] = field_config.obscure_text;
    }
  }

  /// 关闭虚拟键盘。
  void _dismiss_keyboard() {
    FocusScope.of(context).unfocus();
  }

  /// 处理顶部关闭动作。
  void _handle_close() {
    _dismiss_keyboard();
    routerUtil(path: widget.close_path, type: 'replace');
  }

  /// 处理输入框提交动作。
  Future<void> _handle_field_submitted(int index) async {
    final List<UserInfoInputFieldConfig> field_list = widget.config.field_list;
    if (index >= field_list.length - 1) {
      await _handle_submit();
      return;
    }

    final String next_key = field_list[index + 1].field_key;
    _focus_node_map[next_key]?.requestFocus();
  }

  /// 获取当前全部输入值。
  Map<String, String> _build_input_value_map() {
    final Map<String, String> input_value_map = <String, String>{};
    for (final UserInfoInputFieldConfig field_config
        in widget.config.field_list) {
      input_value_map[field_config.field_key] =
          _text_controller_map[field_config.field_key]?.text ?? '';
    }
    return input_value_map;
  }

  /// 处理提交动作。
  Future<void> _handle_submit() async {
    if (_submit_loading) return;

    _dismiss_keyboard();

    bool should_close = false;
    setState(() {
      _submit_loading = true;
    });
    try {
      should_close = await widget.config.on_submit(_build_input_value_map());
    } finally {
      if (mounted) {
        setState(() {
          _submit_loading = false;
        });
      }
    }

    if (!mounted) return;
    if (!should_close) return;
    routerUtil(path: widget.close_path, type: 'replace');
  }
}

/// 单个输入框卡片。
class _InputFieldCard extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 当前输入框配置。
  final UserInfoInputFieldConfig field_config;

  /// 当前输入框控制器。
  final TextEditingController controller;

  /// 当前输入框焦点。
  final FocusNode focus_node;

  /// 当前输入框是否隐藏文本。
  final bool obscure_text;

  /// 当前输入框是否可用。
  final bool enabled;

  /// 清空按钮点击回调。
  final VoidCallback on_clear_tap;

  /// 密码显隐切换点击回调。
  final VoidCallback? on_visibility_tap;

  /// 输入变化回调。
  final ValueChanged<String> on_changed;

  /// 输入框提交回调。
  final ValueChanged<String> on_submitted;

  const _InputFieldCard({
    required this.is_dark,
    required this.field_config,
    required this.controller,
    required this.focus_node,
    required this.obscure_text,
    required this.enabled,
    required this.on_clear_tap,
    required this.on_changed,
    required this.on_submitted,
    this.on_visibility_tap,
  });

  @override
  Widget build(BuildContext context) {
    final bool has_text = controller.text.isNotEmpty;

    return Container(
      padding: Style.input_shell_padding,
      decoration: BoxDecoration(
        color: Style.input_shell_background_color(is_dark: is_dark),
        borderRadius: BorderRadius.circular(Style.input_shell_radius),
        border: Border.all(
          color: Style.input_shell_border_color(is_dark: is_dark),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focus_node,
        obscureText: obscure_text,
        keyboardType: field_config.keyboard_type,
        textInputAction: field_config.text_input_action,
        maxLength: field_config.max_length,
        enabled: enabled,
        onChanged: on_changed,
        onSubmitted: on_submitted,
        style: TextStyle(
          fontSize: Style.input_font_size,
          color: Style.input_text_color(is_dark: is_dark),
          fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
        ),
        decoration: InputDecoration(
          hintText: field_config.hint_text,
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isCollapsed: true,
          hintStyle: TextStyle(
            fontSize: Style.input_hint_font_size,
            color: Style.input_hint_color(is_dark: is_dark),
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: Style.suffix_action_wrap_min_width,
            minHeight: Style.suffix_action_wrap_min_height,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (has_text)
                _FieldActionButton(
                  onTap: on_clear_tap,
                  icon: Icons.close_rounded,
                  icon_color: Style.field_action_icon_color(is_dark: is_dark),
                ),
              if (field_config.obscure_text)
                _FieldActionButton(
                  onTap: on_visibility_tap,
                  icon: obscure_text
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  icon_color: Style.field_action_icon_color(is_dark: is_dark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 输入框尾部操作按钮。
class _FieldActionButton extends StatelessWidget {
  /// 点击回调。
  final VoidCallback? onTap;

  /// 图标。
  final IconData icon;

  /// 图标颜色。
  final Color icon_color;

  const _FieldActionButton({
    required this.onTap,
    required this.icon,
    required this.icon_color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(
          icon,
          size: Style.field_action_icon_size,
          color: icon_color,
        ),
      ),
    );
  }
}

/// 发光装饰块。
class _GlowDecor extends StatelessWidget {
  /// 装饰尺寸。
  final double size;

  /// 渐变颜色。
  final List<Color> colors;

  const _GlowDecor({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

/// 背景纹理绘制器。
class _BackgroundTexturePainter extends CustomPainter {
  /// 纹理线条颜色。
  final Color line_color;

  /// 纹理点颜色。
  final Color dot_color;

  const _BackgroundTexturePainter({
    required this.line_color,
    required this.dot_color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line_paint = Paint()
      ..color = line_color
      ..strokeWidth = 1;
    final Paint dot_paint = Paint()..color = dot_color;

    const double gap = Style.texture_gap;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        line_paint,
      );
    }

    for (double x = gap * 0.5; x < size.width; x += gap * 1.4) {
      for (double y = gap * 0.6; y < size.height; y += gap * 1.4) {
        canvas.drawCircle(Offset(x, y), Style.texture_dot_radius, dot_paint);
      }
    }

    final Paint arc_paint = Paint()
      ..color = line_color.withValues(alpha: line_color.a * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Rect arc_rect = Rect.fromCenter(
      center: Offset(size.width * 0.78, size.height * 0.22),
      width: size.width * 0.44,
      height: size.width * 0.44,
    );
    canvas.drawArc(arc_rect, -math.pi * 0.15, math.pi * 0.72, false, arc_paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundTexturePainter old_delegate) {
    return old_delegate.line_color != line_color ||
        old_delegate.dot_color != dot_color;
  }
}
