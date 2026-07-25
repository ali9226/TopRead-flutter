# Copilot / AI 助手说明（项目内快速上手指南）

下面的要点帮助 AI 代理快速在本仓库中高效工作 — 关注可执行命令、约定和关键文件位置。

## 一句话架构概览
- 这是一个 Flutter 应用（`lib/` 为主），入口在 `lib/main.dart`。应用使用 `Get` 注入/管理全局状态，路由由 `go_router`（在 `lib/components/app_wrapper/index.dart` 中配置）管理。

## 关键目录和示例文件
- 入口与初始化：`lib/main.dart`（`GetStorage.init()`、`Get.put(...)`、`EasyLocalization`、`OKToast`）
- 路由与应用壳：`lib/components/app_wrapper/index.dart`（使用 `ShellRoute` 保持固定底部导航）
- 全局路由助手：`lib/components/app_wrapper/utils/app_router.dart`（`AppRouter.setRouter(...)`，之后使用 `AppRouter.go('/path')`）
- 状态管理（Get）：`lib/stores/*.dart`（例如 `UserInformation.dart`, `DeviceInfo.dart`, `BottomNavigationInfo.dart`, `GameInfo.dart`）
- 网络层：`lib/api/post_request.dart`（使用 `dio`，包含加解密与本地 web CORS 处理）
- 国际化资源：`assets/i18n/*`（`easy_localization`）
- 代码生成：`freezed` + `json_serializable`（配置见 `pubspec.yaml`）

## 项目特有的开发/构建命令（必须明确）
- 获取依赖：
```
flutter pub get
```
- 代码生成（freezed / json_serializable）：
```
flutter pub run build_runner build --delete-conflicting-outputs
```
```md
# Copilot / AI 助手说明 — 快速上手（精简版）

下面的要点帮助 AI 代理在本仓库中快速产出可运行、低风险的改动：聚焦入口、路由、状态、网络与代码生成。

1) 一句话架构
- Flutter 应用，入口：`lib/main.dart`；全局状态用 `Get`（`lib/stores/`），路由由 `go_router` 在 `lib/components/app_wrapper/index.dart` 管理（使用 `ShellRoute` 保持底部导航）。

2) 关键文件/目录（先看这些）
- `lib/main.dart` — 初始化：`GetStorage.init()`、`Get.put(...)`、`EasyLocalization`。
- `lib/components/app_wrapper/index.dart` — 路由表（GoRoute / ShellRoute）、底部导航保持逻辑。
- `lib/components/app_wrapper/utils/app_router.dart` — 全局路由封装，使用 `AppRouter.go('/path')` 跳转。
- `lib/stores/*.dart` — 全局 controller（观察 `.obs` / `Rx`，UI 使用 `Obx`）。
- `lib/api/post_request.dart` — 网络入口（`dio`、请求加密/解密、resultsType<T> 处理、本地 web CORS 特例）。
- `assets/i18n/` — 国际化资源（`easy_localization`）。

3) 必要命令（拷贝即用）
```
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d <device>
flutter build apk
flutter build ios
flutter build web
```
额外：更改应用名/图标（仓库注释有 TODO）：
```
flutter pub run launcher_name:main
flutter pub run flutter_launcher_icons:main
```

4) 项目特有约定（必须遵守）
- 不要替换 `Get` 或重构为其它状态管理：`Get.put(...)` 注入是全局约定。
- 路由改动应谨慎：`AppWrapper` 包含平台差异与返回处理，避免直接改写底层逻辑。
- 所有后端 POST 通过 `lib/api/post_request.dart`：请求/响应有加密流程，直接替换会破坏协议。
- Web 本地调试会在 `postRequest` 中特殊处理 headers 以减少 CORS 预检。
- 注释中的 `TODO` 往往代表业务决策或遗留兼容性，保留原语义除非做完整修复。

5) 快速示例
- 添加页面并注册路由：
  - 新页面文件：`lib/pages/new_page/index.dart`（导出 `NewPage` Widget）。
  - 在 `lib/components/app_wrapper/index.dart` 的 routes 列表加入：
```dart
GoRoute(path: '/new_page', name: 'new_page', builder: (c, s) => NewPage()),
```
  - 跳转：`AppRouter.go('/new_page')`。

- 读取 query param 示例（在页面构造中）：
```dart
final roomId = state.uri.queryParameters['room_id'];
```

6) 常见修改流程（AI 代理建议）
- 小改动：只改所需文件并保留 `Get` 注入与 `AppWrapper` 路由模式。
- 涉及接口/加密/网络的改动：先检查 `lib/api/post_request.dart`，确认解密/签名规则并同步后端或写兼容层。
- 新页面/路由：添加文件 → 注册 GoRoute → 使用 `AppRouter.go(...)`。

7) 哪里去找更多线索
- 查 `lib/stores/` 可了解响应式字段与 side-effect（登录、设备信息、底部导航状态）。
- 查 `lib/api/post_request.dart` 理解后端交互（尤其是加解密与统一结果封装）。

——
如果你希望进一步：我可以（选项）
- 将此文件翻译为英文并保持中英双语；
- 扩展网络请求示例（解密流程与错误码对照）；
- 生成一个 PR 模板，提示如何变更路由/状态/API。

``` 
