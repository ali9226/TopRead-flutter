import 'package:app/api/post_request.dart';
import 'package:app/models/image_text_detail.dart';
import 'package:app/util/language_util/index.dart';

/// image_text 页面逻辑层。
class Logic {
  const Logic();

  /// 请求 image_text 详情接口。
  ///
  /// [type] 为路由透传的业务类型。
  Future<ImageTextDetail?> fetch_image_text_detail({
    required String type,
  }) async {
    /// 统一通过语言工具获取后端语言 ID，避免后续多处硬编码。
    final int language_id = await LanguageUtil.get_language_id();

    /// 调用详情接口。
    final results = await postRequest<ImageTextDetail>(
      path: 'image_text/detailed',
      parameter: <String, dynamic>{
        'type': type,
        'language': language_id,
      },
      fromJson: (json) => ImageTextDetail.fromJson(json),
    );

    if (!results.status) {
      return null;
    }

    return results.content;
  }
}
