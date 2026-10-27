// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/services/work_favorite_signals.dart';
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
  final WorkFavoriteSignals _favorite_signals;
  final bool Function() _require_login;
  final void Function(String) _navigate;
  final void Function(String) _on_collection_error;
  Worker? _identity_worker;

  ComicDetailLogic(
    this.comic_id, {
    ComicDetailFetcher? fetch_detail,
    ComicDetailProgressReader? read_progress,
    Listenable? progress_changes,
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
    request,
    Future<void> Function()? favorite_changed,
    WorkFavoriteSignals? favorite_signals,
    bool Function()? require_login,
    void Function(String)? navigate,
    void Function(String)? on_collection_error,
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
       _favorite_signals = favorite_signals ?? WorkFavoriteSignals.instance,
       _on_collection_error = on_collection_error ?? showBottomTip,
       _navigate = navigate ?? ((path) => routerUtil(path: path)) {
    _progress_changes.addListener(_on_progress_changed);
    _favorite_signals.addListener(_on_favorite_signal);
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
  List<ComicItem> similar_comics = <ComicItem>[];
  bool loading = true;
  bool collecting = false;
  String? _collecting_identity;
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
      // 同账号的旧快照不能撤销在途或已确认的收藏；新账号仍可加载真实状态。
      if (_collecting_identity != identity &&
          collection_revision == _collection_revision) {
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

  /// 加载相似漫画推荐（公开方法，由页面在适当时机调用）。
  Future<void> load_similar() async {
    try {
      final list = await comics_similar(comic_id);
      if (!disposed) {
        similar_comics = list;
        emit();
      }
    } catch (_) {
      // 相似推荐是锦上添花，失败不影响主流程。
    }
  }

  void _on_progress_changed() {
    unawaited(refresh_progress());
  }

  /// TODO 独立的阅读/简介控制器只接受同账号、同漫画的已确认收藏，不影响任何点赞状态。
  void _on_favorite_signal() {
    final change = _favorite_signals.latest;
    if (disposed ||
        change == null ||
        change.domain != WorkFavoriteDomain.comic ||
        change.work_id != comic_id ||
        change.account_identity != _identity()) {
      return;
    }
    // 相同星形也可能是另一页刚确认的结果，必须使本地在途失败回退失效。
    _collection_revision++;
    if (collected == change.favorited) return;
    collected = change.favorited;
    emit();
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
    final previous_collected = collected;
    final collection_revision = ++_collection_revision;
    collected = requested_collected;
    collecting = true;
    _collecting_identity = identity;
    emit();
    try {
      final response = await _request('collect', <String, dynamic>{
        'comic_id': comic_id,
        'collected': requested_collected,
      });
      if (identity != _identity()) return;
      final confirmed = response.containsKey('collected')
          ? comics_bool(response['collected'])
          : requested_collected;
      _collection_revision++;
      if (!disposed) collected = confirmed;
      _favorite_signals.confirm(
        WorkFavoriteChange(
          domain: WorkFavoriteDomain.comic,
          work_id: comic_id,
          favorited: confirmed,
          account_identity: identity,
        ),
      );
      unawaited(
        _favorite_changed(auth_revision).catchError((Object failure) {
          /* 收藏已成功，书架可在下一次激活时重试刷新。 */
        }),
      );
    } catch (failure) {
      if (!disposed && identity == _identity()) {
        // 后来收到的跨页确认优先；只回退本次仍然有效的乐观更新。
        if (_collection_revision == collection_revision) {
          collected = previous_collected;
          _collection_revision++;
        }
        _on_collection_error(failure.toString());
      }
    } finally {
      collecting = false;
      _collecting_identity = null;
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
    _favorite_signals.removeListener(_on_favorite_signal);
    _identity_worker?.dispose();
    super.dispose();
  }
}
