import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'style.dart';

/// 仅通过真实字体排版判断三档标题；行数阈值不用于裁切展示内容。
enum WorkHeroTitleTier { regular, reduced, extended }

/// 在局部安全区避让后的宽度内，先测原字号两行，再测小字号四行。
/// 无障碍缩放、语言、行高与实际标题保持一致，不按字符数推测长度。
WorkHeroTitleTier resolve_work_hero_title_tier({
  required BuildContext context,
  required String title,
  required double max_width,
  required TextStyle regular_style,
  required TextStyle reduced_style,
}) {
  bool fits(TextStyle style, int lines) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: lines,
    )..layout(maxWidth: max_width);
    final result = !painter.didExceedMaxLines;
    painter.dispose();
    return result;
  }

  if (fits(regular_style, WorkIntroductionHeroStyle.regular_title_lines)) {
    return WorkHeroTitleTier.regular;
  }
  if (fits(reduced_style, WorkIntroductionHeroStyle.reduced_title_lines)) {
    return WorkHeroTitleTier.reduced;
  }
  return WorkHeroTitleTier.extended;
}

/// 在真实标题布局完成后测量两种候选字号。
///
/// 与首帧纯文字估算不同，这里读取实际RenderParagraph及已布局的WidgetSpan，
/// 将运营ID、替换封面按钮和其他内联内容全部纳入两行/四行判断。
class WorkHeroTitleMeasure extends SingleChildRenderObjectWidget {
  const WorkHeroTitleMeasure({
    super.key,
    required super.child,
    required this.regular_style,
    required this.reduced_style,
    required this.on_tier_changed,
  });

  final TextStyle regular_style;
  final TextStyle reduced_style;
  final ValueChanged<WorkHeroTitleTier> on_tier_changed;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _WorkHeroTitleMeasureRenderBox(
        regular_style: regular_style,
        reduced_style: reduced_style,
        on_tier_changed: on_tier_changed,
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final render_box = renderObject as _WorkHeroTitleMeasureRenderBox;
    render_box
      ..regular_style = regular_style
      ..reduced_style = reduced_style
      ..on_tier_changed = on_tier_changed
      ..markNeedsLayout();
  }
}

class _WorkHeroTitleMeasureRenderBox extends RenderProxyBox {
  _WorkHeroTitleMeasureRenderBox({
    required this.regular_style,
    required this.reduced_style,
    required this.on_tier_changed,
  });

  TextStyle regular_style;
  TextStyle reduced_style;
  ValueChanged<WorkHeroTitleTier> on_tier_changed;
  bool _report_scheduled = false;

