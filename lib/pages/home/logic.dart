import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/story_item.dart';

/// 首页逻辑层。
///
/// 负责管理首页榜单列表、书籍列表和下拉刷新状态。
class Logic {
  /// 当前页面上下文。
  final BuildContext context;

  /// 首页初始小说列表。
  final List<StoryItem> seed_story_item_list = const <StoryItem>[
    StoryItem(
      id: 1001,
      title: '夜潮回声：旧港口最后一班渡船消失后的七天追凶',
      popularity_count: '48',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780141439518-M.jpg',
    ),
    StoryItem(
      id: 1002,
      title: '云端来信：那封跨越十二年的未读邮件终于在雨夜弹出提醒',
      popularity_count: '45',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780141441146-M.jpg',
    ),
    StoryItem(
      id: 1003,
      title: '归舟记：他从江湖归来时朝堂棋局已经悄然落下第一子',
      popularity_count: '43',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780141439556-M.jpg',
    ),
    StoryItem(
      id: 1004,
      title: '长夜与星火：废土尽头的最后一座灯塔仍在等待失踪舰队返航',
      popularity_count: '40',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780743273565-M.jpg',
    ),
    StoryItem(
      id: 1005,
      title: '旧城迷雾录：每一条消失的街巷都在深夜重新指向案发现场',
      popularity_count: '38',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780142437247-M.jpg',
    ),
    StoryItem(
      id: 1006,
      title: '月光坠入深海时',
      popularity_count: '35',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780147514011-M.jpg',
    ),
    StoryItem(
      id: 1007,
      title: '风起青梧巷：她在长安最冷的雪夜里捡到一封改变朝局的密信',
      popularity_count: '31',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780141439846-M.jpg',
    ),
    StoryItem(
      id: 1008,
      title: '失落王座手记',
      popularity_count: '28',
      cover_url: 'https://covers.openlibrary.org/b/isbn/9780141034324-M.jpg',
    ),
  ];

  /// 当前已经渲染在首页榜单中的小说列表。
  final RxList<StoryItem> story_item_list = <StoryItem>[].obs;

  /// 当前首页榜单是否处于网络加载中。
  final RxBool is_ranking_loading = true.obs;

  /// 当前已经渲染在首页书籍列表中的小说数据。
  final RxList<BookListItem> book_list = <BookListItem>[].obs;

  /// 当前书籍列表是否处于首屏加载中。
  final RxBool is_book_list_initial_loading = true.obs;

  /// 当前书籍列表是否正在执行加载更多。
  final RxBool is_book_list_loading_more = false.obs;

  /// 当前书籍列表是否仍然存在更多数据。
  final RxBool has_more_book_list = true.obs;

  /// 首页榜单模拟网络请求耗时。
  static const int ranking_mock_request_duration_ms = 1000;

  /// 首页书籍列表单次加载数量。
  static const int book_list_page_size = 8;

  /// 首页书籍列表最大页数。
  static const int max_book_list_page = 4;

  /// 触发自动加载更多的底部预加载距离。
  static const double load_more_trigger_offset = 260;

  /// 当前书籍列表已经加载到的页码。
  int current_book_list_page = 0;

  Logic(this.context);

  /// 初始化首页列表数据。
  void initialize() {
    if (story_item_list.isEmpty || is_ranking_loading.isTrue) {
      load_home_content();
    }

    if (book_list.isEmpty) {
      load_initial_book_list();
    }
  }

  /// 加载首页榜单内容。
  ///
  /// 这里先保留模拟请求过程，
  /// 这样后面替换成真实接口时只需要把延迟替换成请求调用即可。
  Future<void> load_home_content({bool reverse_list = false}) async {
    is_ranking_loading.value = true;

    await Future<void>.delayed(
      const Duration(milliseconds: ranking_mock_request_duration_ms),
    );

    story_item_list.assignAll(
      reverse_list
          ? seed_story_item_list.reversed.toList()
          : seed_story_item_list,
    );

    is_ranking_loading.value = false;
  }

