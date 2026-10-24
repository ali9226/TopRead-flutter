// ignore_for_file: non_constant_identifier_names

part of 'index.dart';

/// TODO 固定卡宽按索引定位，只在阅读目标或可用宽度改变时自动定位。
mixin _ComicChapterPreviewLogic on State<ComicChapterPreview> {
  late final ScrollController scroll_controller = ScrollController(
    keepScrollOffset: false,
  )..addListener(_sync_current_visibility);

  int _current_index = -1;
  int _position_revision = 0;
  int? _scheduled_revision;
  bool _needs_positioning = true;
  bool _is_positioning = false;
  bool show_location_button = false;
  double _viewport_width = 0;
  double _card_width = 0;
  double _horizontal_padding = 0;

  @override
  void initState() {
    super.initState();
    _current_index = _resolve_current_index();
  }

  @override
  void didUpdateWidget(covariant ComicChapterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current_index = _resolve_current_index();
    if (oldWidget.current_chapter_id != widget.current_chapter_id ||
        current_index != _current_index) {
      _current_index = current_index;
      _invalidate_position();
      show_location_button = false;
    }
  }

  int _resolve_current_index() => widget.current_chapter_id == null
      ? -1
      : widget.chapters.indexWhere(
          (chapter) => chapter.id == widget.current_chapter_id,
        );

  void _invalidate_position() {
    _position_revision++;
    _needs_positioning = true;
    _is_positioning = false;
  }

  /// TODO 只记录真实布局变化；同一窗口下的主题、数据或父级重建保留手动滚动位置。
  void update_rail_layout({
    required double viewport_width,
    required double card_width,
  }) {
    if (_viewport_width != viewport_width ||
        _card_width != card_width ||
        _horizontal_padding != widget.horizontal_padding) {
      _viewport_width = viewport_width;
      _card_width = card_width;
      _horizontal_padding = widget.horizontal_padding;
      // TODO 顶栏已在外层构建，保留当前显隐值，待定位后通过 setState 同步新布局。
      _invalidate_position();
    }
    if (!_needs_positioning || _scheduled_revision == _position_revision) {
      return;
    }
    final revision = _position_revision;
    _scheduled_revision = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _position_revision) return;
      _scheduled_revision = null;
      if (_current_index < 0) {
        _needs_positioning = false;
        return;
      }
      if (!scroll_controller.hasClients ||
          !scroll_controller.position.hasContentDimensions) {
        return;
      }
      _needs_positioning = false;
      scroll_controller.jumpTo(_current_offset());
      _sync_current_visibility();
    });
  }

  double _current_offset() {
    final position = scroll_controller.position;
    return (_current_index * (_card_width + ComicChapterPreviewStyle.gap))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }

  bool _current_is_visible() {
    if (_current_index < 0 ||
        !scroll_controller.hasClients ||
        !scroll_controller.position.hasContentDimensions) {
      return true;
    }
    final position = scroll_controller.position;
    final left =
        _horizontal_padding +
        _current_index * (_card_width + ComicChapterPreviewStyle.gap);
    final right = left + _card_width;
    return left >=
            position.pixels +
                _horizontal_padding -
                ComicChapterPreviewStyle.visibility_tolerance &&
        right <=
            position.pixels +
                position.viewportDimension -
                _horizontal_padding +
                ComicChapterPreviewStyle.visibility_tolerance;
  }

  void _sync_current_visibility() {
    if (!mounted) return;
    final show =
        !_needs_positioning && !_is_positioning && !_current_is_visible();
    if (show_location_button != show) {
      setState(() => show_location_button = show);
    }
  }

  /// TODO 动画完成后只同步同一阅读目标；新进度、窗口重排或卸载使旧回调失效。
  Future<void> scroll_to_current() async {
    if (_current_index < 0 || !scroll_controller.hasClients) return;
    final revision = ++_position_revision;
    _needs_positioning = false;
    setState(() {
      _is_positioning = true;
      show_location_button = false;
    });
    final target = _current_offset();
    if (MediaQuery.disableAnimationsOf(context)) {
      scroll_controller.jumpTo(target);
    } else {
      await scroll_controller.animateTo(
        target,
        duration: ComicChapterPreviewStyle.position_duration,
        curve: ComicChapterPreviewStyle.position_curve,
      );
    }
    if (!mounted || revision != _position_revision) return;
    _is_positioning = false;
    _sync_current_visibility();
  }

  @override
  void dispose() {
    _position_revision++;
    scroll_controller.dispose();
    super.dispose();
  }
}
