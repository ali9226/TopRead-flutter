# AGENTS.md — TopRead Flutter App

## 项目概览

- TopRead 小说/漫画阅读 App（长篇、短篇、漫画、作者创作、钱包、客服、推送、多语言）。
- Dart 包名 `app`（import 用 `package:app/...`），应用名 TopRead，Bundle ID `com.topread.novel`，版本源在 `lib/config/constant.dart`。
- 线上 API：`https://app.read.top` + 前缀 `/api/`（`lib/config/constant.dart` 的 `requestUrl`/`prefix`）。
- 兄弟仓库：`../后端`（Node API）、`../前端`（Vue 后台）、`../官网`（Web 站）、`../notify`（飞书通知服务）。

## 命令（重要：必须用 fvm）

**本机 `flutter`/`dart` 不在 PATH，一律通过 fvm 执行**（`.fvmrc` 固定 Flutter 3.44.2 / Dart 3.12.2）：

```bash
make run            # = fvm flutter run（先跑 scripts/sync_version.sh 同步版本号）
make run-android / make run-ios / make run-web
make build-apk      # = fvm flutter build apk --release
make build-ios / make build-web
make sync           # 同步 constant.dart 的版本号到 pubspec.yaml
fvm flutter test                              # 全部测试（245 个 *_test.dart）
fvm flutter test --no-pub test/pages/work_editor   # 按目录跑
fvm dart analyze <改动的文件> 2>&1 | grep -E "error|warning"   # 改完必跑，error 清零
fvm dart format .    # 重构后格式化
fvm flutter clean && fvm flutter pub get      # 缓存/依赖异常时
```

- 入口唯一：`lib/main.dart`（无 flavor、无多入口）。
- 构建产物命名/图标：`fvm flutter pub run launcher_name:main`、`fvm flutter pub run flutter_launcher_icons:main`。
- freezed/json_serializable/build_runner 在 dev_deps 里但**当前未使用**（没有任何 .g.dart/.freezed.dart，模型全部手写 fromJson）；不要假设存在生成代码。

## 架构

分层目录（layer-first），不是 feature-first：

| 目录 | 职责 |
|---|---|
| `lib/api/` | 网络层。**所有后端请求必须走 `lib/api/post_request.dart` 的 `postRequest<T>()`**（自带请求加密、响应解密、错误 toast、语言头），不要绕过 |
| `lib/stores/` | 全局状态：GetX 的 `GetxController`，在 `main.dart` 里 `Get.put(...)` 注册，UI 用 `.obs`/`Obx`/`Get.find<T>()`。**不要替换成其他状态管理** |
| `lib/components/app_wrapper/router/route_config.dart` | go_router 路由表（`RouteConfig`，ShellRoute 底部 4 tab：`/`、`/bookshelf`、`/user_info`、`/message`，共约 34 条路径） |
| `lib/components/app_wrapper/utils/app_router.dart` + `lib/util/router/router_util.dart` | 导航封装：`AppRouter.go/push/replace/pop`、`routerUtil(path:, type:)` |
| `lib/models/` | 纯数据类 + 手写 `fromJson` |
| `lib/pages/` | 路由页面（按功能分目录） |
| `lib/components/` | 共享组件（约 65 个目录） |
| `lib/services/` | 业务服务（广告池、书架同步、推荐刷新等） |
| `lib/config/` | `constant.dart`、`color_config.dart`、`font_config.dart`、`theme.dart` 等 |
| `lib/websocket/` | WS 服务（鉴权/心跳/重连） |
| `lib/util/` | 工具（加密、存储、语言、路由、设备…） |

其他要点：

- 本地存储用 **get_storage**（封装在 `lib/util/storage_util/`），不是 hive/sqflite。
- 网络用 **dio**（单例 `lib/api/dio_client.dart`）；加解密在 `lib/util/encryption/`（AES/JWT）。
- i18n 用 **easy_localization** + `assets/i18n/{zh,en,fr,sw}.json`。
- DI 只用 GetX（`Get.put`/`Get.find`），没有 get_it。

## 编码规范（必须遵守）

1. **命名用 snake_case**（非标准 Dart！）：变量、函数、参数、常量一律 `get_language()`、`app_name` 风格；类名/枚举/扩展用 PascalCase。`analysis_options.yaml` 故意关掉了 `non_constant_identifier_names`/`constant_identifier_names`，不要打开。
2. **页面/组件三段式**（最重要的结构规则）：
   ```
   lib/pages/<page_name>/
     index.dart   # 只放 UI 结构
     logic.dart   # 交互、状态、数据请求
     style.dart   # 样式常量（禁止魔法数字）
     widgets/     # 子组件（子组件同样遵守三段式思路）
   ```
