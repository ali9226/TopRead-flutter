import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/thumbnail_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('超长首图解码遵守像素预算，普通缩略图保持屏幕清晰度', () {
    const long_page = ComicImageData(image_url: '', width: 720, height: 40000);
    final width = comic_thumbnail_cache_width(
      width: 152,
      device_pixel_ratio: 3,
      image: long_page,
    );
    expect(
      width * width * long_page.height / long_page.width,
      lessThanOrEqualTo(ComicsStyle.thumbnail_max_pixels),
    );
    expect(
      comic_thumbnail_cache_width(
        width: 152,
        device_pixel_ratio: 3,
        image: const ComicImageData(image_url: '', width: 720, height: 1080),
      ),
      456,
    );
    expect(
      comic_thumbnail_cache_width(
        width: 152,
        device_pixel_ratio: 3,
        image: const ComicImageData(image_url: '', width: 80, height: 120),
      ),
      80,
    );
    expect(comic_thumbnail_cache_width(width: 152, device_pixel_ratio: 3), 456);
  });
}
