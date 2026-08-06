// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/back_aware_page.dart';
import 'package:app/components/shell_tab_host/index.dart';
import 'package:app/pages/change_nickname/index.dart';
import 'package:app/pages/change_password/index.dart';
import 'package:app/pages/image_text/index.dart';
import 'package:app/pages/register/index.dart';
import 'package:app/pages/ranking_full_list/index.dart';
import 'package:app/pages/read/index.dart';
import 'package:app/pages/selection_language/index.dart';
import 'package:app/pages/search/index.dart';
import 'package:app/pages/web_view/index.dart';
import 'package:app/pages/interest_preference/index.dart';
import 'package:app/pages/registration_interest_preference/index.dart';
import 'package:app/pages/short_story_read/index.dart';
import 'package:app/pages/customer_service_chat/index.dart';
import 'package:app/pages/about_topread/index.dart';
import 'package:app/pages/debug/index.dart';
import 'package:app/pages/installation/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/pages/login/index.dart' as login_page;

/// 路由配置。
///
/// 负责构建应用完整的 GoRouter 路由表。
class RouteConfig {
  /// 根据当前平台构建路由页面对象。
  ///
  /// iOS 使用 CupertinoPage 以支持左缘侧滑返回手势。
  /// 其他平台使用 MaterialPage。
  static Page<dynamic> buildRoutePage({
    required GoRouterState state,
    required Widget child,
  }) {
    final Widget wrappedChild = BackAwarePage(child: child);
    final LocalKey stableKey = ValueKey(state.uri.toString());

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoPage<dynamic>(key: stableKey, child: wrappedChild);
    }

    return MaterialPage<dynamic>(key: stableKey, child: wrappedChild);
  }

  /// 构建应用完整路由表。
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return BackAwarePage(
              child: ShellTabHost(
                key: const ValueKey('shell_tab_host'),
                activePath: state.uri.path,
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: '/bookshelf',
              name: 'bookshelf',
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: '/user_info',
              name: 'user_info',
              builder: (context, state) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: '/message',
              name: 'message',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: login_page.Login()),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder: (context, state) {
            final c = state.uri.queryParameters['c'];
            return buildRoutePage(
              state: state,
              child: Register(c: c),
            );
          },
        ),
        GoRoute(
          path: '/change_nickname',
          name: 'change_nickname',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const ChangeNickname()),
        ),
        GoRoute(
          path: '/change_password',
          name: 'change_password',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const ChangePassword()),
        ),
        GoRoute(
          path: '/selection_language',
          name: 'selection_language',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: SelectionLanguage()),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const SearchPage()),
        ),
        GoRoute(
          path: '/short_story_read',
          name: 'short_story_read',
          pageBuilder: (context, state) {
            final String? id_str = state.uri.queryParameters['id'];
            final int? story_id = int.tryParse(id_str ?? '');
            final int comment_id =
                int.tryParse(state.uri.queryParameters['comment_id'] ?? '') ??
                0;
            if (story_id == null || story_id <= 0) {
              return buildRoutePage(
                state: state,
                child: const SizedBox.shrink(),
              );
            }
            return buildRoutePage(
              state: state,
              child: ShortStoryReadPage(
                story_id: story_id,
                initial_comment_id: comment_id,
              ),
            );
          },
        ),
        GoRoute(
          path: '/ranking_full_list',
          name: 'ranking_full_list',
          pageBuilder: (context, state) {
            final int initial_tab_id =
                int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
            final int initial_category_id =
                int.tryParse(state.uri.queryParameters['category_id'] ?? '') ??
                0;
            return buildRoutePage(
              state: state,
              child: RankingFullListPage(
                initial_tab_id: initial_tab_id,
                initial_category_id: initial_category_id,
              ),
            );
          },
        ),
        GoRoute(
          path: '/read',
          name: 'read',
          pageBuilder: (context, state) {
            final int story_id =
                int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
            final String story_title = state.uri.queryParameters['title'] ?? '';
            final int comment_id =
                int.tryParse(state.uri.queryParameters['comment_id'] ?? '') ??
                0;
            return buildRoutePage(
              state: state,
              child: ReadPage(
                story_id: story_id,
                story_title: story_title,
                initial_comment_id: comment_id,
              ),
            );
          },
        ),
        GoRoute(
          path: '/image_text',
          name: 'image_text',
          pageBuilder: (context, state) {
            final String? type = state.uri.queryParameters['type'];
            return buildRoutePage(
              state: state,
              child: ImageText(type: type),
            );
          },
        ),
        GoRoute(
          path: '/web_view',
          name: 'web_view',
          pageBuilder: (context, state) {
            final String url = state.uri.queryParameters['url'] ?? '';
            return buildRoutePage(
              state: state,
              child: WebViewPage(url: url),
            );
          },
        ),
        GoRoute(
          path: '/interest_preference',
          name: 'interest_preference',
          pageBuilder: (context, state) => buildRoutePage(
            state: state,
            child: const InterestPreferencePage(),
          ),
        ),
        GoRoute(
          path: '/registration_interest_preference',
          name: 'registration_interest_preference',
          pageBuilder: (context, state) => buildRoutePage(
            state: state,
            child: const RegistrationInterestPreferencePage(),
          ),
        ),
        GoRoute(
          path: '/customer_service_chat',
          name: 'customer_service_chat',
          pageBuilder: (context, state) {
            final bool is_dark = Get.find<DeviceInfo>().dark.value;
            return buildRoutePage(
              state: state,
              child: CustomerServiceChatPage(is_dark: is_dark),
            );
          },
        ),
        GoRoute(
          path: '/debug',
          name: 'debug',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const DebugPage()),
        ),
        GoRoute(
          path: '/about_topread',
          name: 'about_topread',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const AboutTopRead()),
        ),
        GoRoute(
          path: '/installation',
          name: 'installation',
          pageBuilder: (context, state) =>
              buildRoutePage(state: state, child: const InstallationPage()),
        ),
      ],
    );
  }
}
