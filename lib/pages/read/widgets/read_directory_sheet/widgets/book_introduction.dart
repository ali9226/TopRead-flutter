import 'package:flutter/material.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/intro_summary_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/intro_summary_section/style.dart';

/// 目录弹窗详情 Tab 内容组件。
class BookIntroduction extends StatelessWidget {
  /// 书籍详情数据。
  final ReadDetail detail;

  /// 是否为夜间模式。
  final bool is_dark;

  const BookIntroduction({
    super.key,
    required this.detail,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计子组件，展示评分、在读人数、字数三个指标。
          ReadStatSection(is_dark: is_dark, detail: detail),
          const SizedBox(height: 24),
          // 标签子组件，展示小说标签列表。
          ReadTagSection(is_dark: is_dark, tag_list: detail.tag_list),
          const SizedBox(height: 24),
          // 简介子组件，字号+2px，默认展开。
          ReadIntroSummarySection(
            is_dark: is_dark,
            intro_text: detail.intro_text,
            initial_expanded: true,
            font_size: IntroSummaryStyle.intro_font_size + 2,
          ),
          const SizedBox(height: 40), // 底部留白
        ],
      ),
    );
  }
}
