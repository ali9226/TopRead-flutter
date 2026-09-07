import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 创作者资源上传API
class CreatorAssetApi {
  /// 准备上传
  /// 返回上传路径和资源ID
  static Future<ResultsType<Map<String, dynamic>>> prepareUpload({
    required int assetType,
    int? novelId,
    String? chapterUid,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_asset/prepare_upload',
      parameter: {
        'asset_type': assetType,
        if (novelId != null) 'novel_id': novelId,
        if (chapterUid != null) 'chapter_uid': chapterUid,
        if (mimeType != null) 'mime_type': mimeType,
        if (fileSize != null) 'file_size': fileSize,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
      fromJson: (json) => json,
    );
  }

  /// 完成上传
  /// 更新资源记录状态
  static Future<ResultsType<Map<String, dynamic>>> completeUpload({
    required int assetId,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    String? sha256,
  }) {
    return postRequest<Map<String, dynamic>>(
      path: 'creator_asset/complete_upload',
      parameter: {
        'asset_id': assetId,
        if (mimeType != null) 'mime_type': mimeType,
        if (fileSize != null) 'file_size': fileSize,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (sha256 != null) 'sha256': sha256,
      },
      fromJson: (json) => json,
    );
  }
}
