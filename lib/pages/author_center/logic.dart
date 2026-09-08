import 'package:app/api/creator_work.dart';
import 'package:app/api/creator_chapter.dart';
import 'package:app/api/creator_asset.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/models/preference.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/util/log_util.dart';
import 'package:get/get.dart';

/// 创作者中心业务逻辑处理
class CreatorLogic {
  /// 获取Dashboard统计数据
  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      logUtil(msg: '========== Dashboard请求开始 ==========', type: 'i');
      logUtil(msg: '请求地址: creator_work/dashboard', type: 'i');
      logUtil(msg: '请求参数: {}', type: 'i');

      final result = await CreatorWorkApi.dashboard();

      logUtil(msg: '响应状态: ${result.status}', type: 'i');
      logUtil(msg: '响应消息: ${result.message}', type: 'i');
      logUtil(msg: '响应数据: ${result.content}', type: 'i');
      logUtil(msg: '========== Dashboard请求结束 ==========', type: 'i');

      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '获取Dashboard失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '获取Dashboard异常: $e', type: 'e');
      return null;
    }
  }

  /// 获取创作配置
  static Future<Map<String, dynamic>?> getFormConfig() async {
    try {
      final result = await CreatorWorkApi.getFormConfig();
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '获取创作配置失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '获取创作配置异常: $e', type: 'e');
      return null;
    }
  }

  /// 创建作品草稿
  static Future<Map<String, dynamic>?> createDraft({
    required int workType,
    required int languageId,
    String? title,
    String? subtitle,
    String? introduction,
  }) async {
    try {
      final result = await CreatorWorkApi.createDraft(
        workType: workType,
        languageId: languageId,
        title: title,
        subtitle: subtitle,
        introduction: introduction,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '创建作品草稿失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '创建作品草稿异常: $e', type: 'e');
      return null;
    }
  }

  /// 查询我的作品列表
  static Future<Map<String, dynamic>?> getMyWorks({
    int? workType,
    int? publicStatus,
    int? initialAuditStatus,
    int? serializationStatus,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await CreatorWorkApi.inquire(
        workType: workType,
        publicStatus: publicStatus,
        initialAuditStatus: initialAuditStatus,
        serializationStatus: serializationStatus,
        keyword: keyword,
        page: page,
        pageSize: pageSize,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '查询作品列表失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '查询作品列表异常: $e', type: 'e');
      return null;
    }
  }

  /// 获取草稿列表
  static Future<Map<String, dynamic>?> getDraftList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await CreatorWorkApi.getDraftList(
        page: page,
        pageSize: pageSize,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '获取草稿列表失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '获取草稿列表异常: $e', type: 'e');
      return null;
    }
  }

  /// 获取作品详情
  static Future<Map<String, dynamic>?> getWorkInfo(int novelId) async {
    try {
      final result = await CreatorWorkApi.getInfo(novelId: novelId);
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '获取作品详情失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '获取作品详情异常: $e', type: 'e');
      return null;
    }
  }

  /// 保存作品资料草稿
  static Future<Map<String, dynamic>?> saveWorkDraft({
    required int novelId,
    required int revisionId,
    String? title,
    String? subtitle,
    String? introduction,
    String? coverUrl,
    int? coverWidth,
    int? coverHeight,
    String? contentUrl,
    int? wordCount,
    int? serializationStatus,
    List<Map<String, dynamic>>? categorySnapshot,
    int? lockVersion,
  }) async {
    try {
      final result = await CreatorWorkApi.saveDraft(
        novelId: novelId,
        revisionId: revisionId,
        title: title,
        subtitle: subtitle,
        introduction: introduction,
        coverUrl: coverUrl,
        coverWidth: coverWidth,
        coverHeight: coverHeight,
        contentUrl: contentUrl,
        wordCount: wordCount,
        serializationStatus: serializationStatus,
        categorySnapshot: categorySnapshot,
        lockVersion: lockVersion,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '保存作品草稿失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '保存作品草稿异常: $e', type: 'e');
      return null;
    }
  }

  /// 提交作品审核
  static Future<Map<String, dynamic>?> submitWork({
    required int novelId,
    required int revisionId,
    required int submissionType,
    String? submitNote,
  }) async {
    try {
      final result = await CreatorWorkApi.submit(
        novelId: novelId,
        revisionId: revisionId,
        submissionType: submissionType,
        submitNote: submitNote,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '提交审核失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '提交审核异常: $e', type: 'e');
      return null;
    }
  }

  /// 查询章节列表
  static Future<List<CreatorChapterModel>> getChapters(int novelId) async {
    try {
      final result = await CreatorChapterApi.inquire(novelId: novelId);
      if (result.status && result.content != null) {
        final list = result.content!['list'] as List? ?? [];
        return list.map((item) => CreatorChapterModel.fromJson(item)).toList();
      }
      logUtil(msg: '查询章节列表失败: ${result.message}', type: 'e');
      return [];
    } catch (e) {
      logUtil(msg: '查询章节列表异常: $e', type: 'e');
      return [];
    }
  }

  /// 创建章节草稿
  static Future<Map<String, dynamic>?> createChapterDraft({
    required int novelId,
    required int novelLanguageId,
    required String title,
  }) async {
    try {
      final result = await CreatorChapterApi.createDraft(
        novelId: novelId,
        novelLanguageId: novelLanguageId,
        title: title,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '创建章节草稿失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '创建章节草稿异常: $e', type: 'e');
      return null;
    }
  }

  /// 保存章节草稿
  static Future<Map<String, dynamic>?> saveChapterDraft({
    required int revisionId,
    String? title,
    String? contentUrl,
    int? wordCount,
    int? lockVersion,
  }) async {
    try {
      final result = await CreatorChapterApi.saveDraft(
        revisionId: revisionId,
        title: title,
        contentUrl: contentUrl,
        wordCount: wordCount,
        lockVersion: lockVersion,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '保存章节草稿失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '保存章节草稿异常: $e', type: 'e');
      return null;
    }
  }

  /// 提交章节审核
  static Future<Map<String, dynamic>?> submitChapters({
    required int novelId,
    required List<int> chapterRevisionIds,
    String? submitNote,
  }) async {
    try {
      final result = await CreatorChapterApi.submit(
        novelId: novelId,
        chapterRevisionIds: chapterRevisionIds,
        submitNote: submitNote,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '提交章节审核失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '提交章节审核异常: $e', type: 'e');
      return null;
    }
  }

  /// 删除章节草稿
  static Future<bool> deleteChapterDraft(int revisionId) async {
    try {
      final result = await CreatorChapterApi.deleteDraft(revisionId: revisionId);
      if (result.status) {
        return true;
      }
      logUtil(msg: '删除章节草稿失败: ${result.message}', type: 'e');
      return false;
    } catch (e) {
      logUtil(msg: '删除章节草稿异常: $e', type: 'e');
      return false;
    }
  }

  /// 准备上传资源
  static Future<Map<String, dynamic>?> prepareUpload({
    required int assetType,
    int? novelId,
    String? chapterUid,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
  }) async {
    try {
      final result = await CreatorAssetApi.prepareUpload(
        assetType: assetType,
        novelId: novelId,
        chapterUid: chapterUid,
        mimeType: mimeType,
        fileSize: fileSize,
        width: width,
        height: height,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '准备上传失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '准备上传异常: $e', type: 'e');
      return null;
    }
  }

  /// 完成上传
  static Future<Map<String, dynamic>?> completeUpload({
    required int assetId,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    String? sha256,
  }) async {
    try {
      final result = await CreatorAssetApi.completeUpload(
        assetId: assetId,
        mimeType: mimeType,
        fileSize: fileSize,
        width: width,
        height: height,
        sha256: sha256,
      );
      if (result.status && result.content != null) {
        return result.content;
      }
      logUtil(msg: '完成上传失败: ${result.message}', type: 'e');
      return null;
    } catch (e) {
      logUtil(msg: '完成上传异常: $e', type: 'e');
      return null;
    }
  }

  /// TODO 作者投稿可选分类所在的分组 id。
  ///
  /// 对应 `novel_preference_type` 中 label 为「内容偏好」的分组，
  /// 该分组的 creator_min_select / creator_max_select 为 1 / 5。
  static const int category_type_id = 2;

  /// TODO 读取作者可选的分类选项。
  ///
  /// 数据来自全局 [PreferenceStore]，由 `redis/get` 统一缓存，
  /// 页面不需要单独请求网络。偏好数据尚未就绪时返回空列表。
  static List<PreferenceItem> get category_options {
    final Preference? preference = Get.find<PreferenceStore>()
        .find_preference_by_id(category_type_id);
    return preference?.data_list ?? const <PreferenceItem>[];
  }

  /// TODO 按选项 id 反查分类名称。
  ///
  /// 找不到时返回空字符串，避免在未加载偏好数据时抛出越界。
  static String category_name(int id) {
    for (final PreferenceItem item in category_options) {
      if (item.id == id) return item.title;
    }
    return '';
  }
}
