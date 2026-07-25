import 'package:dio/dio.dart';
import 'package:app/util/log_util.dart';

/// 获取章节正文内容。
///
/// [url] 章节正文內容的连接。
/// 返回章节的文本内容，如果获取失败则返回空字符串。
Future<String> get_chapter_content(String url) async {
  if (url.isEmpty) {
    return '';
  }

  try {
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final Response<String> response = await dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    } else {
      logUtil(
        msg: 'get_chapter_content 失败: statusCode=${response.statusCode}, url=$url',
        type: 'w',
      );
      return '';
    }
  } catch (error) {
    logUtil(
      msg: 'get_chapter_content 捕获异常: url=$url, error=$error',
      type: 'e',
    );
    return '';
  }
}
