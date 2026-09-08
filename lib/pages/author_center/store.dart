import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/util/log_util.dart';
import 'package:get/get.dart';

/// 创作者中心状态管理
class CreatorStore extends GetxController {
  /// 作品列表
  final works = <CreatorWorkModel>[].obs;

  /// 章节列表
  final chapters = <CreatorChapterModel>[].obs;

  /// 当前选中的作品
  final currentWork = Rxn<CreatorWorkModel>();

  /// 创作配置
  final formConfig = Rxn<Map<String, dynamic>>();

  /// Dashboard统计数据
  final dashboardData = Rxn<Map<String, dynamic>>();

  /// 加载状态
  final isLoading = false.obs;

  /// 作品列表加载状态
  final isWorksLoading = false.obs;

  /// 章节列表加载状态
  final isChaptersLoading = false.obs;

  /// 当前页码
  final currentPage = 1.obs;

  /// 总页数
  final totalPages = 1.obs;

  /// 筛选条件
  final filterWorkType = Rxn<int>();
  final filterPublicStatus = Rxn<int>();
  final filterAuditStatus = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    loadFormConfig();
    loadWorks();
  }

  /// 加载Dashboard统计数据
  Future<void> loadDashboard() async {
    try {
      final result = await CreatorLogic.getDashboard();
      if (result != null) {
        dashboardData.value = result;
      }
    } catch (e) {
      logUtil(msg: '加载Dashboard失败: $e', type: 'e');
    }
  }

  /// 加载创作配置
  Future<void> loadFormConfig() async {
    try {
      final config = await CreatorLogic.getFormConfig();
      if (config != null) {
        formConfig.value = config;
      }
    } catch (e) {
      logUtil(msg: '加载创作配置失败: $e', type: 'e');
    }
  }

  /// 加载作品列表
  Future<void> loadWorks({bool refresh = false}) async {
    if (isWorksLoading.value) return;

    try {
      isWorksLoading.value = true;

      if (refresh) {
        currentPage.value = 1;
      }

      final result = await CreatorLogic.getMyWorks(
        workType: filterWorkType.value,
        publicStatus: filterPublicStatus.value,
        initialAuditStatus: filterAuditStatus.value,
        page: currentPage.value,
      );

      if (result != null) {
        final list = result['list'] as List? ?? [];
        final newWorks = list.map((item) => CreatorWorkModel.fromJson(item)).toList();

        if (refresh || currentPage.value == 1) {
          works.value = newWorks;
        } else {
          works.addAll(newWorks);
        }

        final total = result['total'] as int? ?? 0;
        totalPages.value = (total / 20).ceil();
      }
    } catch (e) {
      logUtil(msg: '加载作品列表失败: $e', type: 'e');
    } finally {
      isWorksLoading.value = false;
    }
  }

  /// 加载更多作品
  Future<void> loadMoreWorks() async {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      await loadWorks();
    }
  }

  /// 刷新作品列表
  Future<void> refreshWorks() async {
    await loadWorks(refresh: true);
  }

  /// 设置筛选条件
  void setFilter({
    int? workType,
    int? publicStatus,
    int? auditStatus,
  }) {
    filterWorkType.value = workType;
    filterPublicStatus.value = publicStatus;
    filterAuditStatus.value = auditStatus;
    loadWorks(refresh: true);
  }

  /// 清除筛选条件
  void clearFilter() {
    filterWorkType.value = null;
    filterPublicStatus.value = null;
    filterAuditStatus.value = null;
    loadWorks(refresh: true);
  }

  /// 选择作品
  void selectWork(CreatorWorkModel work) {
    currentWork.value = work;
    loadChapters(work.id);
  }

  /// 加载章节列表
  Future<void> loadChapters(int novelId) async {
    if (isChaptersLoading.value) return;

    try {
      isChaptersLoading.value = true;
      final result = await CreatorLogic.getChapters(novelId);
      chapters.value = result;
    } catch (e) {
      logUtil(msg: '加载章节列表失败: $e', type: 'e');
    } finally {
      isChaptersLoading.value = false;
    }
  }

  /// 创建新作品
  Future<CreatorWorkModel?> createWork({
    required int workType,
    required int languageId,
    String? title,
    String? subtitle,
    String? introduction,
  }) async {
    try {
      isLoading.value = true;

      final result = await CreatorLogic.createDraft(
        workType: workType,
        languageId: languageId,
        title: title,
        subtitle: subtitle,
        introduction: introduction,
      );

      if (result != null) {
        // 重新加载作品列表
        await refreshWorks();

        // 返回新创建的作品（从列表中查找）
        final novelId = result['novel_id'] as int?;
        if (novelId != null) {
          return works.firstWhereOrNull((w) => w.id == novelId);
        }
      }

      return null;
    } catch (e) {
      logUtil(msg: '创建作品失败: $e', type: 'e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 保存作品草稿
  Future<bool> saveWorkDraft({
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
      final result = await CreatorLogic.saveWorkDraft(
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

      if (result != null) {
        // 刷新作品列表
        await refreshWorks();
        return true;
      }

      return false;
    } catch (e) {
      logUtil(msg: '保存作品草稿失败: $e', type: 'e');
      return false;
    }
  }

  /// 提交作品审核
  Future<bool> submitWork({
    required int novelId,
    required int revisionId,
    required int submissionType,
    String? submitNote,
  }) async {
    try {
      isLoading.value = true;

      final result = await CreatorLogic.submitWork(
        novelId: novelId,
        revisionId: revisionId,
        submissionType: submissionType,
        submitNote: submitNote,
      );

      if (result != null) {
        // 刷新作品列表
        await refreshWorks();
        return true;
      }

      return false;
    } catch (e) {
      logUtil(msg: '提交审核失败: $e', type: 'e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 创建新章节
  Future<CreatorChapterModel?> createChapter({
    required int novelId,
    required int novelLanguageId,
    required String title,
  }) async {
    try {
      final result = await CreatorLogic.createChapterDraft(
        novelId: novelId,
        novelLanguageId: novelLanguageId,
        title: title,
      );

      if (result != null) {
        // 重新加载章节列表
        await loadChapters(novelId);

        // 返回新创建的章节
        final revisionId = result['revision_id'] as int?;
        if (revisionId != null) {
          return chapters.firstWhereOrNull((c) => c.id == revisionId);
        }
      }

      return null;
    } catch (e) {
      logUtil(msg: '创建章节失败: $e', type: 'e');
      return null;
    }
  }

  /// 保存章节草稿
  Future<bool> saveChapterDraft({
    required int revisionId,
    String? title,
    String? contentUrl,
    int? wordCount,
    int? lockVersion,
  }) async {
    try {
      final result = await CreatorLogic.saveChapterDraft(
        revisionId: revisionId,
        title: title,
        contentUrl: contentUrl,
        wordCount: wordCount,
        lockVersion: lockVersion,
      );

      if (result != null) {
        // 刷新章节列表
        if (currentWork.value != null) {
          await loadChapters(currentWork.value!.id);
        }
        return true;
      }

      return false;
    } catch (e) {
      logUtil(msg: '保存章节草稿失败: $e', type: 'e');
      return false;
    }
  }

  /// 提交章节审核
  Future<bool> submitChapters({
    required int novelId,
    required List<int> chapterRevisionIds,
    String? submitNote,
  }) async {
    try {
      isLoading.value = true;

      final result = await CreatorLogic.submitChapters(
        novelId: novelId,
        chapterRevisionIds: chapterRevisionIds,
        submitNote: submitNote,
      );

      if (result != null) {
        // 刷新章节列表
        await loadChapters(novelId);
        // 刷新作品列表
        await refreshWorks();
        return true;
      }

      return false;
    } catch (e) {
      logUtil(msg: '提交章节审核失败: $e', type: 'e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除章节草稿
  Future<bool> deleteChapterDraft(int revisionId) async {
    try {
      final success = await CreatorLogic.deleteChapterDraft(revisionId);

      if (success) {
        // 刷新章节列表
        if (currentWork.value != null) {
          await loadChapters(currentWork.value!.id);
        }
        return true;
      }

      return false;
    } catch (e) {
      logUtil(msg: '删除章节草稿失败: $e', type: 'e');
      return false;
    }
  }

  /// 获取筛选后的作品数量
  int get worksCount => works.length;

  /// 获取草稿数量
  int get draftCount => works.where((w) => w.is_draft).length;

  /// 获取审核中数量
  int get reviewingCount => works.where((w) => w.is_reviewing).length;

  /// 获取已驳回数量
  int get rejectedCount => works.where((w) => w.is_rejected).length;

  /// 获取已发布数量
  int get publishedCount => works.where((w) => w.is_published).length;
}
