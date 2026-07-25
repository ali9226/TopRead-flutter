import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

class Carousel extends StatefulWidget {
  final List<Widget> children;
  final double? width;
  final double? height;
  final double borderRadius;
  final Duration autoPlayInterval;

  const Carousel({
    super.key,
    required this.children,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.autoPlayInterval = const Duration(seconds: 4),
  });

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  /// 用大页码中间值作为初始页，模拟左右都可无限滑动。
  static const int _initial_page_base = 10000;

  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _resolveInitialPage();
    _pageController = PageController(
      viewportFraction: 1,
      initialPage: _currentPage,
    );
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _currentIndex = 0;
      _currentPage = _resolveInitialPage();
      _pageController.jumpToPage(_currentPage);
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.children.length <= 1) return;

    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final int nextPage = _currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// 计算无限轮播的初始页码。
  ///
  /// 通过把大页码对齐到真实 child 数量的倍数，
  /// 保证初始显示的仍然是第 0 个元素。
  int _resolveInitialPage() {
    if (widget.children.isEmpty) {
      return 0;
    }
    return _initial_page_base - (_initial_page_base % widget.children.length);
  }

  void _restartAutoPlay() {
    _timer?.cancel();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? 200;

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _timer?.cancel();
                } else if (notification is ScrollEndNotification) {
                  _restartAutoPlay();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.children.length > 1
                    ? null
                    : widget.children.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _currentIndex = index % widget.children.length;
                  });
                },
                itemBuilder: (context, index) {
                  final int actualIndex = index % widget.children.length;
                  return RepaintBoundary(
                    child: SizedBox.expand(child: widget.children[actualIndex]),
                  );
                },
              ),
            ),
          ),
          if (widget.children.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.children.length, (index) {
                  final active = index == _currentIndex;
                  final themeColor = ColorConstants.themeColor;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? themeColor
                          : themeColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
