import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/pages/home/widgets/home_tab_bar/index.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/index.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/index.dart';
import 'package:app/pages/home/widgets/tab_contents/default_tab/index.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/models/home_classification.dart';

/// 首页 Tab 内容容器。
class HomeTabs extends StatelessWidget {
  final TabController tab_controller;

  const HomeTabs({super.key, required this.tab_controller});

  @override
  Widget build(BuildContext context) {
    final List<String> titles = get_titles();
    final List<HomeClassification> classification_list =
        _get_classification_list();

    return TabBarView(
      controller: tab_controller,
      physics: const BouncingScrollPhysics(),
      children: List<Widget>.generate(titles.length, (int index) {
        final int classification_id = index < classification_list.length
            ? classification_list[index].id
            : _get_default_id_by_index(index);

        if (classification_id == 143) {
          return const RecommendTabContent(key: ValueKey('recommend_tab'));
        }
        if (classification_id == 145) {
          return const ShortStoryTabContent(key: ValueKey('short_story_tab'));
        }
        final String classification_scope = classification_id > 0
            ? '$classification_id'
            : 'fallback_$index';
        return DefaultTabContent(
          key: ValueKey('default_tab_$classification_scope'),
          title: titles[index],
          waterfall_id: 'home_classification_$classification_scope',
        );
      }),
    );
  }

  List<HomeClassification> _get_classification_list() {
    try {
      return Get.find<HomeBannerStore>().home_classification_list;
    } catch (_) {}
    return const [];
  }

  int _get_default_id_by_index(int index) {
    if (index == 0) return 143;
    if (index == 5) return 145;
    return 0;
  }
}