  /// 执行首页下拉刷新。
  ///
  /// 这里先模拟一次短暂请求，并重置首页榜单顺序，
  /// 让刷新动画结束后页面内容也有明确反馈。
  Future<void> refresh_home_content() async {
    await Future.wait(<Future<void>>[
      load_home_content(reverse_list: true),
      refresh_book_list(),
    ]);
  }

  /// 加载首页书籍列表首屏数据。
  ///
  /// 该方法会重置页码、重置“是否还有更多”状态，
  /// 然后重新生成一批用于展示的假数据。
  Future<void> load_initial_book_list() async {
    current_book_list_page = 1;
    is_book_list_initial_loading.value = true;
    is_book_list_loading_more.value = false;
    has_more_book_list.value = true;

    await Future<void>.delayed(
      const Duration(milliseconds: ranking_mock_request_duration_ms),
    );

    book_list.assignAll(_build_mock_book_list(page: current_book_list_page));
    has_more_book_list.value = current_book_list_page < max_book_list_page;
    is_book_list_initial_loading.value = false;
  }

  /// 刷新首页书籍列表。
  ///
  /// 下拉刷新时直接复用首屏逻辑，
  /// 保持首页所有模块都能拿到新的演示数据。
  Future<void> refresh_book_list() async {
    await load_initial_book_list();
  }

  /// 根据外层滚动位置尝试自动加载更多。
  ///
  /// 因为首页列表放在页面主滚动容器中，
  /// 所以这里直接监听外层 `ScrollController` 的剩余滚动距离。
  Future<void> try_load_more_book_list({
    required ScrollController scroll_controller,
  }) async {
    if (!scroll_controller.hasClients || is_book_list_initial_loading.isTrue) {
      return;
    }

    final double distance_to_bottom =
        scroll_controller.position.maxScrollExtent - scroll_controller.offset;

    if (distance_to_bottom > load_more_trigger_offset) {
      return;
    }

    await load_more_book_list();
  }

  /// 加载更多首页书籍列表数据。
  ///
  /// 当前版本使用假数据模拟分页，
  /// 后续接接口时只需要把数据源替换为真实请求结果。
  Future<void> load_more_book_list() async {
    if (is_book_list_loading_more.value || has_more_book_list.isFalse) {
      return;
    }

    is_book_list_loading_more.value = true;

    await Future<void>.delayed(
      const Duration(milliseconds: ranking_mock_request_duration_ms),
    );

    final int next_page = current_book_list_page + 1;
    final List<BookListItem> next_page_item_list = _build_mock_book_list(
      page: next_page,
    );

    book_list.addAll(next_page_item_list);
    current_book_list_page = next_page;
    has_more_book_list.value = current_book_list_page < max_book_list_page;
    is_book_list_loading_more.value = false;
  }