3. **所有注释加 `TODO` 前缀**：`// TODO 说明` 或 `/* TODO\n * ... */`（这是本项目风格，不代表未完成）。构造参数、页面头部、复杂函数必须写作用/参数/返回值。
4. **日夜主题**：所有 UI 必须适配深浅色（`lib/config/theme.dart`）。
5. **中西文适配**：中文（CJK）与字母文字样式不同，提供 `xxx_cjk`/`xxx_alphabetic` 成对样式，用 `LanguageUtil.is_cjk_language()` 判断。
6. **字重必须过 `FontConfig.adjustedWeight(FontWeight.w4xx)`**（`lib/config/font_config.dart`，适配 Android/iOS 字体差异）。注意：它是 `static final` 而非 `const`，用到它的 TextStyle 不能写 `const`。
7. 颜色取 `lib/config/color_config.dart`（`dangerColor` 红、`successColor` 绿、`themeColor` 主题色）。
8. 无用代码直接删；重构后必须 `fvm dart format` + `fvm dart analyze` 过一遍。

## 常见改动模式

**新增页面**：建 `lib/pages/<name>/{index,logic,style}.dart` 三段式 → 在 `lib/components/app_wrapper/router/route_config.dart` 注册 `GoRoute`（query 参数用 `state.uri.queryParameters`）→ 用 `routerUtil`/`AppRouter` 跳转。路由路径用小写下划线（如 `/top_up_record`）。

**新增接口**：`lib/api/<feature>.dart`，内部走 `postRequest`，结果用 `ResultsType<T>`（`lib/api/results_type.dart`）。

**新增全局状态**：`lib/stores/<name>_store.dart` 继承 `GetxController`，在 `main.dart` 的 `Get.put` 区注册。

**新增共享组件**：`lib/components/<name>/`，能复用就复用，不重复造。

## 测试与验证

- `test/` 镜像 `lib/` 结构，`flutter_test`（单测 + `testWidgets`），无 golden、无 CI；`integration_test/` 已配置（真实模拟器手势演练，见下方）。
- **界面测试规范**（定位/操作/断言/汇报纪律）见 `.mimocode/skills/flutter-ui-test/SKILL.md`：优先 `find.byKey`（snake_case Key），断言实际反馈，结论必须注明"widget 测试（假数据）"还是"模拟器实测（真实接口）"。
- 改完代码的最低验证：`fvm dart analyze <文件>` error 清零 + 相关 `fvm flutter test test/<对应目录>`。
- 路由改动必须真机/模拟器验证跳转（路由是高风险区）。
- **iOS 模拟器调试（Device Hub / Xcode 27）**：主力机 iPhone 18 Pro Max。构建运行 `fvm flutter run -d <udid>`、截图 `xcrun simctl io <udid> screenshot`、点按/滑动/输入用 Maestro（`maestro test --device <udid> <flow.yaml>`，按文字定位元素）。完整工作流见 `.mimocode/skills/ios-sim-debug/SKILL.md`，改 UI 后应跑 maestro 流程截图自验。

## 已知坑

- **路由未注册**：`/top_up`、`/top_up_qr_code`、`/top_up_record`、`/withdraw`、`/withdraw_record`、`/bill`、`user_info_input` 的页面存在且代码里有跳转调用，但**没在 `route_config.dart` 注册**（`要求.txt` 标注"路由待补充注册"）。动这些功能前先确认路由现状。
- `.mimocode/skills/` 里的技能有两处过时，以本文件为准：
  - `flutter-error-fix`/`flutter-new-page` 写的裸 `flutter` 命令要换成 `fvm flutter`；
  - `flutter-new-page` 说注册在 `app_wrapper/index.dart`，实际路由表在 `router/route_config.dart`。
- 根目录 `package.json` 的 `@openim/wasm-client-sdk` 在 lib/ 里无引用，属休眠/实验依赖。
- `flutter_sdk/`、`build/`、`caches/`、`daemon/`、`native/`、`wrapper/` 是本地产物，不要动（见 `AUDIT_SCOPE.md`）。

## 工作流约定

- 完成任务或需要授权时，发飞书通知：`redis-cli publish notify:task_done "内容"`（详细规则见 `全局需求.txt` / `要求.txt`；需要授权的操作必须先发【需授权】通知再执行）。
- 输出尽量只给可运行代码，少废话，省 token。

## 文档索引（先读再改）

| 文件 | 内容 |
|---|---|
| `要求.txt` | 最完整的模块/路由→页面职责地图 |
| `开发规范.md` | 编码硬规则（命名、主题、CJK、字重、TODO 注释） |
| `PROJECT_CONVENTIONS.md` | 命名与注释约定 |
| `作者需求.md` | 作者/创作模块交接文档 |
| `阅读页面重构需求文档.md` | 长篇阅读页需求 |
| `全局需求.txt` | 仓库布局 + 通知工作流 |
| `资料/flutter命令.md` | 构建/安装/日志命令备忘 |
| `.github/copilot-instructions.md` | AI 快速上手摘要 |
