// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 图片流提供原图宽高，长条图无需裁剪或拉伸。关闭页面时释放流监听。
class ComicReaderImage extends StatefulWidget {
  final ComicImageData image;
  final int page_index;
  final double width;
  final ValueChanged<double> on_ratio;
  const ComicReaderImage({
    super.key,
    required this.image,
    required this.page_index,
    required this.width,
    required this.on_ratio,
  });
  @override
  State<ComicReaderImage> createState() => _ComicReaderImageState();
}

class _ComicReaderImageState extends State<ComicReaderImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageProvider? _provider;
  double? _ratio;
  bool _failed = false;
  bool _loaded = false;
  int _image_request = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider == null) _resolve();
  }

  @override
  void didUpdateWidget(covariant ComicReaderImage old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.image.image_url != widget.image.image_url) _resolve();
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  void _resolve() {
    _detach();
    _failed = false;
    _loaded = false;
    _ratio = null;
    _provider = CachedNetworkImageProvider(widget.image.image_url);
    final request_id = ++_image_request;
    _stream = _provider!.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, synchronous_call) {
        final ratio = info.image.width / info.image.height;
        // 同步缓存命中时推迟通知，避免在父组件 build 中调用 setState。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || request_id != _image_request) return;
          setState(() {
            _ratio = ratio;
            _loaded = true;
          });
          widget.on_ratio(ratio);
        });
      },
      onError: (Object error, StackTrace? stack_trace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && request_id == _image_request) {
            setState(() => _failed = true);
          }
        });
      },
    );
    _stream!.addListener(_listener!);
  }

  Future<void> _retry() async {
    await CachedNetworkImage.evictFromCache(widget.image.image_url);
    if (!mounted) return;
    setState(_resolve);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: tr(
      'comics.reader_page',
      namedArgs: <String, String>{'page': '${widget.page_index + 1}'},
    ),
    child: SizedBox(
      width: widget.width,
      height: comic_page_height(
        widget.image,
        widget.width,
        measured_ratio: _ratio,
      ),
      child: _failed
          ? ColoredBox(
              color: ComicsStyle.reader_background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: ComicsStyle.small_gap),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: ColorConstants.themeColor,
                      ),
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('comics.retry_image')),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (!_loaded)
                  const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_provider != null)
                  Image(
                    image: _provider!,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stack_trace) => Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: ColorConstants.themeColor,
                        ),
                        onPressed: _retry,
                        child: Text(tr('comics.retry_image')),
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