  /// 构建指定页码的假书籍数据。
  ///
  /// 这里通过若干文案池和封面地址池组合生成卡片内容，
  /// 让首页在未接真实接口前也能完整验证视觉效果和滚动加载行为。
  List<BookListItem> _build_mock_book_list({required int page}) {
    /// 标题候选列表。
    const List<String> title_pool = <String>[
      '夜雨连城，旧案重开之后她在图书馆最深处翻到了那本没有馆藏记录的手稿',
      '从离婚开始重写人生',
      '雪落长安时，少年提剑赴一场迟到了十年的故人之约',
      '她把暗恋写成连载，结果男主角本人每天准时催更',
      '荒海灯塔仍在等待最后一艘返航的船',
      '病房窗边的来信',
      '第七次回到案发当晚，她终于看清了雨幕里撑伞的人',
      '猫咖店长不想拯救世界',
      '将军今天也在躲婚书',
      '凌晨三点的地铁站，只对失眠的人开放第二条时间线',
      '被退婚后我成了全城最会写话本的人',
      '山海尽头有人等你',
    ];

    /// 简介候选列表。
    const List<String> description_pool = <String>[
      '悬疑线和情感线并行推进，节奏很稳，适合一口气读下去。',
      '偏轻松向，人物对话很多，氛围感比较强。',
      '',
      '世界观不复杂，但细节铺垫很密，越读越容易沉进去。',
      '主打高糖与反转并存，适合睡前追更。',
      '短章节快节奏，连续阅读体验会更好。',
      '',
      '一边破案一边自救，人物成长非常明显。',
    ];

    /// 左上角角标候选列表。
    const List<String> badge_pool = <String>[
      '短篇',
      '',
      '完结',
      '',
      '独家',
      '',
      '精选',
      '',
    ];

    /// 封面左下角信息候选列表。
    const List<String> meta_pool = <String>[
      '9.4分',
      '1.8万次播放',
      '8.9分',
      '2.3万人在读',
      '9.1分',
      '6.7万热度',
      '7.8分',
      '3.2万收藏',
    ];

    /// 标签文案候选列表。
    const List<String> tag_label_pool = <String>[
      '悬疑',
      '都市',
      '甜宠',
      '古言',
      '治愈',
      '成长',
      '逆袭',
      '轻松',
      '救赎',
      '群像',
      '推理',
      '幻想',
    ];

    /// 标签颜色候选列表。
    final List<Color> tag_color_pool = <Color>[
      ColorConstants.dangerColor,
      ColorConstants.successColor,
      const Color(0xFF5F8BFF),
      const Color(0xFFFF9F5A),
      const Color(0xFF8B7CFF),
      const Color(0xFF2FBF9B),
    ];

    /// 封面地址候选列表。
    const List<String> cover_url_pool = <String>[
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1476275466078-4007374efbbe?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1513001900722-370f803f498d?auto=format&fit=crop&w=900&q=80',
    ];

    /// 广告图片组候选列表。
    const List<List<String>> ad_image_group_pool = <List<String>>[
      <String>[
        'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=900&q=80',
      ],
      <String>[
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=900&q=80',
      ],
      <String>[
        'https://images.unsplash.com/photo-1476275466078-4007374efbbe?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1513001900722-370f803f498d?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1516979187457-637abb4f9353?auto=format&fit=crop&w=900&q=80',
      ],
    ];

    /// 当前页生成出的书籍数据列表。
    final List<BookListItem> result = <BookListItem>[];

    for (int index = 0; index < book_list_page_size; index++) {
      /// 当前卡片对应的全局索引。
      final int global_index = (page - 1) * book_list_page_size + index;

      /// 当前卡片的标签数量。
      final int current_tag_count = global_index % 4;

      /// 当前卡片的标签列表。
      final List<BookListTagItem> current_tag_list =
          List<BookListTagItem>.generate(current_tag_count, (int tag_index) {
            final int label_index =
                (global_index + tag_index) % tag_label_pool.length;
            final int color_index =
                (global_index + tag_index) % tag_color_pool.length;

            return BookListTagItem(
              label: tag_label_pool[label_index],
              color: tag_color_pool[color_index],
            );
          });

      /// 当前索引是否插入广告。
      final bool should_insert_ad =
          global_index != 0 && (global_index + page) % 5 == 0;

      if (should_insert_ad) {
        result.add(
          BookListItem(
            id: 'ad_$global_index',
            story_id: 0,
            type: BookListItemType.ad,
            title: '',
            description: '',
            cover_url: '',
            cover_badge: '',
            cover_meta_text: '',
            tag_list: const <BookListTagItem>[],
            ad_image_url_list:
                ad_image_group_pool[global_index % ad_image_group_pool.length],
          ),
        );
        continue;
      }

      result.add(
        BookListItem(
          id: 'book_$global_index',
          story_id: global_index + 1,
          type: BookListItemType.book,
          title: title_pool[global_index % title_pool.length],
          description: description_pool[global_index % description_pool.length],
          cover_url: cover_url_pool[global_index % cover_url_pool.length],
          cover_badge: badge_pool[global_index % badge_pool.length],
          cover_meta_text: meta_pool[global_index % meta_pool.length],
          tag_list: current_tag_list,
          ad_image_url_list: const <String>[],
        ),
      );
    }

    return result;
  }
}