  @override
  void performLayout() {
    super.performLayout();
    // 内联部件是孙级RenderBox，不能在祖先的performLayout中直接读取其size。
    // 等整帧布局完成后统一读取，Obx只重建标题时也会由布局变更触发此观察器。
    if (_report_scheduled) return;
    _report_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _report_scheduled = false;
      if (attached) _measure_and_report();
    });
  }

  void _measure_and_report() {
    final paragraph = _find_paragraph(child);
    if (paragraph == null || !paragraph.hasSize) return;
    final current_font_size =
        _first_text_font_size(paragraph.text, kDefaultFontSize) ??
        regular_style.fontSize ??
        kDefaultFontSize;
    final tier =
        _fits(
          paragraph,
          regular_style,
          current_font_size,
          WorkIntroductionHeroStyle.regular_title_lines,
        )
        ? WorkHeroTitleTier.regular
        : _fits(
            paragraph,
            reduced_style,
            current_font_size,
            WorkIntroductionHeroStyle.reduced_title_lines,
          )
        ? WorkHeroTitleTier.reduced
        : WorkHeroTitleTier.extended;
    on_tier_changed(tier);
  }

  RenderParagraph? _find_paragraph(RenderObject? object) {
    if (object is RenderParagraph) return object;
    RenderParagraph? result;
    object?.visitChildren((child) {
      result ??= _find_paragraph(child);
    });
    return result;
  }

  /// Text.rich的外层样式可能仍是正文14sp，实际标题字号位于非空子TextSpan。
  double? _first_text_font_size(InlineSpan span, double inherited_size) {
    final size = span.style?.fontSize ?? inherited_size;
    if (span is TextSpan && span.text?.isNotEmpty == true) return size;
    double? result;
    span.visitDirectChildren((child) {
      result ??= _first_text_font_size(child, size);
      return result == null;
    });
    return result;
  }

  bool _fits(
    RenderParagraph paragraph,
    TextStyle candidate_style,
    double current_font_size,
    int max_lines,
  ) {
    final candidate_font_size = candidate_style.fontSize ?? current_font_size;
    final ratio = current_font_size > 0
        ? candidate_font_size / current_font_size
        : 1.0;
    final placeholder_scale_ratios = <double>[];
    final candidate_span = _copy_span(
      paragraph.text,
      ratio,
      paragraph.textScaler,
      kDefaultFontSize,
      placeholder_scale_ratios,
    );
    final placeholders = <PlaceholderDimensions>[];
    var placeholder_index = 0;
    for (
      RenderBox? inline_child = paragraph.firstChild;
      inline_child != null;
      inline_child = paragraph.childAfter(inline_child)
    ) {
      final data = inline_child.parentData! as TextParentData;
      final span = data.span;
      final scale_ratio = placeholder_index < placeholder_scale_ratios.length
          ? placeholder_scale_ratios[placeholder_index]
          : 1.0;
      placeholder_index++;
      if (span == null) {
        placeholders.add(PlaceholderDimensions.empty);
        continue;
      }
      final baseline_offset = span.alignment == PlaceholderAlignment.baseline
          ? inline_child.getDistanceToBaseline(span.baseline!, onlyReal: true)
          : null;
      placeholders.add(
        PlaceholderDimensions(
          size: inline_child.size * scale_ratio,
          alignment: span.alignment,
          baseline: span.baseline,
          baselineOffset: baseline_offset == null
              ? null
              : baseline_offset * scale_ratio,
        ),
      );
    }
    final width = paragraph.constraints.maxWidth.isFinite
        ? paragraph.constraints.maxWidth
        : paragraph.size.width;
    final painter =
        TextPainter(
            text: candidate_span,
            textAlign: paragraph.textAlign,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
            locale: paragraph.locale,
            strutStyle: paragraph.strutStyle,
            textWidthBasis: paragraph.textWidthBasis,
            textHeightBehavior: paragraph.textHeightBehavior,
            maxLines: max_lines,
          )
          ..setPlaceholderDimensions(placeholders)
          ..layout(maxWidth: math.max(0, width));
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  /// 同一帧同时测原字号和小字号，避免用已经缩小的标题反推而来回切换档位。
  /// 内联部件保留真实业务尺寸，仅同步Flutter对WidgetSpan的系统缩放比例。
  InlineSpan _copy_span(
    InlineSpan span,
    double ratio,
    TextScaler scaler,
    double inherited_size,
    List<double> placeholder_scale_ratios,
  ) {
    final original_size = span.style?.fontSize ?? inherited_size;
    final style = span.style;
    final candidate_style = style?.copyWith(
      fontSize: style.fontSize == null ? null : style.fontSize! * ratio,
    );
    if (span is WidgetSpan) {
      final old_scale = original_size > 0
          ? scaler.scale(original_size) / original_size
          : 1.0;
      final new_size = original_size * ratio;
      final new_scale = new_size > 0 ? scaler.scale(new_size) / new_size : 1.0;
      placeholder_scale_ratios.add(old_scale > 0 ? new_scale / old_scale : 1.0);
      return WidgetSpan(
        child: span.child,
        alignment: span.alignment,
        baseline: span.baseline,
        style: candidate_style,
      );
    }
    if (span is TextSpan) {
      return TextSpan(
        text: span.text,
        style: candidate_style,
        children: span.children
            ?.map(
              (child) => _copy_span(
                child,
                ratio,
                scaler,
                original_size,
                placeholder_scale_ratios,
              ),
            )
            .toList(),
        locale: span.locale,
      );
    }
    return span;
  }
}
