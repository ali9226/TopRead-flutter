// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/config/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';

typedef ComicDetailFetcher =
    Future<ComicDetail> Function(int comic_id, {String? language});
typedef ComicDetailProgressReader =
    Future<Map<String, dynamic>> Function(int comic_id, {int? user_id});

/// 详情状态管理：语种请求、防止旧账号响应串写、即时续读与统一书架收藏刷新。
class ComicDetailLogic extends ComicsController {
  final int comic_id;
  final ComicDetailFetcher _fetch_detail;
  final ComicDetailProgressReader _read_progress;
  final Listenable _progress_changes;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
  _request;
  final Future<void> Function(int?) _favorite_changed;
  final bool Function() _require_login;
  final void Function(String) _navigate;
  Worker? _identity_worker;

  ComicDetailLogic(
    this.comic_id, {
    ComicDetailFetcher? fetch_detail,
    ComicDetailProgressReader? read_progress,
    Listenable? progress_changes,
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
    request,
    Future<void> Function()? favorite_changed,
    bool Function()? require_login,
    void Function(String)? navigate,
  }) : _fetch_detail = fetch_detail ?? comics_detail,
       _read_progress =
           read_progress ?? ComicsProgressService.instance.read_record,
       _progress_changes = progress_changes ?? ComicsProgressService.instance,
       _request = request ?? _session_request,
       _favorite_changed = favorite_changed == null
           ? ((revision) =>
                 BookshelfSyncService.favorite_changed(auth_revision: revision))
           : ((_) => favorite_changed()),
       _require_login = require_login ?? comics_require_login,
       _navigate = navigate ?? ((path) => routerUtil(path: path)) {
    _progress_changes.addListener(_on_progress_changed);
    if (Get.isRegistered<UserInformation>()) {
      final user = Get.find<UserInformation>();
      _identity_worker = everAll(
        <RxInterface>[user.userInfo, user.isLoggedIn],
        (_) {
          if (_loaded_identity != _identity()) {
            local_record = <String, dynamic>{};
            collected = false;
            emit();
            unawaited(load());
          }
        },
      );
    }
  }

  /// 写入携带操作发起时的凭证，读取语言配置或存储期间切换账号会取消旧操作。
  static Future<Map<String, dynamic>> _session_request(
    String action,
    Map<String, dynamic> parameter,
  ) async {
    final user = Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>()
        : null;
    final revision = user?.auth_revision;
    final token = await StorageUtil.getData(Constant.tokenKey);
    if (revision == null ||
        user == null ||
        !user.can_apply_authenticated_response(revision) ||
        token == null ||
        token.isEmpty) {
      throw ComicsRequestException(tr('comics.login_required'));
    }
    return comics_session_request(
      action,
      parameter,
      authorization_token: token,
    );
  }

  ComicDetail? detail;
  bool loading = true;
  bool collecting = false;
  bool collected = false;
  int _request_id = 0;
  int _progress_request_id = 0;
  int _collection_revision = 0;
  String? selected_code;
  String? _loaded_identity;
  Map<String, dynamic> local_record = <String, dynamic>{};

  int _user_id() => ComicsProgressService.current_account_id();
  String _identity() =>
      '${_user_id()}:${Get.isRegistered<UserInformation>() ? Get.find<UserInformation>().auth_identity_revision : 0}';

  /// 外部测试可以直接设置detail；生产响应仅在同一认证身份下参与续读合并。
  ComicResumeRecord? get resume_record {
    final current = detail;
    if (current == null) return null;
    final same_identity =
        _loaded_identity == null || _loaded_identity == _identity();
    return resolve_comic_resume(
      current,
      local_record: same_identity ? local_record : const <String, dynamic>{},
      server_record: same_identity
          ? current.read_record
          : const <String, dynamic>{},
      user_id: _user_id(),
    );
  }

  Map<String, dynamic> get read_record =>
      resume_record?.record ?? <String, dynamic>{};
  List<ComicChapter> get readable_chapters =>
      detail == null ? <ComicChapter>[] : comic_readable_chapters(detail!);

  Future<void> load({String? language}) async {
    final request_id = ++_request_id;
    _progress_request_id++;
    final identity = _identity();
    final user_id = _user_id();
    final collection_revision = _collection_revision;
    selected_code = language ?? selected_code;
    loading = true;
    error = null;
    emit();
    try {
      final value = await _fetch_detail(comic_id, language: selected_code);
      if (disposed || request_id != _request_id || identity != _identity()) {
        return;
      }
      final local = await _read_progress(comic_id, user_id: user_id);
      if (disposed || request_id != _request_id || identity != _identity()) {
        return;
      }
      local_record = local;
      detail = value;
      selected_code = value.selected_language?.language ?? selected_code;
      _loaded_identity = identity;
      // 背景刷新发出的旧快照不能撤销已经成功的收藏操作。
      if (collection_revision == _collection_revision) {
        collected = value.is_collected;
      }
    } catch (failure) {
      if (!disposed && request_id == _request_id && identity == _identity()) {
        error = failure.toString();
      }
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        emit();
      }
    }
  }

  void _on_progress_changed() {
    unawaited(refresh_progress());
  }

  /// reader服务写入内存后主动通知；从阅读页回来无需重新拉取整个目录。
  Future<void> refresh_progress() async {
    if (disposed || detail == null) return;
    final request_id = ++_progress_request_id;
    final identity = _identity();
    Map<String, dynamic> record;
    try {
      record = await _read_progress(comic_id, user_id: _user_id());
    } catch (_) {
      return;
    }
    if (disposed ||
        request_id != _progress_request_id ||
        identity != _identity()) {
      return;
    }
    local_record = record;
    emit();
  }

  Future<void> collect() async {
    if (collecting || !_require_login()) return;
    final identity = _identity();
    final auth_revision = Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>().auth_revision
        : null;
    final requested_collected = !collected;
    collecting = true;
    emit();
    try {
      await _request('collect', <String, dynamic>{
        'comic_id': comic_id,
        'collected': requested_collected,
      });
      if (identity != _identity()) return;
      _collection_revision++;
      if (!disposed) collected = requested_collected;
      unawaited(
        _favorite_changed(auth_revision).catchError((Object failure) {
          /* 收藏已成功，书架可在下一次激活时重试刷新。 */
        }),
      );
    } catch (failure) {
      if (!disposed && identity == _identity()) {
        showBottomTip(failure.toString());
      }
    } finally {
      collecting = false;
      emit();
    }
  }

  int get start_chapter_id =>
      resume_record?.chapter.id ??
      (readable_chapters.isEmpty ? 0 : readable_chapters.first.id);
  bool get can_continue => resume_record != null;
  String? get resume_chapter_title => resume_record?.chapter.title;

  void open_comments() => _navigate('/comics/comments?comic_id=$comic_id');

  /// 失效记录只回退章首，决不把旧章页码带到一个没有阅读过的章节。
  void open_chapter(int chapter_id, {bool resume = false}) {
    if (loading ||
        !readable_chapters.any((chapter) => chapter.id == chapter_id)) {
      return;
    }
    final record = resume_record;
    final page_index = resume && record?.chapter.id == chapter_id
        ? record!.page_index
        : 0;
    _navigate(
      '/comics/read?chapter_id=$chapter_id&page=$page_index&resume=${resume && record?.chapter.id == chapter_id ? 1 : 0}',
    );
  }

  @override
  void dispose() {
    _progress_changes.removeListener(_on_progress_changed);
    _identity_worker?.dispose();
    super.dispose();
  }
}
