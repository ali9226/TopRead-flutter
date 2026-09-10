# 作品编辑与发布

## 目录结构

- `_shared/`：路由共享代码（草稿持久化、表单管理、文件处理、发布策略、样式常量、共用 widget）。
  - `style.dart`、`editor_publish_policy.dart`、`draft_persistence.dart`：共用状态规则、保存与发布重试。
  - `editor_form_manager.dart`、`editor_file_handler.dart`：表单逻辑与文件操作 mixin。
  - `backend_draft_loader.dart`、`work_recovery.dart`：后端草稿加载与本地恢复。
  - `widgets/steps/`：共用资料、分类、正文、时间选择与按钮样式。
- `long_novel_editor/`：未发布长篇路由，保留基本资料、分类、章节、发布方式四步 UI。章节输入实时进入 `ChapterEditingSession`，保存完整章节数组，重新进入前通过 `_shared/backend_draft_loader.dart` 读取正文。
- `short_novel_editor/`：短篇新增和编辑共用页面。已发布作品直接发布修改，不显示草稿保存和定时发布步骤。
- `published_long_novel_editor/`：已发布长篇专用路由，复用 `workspace/` 的资料和分页章节管理。
- `single_chapter/`：原章节修改直接即时发布；新章节允许保存草稿，发布时复用 `chapter_publish_sheet.dart` 选择立即或定时发布。
- `workspace/`：工作区页面，已发布作品的资料与章节管理。

## 业务规则

创作中心分为已发布、未发布长篇、未发布短篇，不再提供审核 Tab。作品发布后或定时发布尚未到期时禁止保存作品草稿。章节换序和删除确认后在后端同一事务内立即生效；失败不残留待提交草稿。定时新章互相独立，也不阻塞原章或作品资料修改。

定时作品的表单保持可编辑，发布时携带原修订编号和 `replace_scheduled:true` 更新排期内容，默认回显原发布时间；可以修改时间或改为立即发布。服务端在同一事务替换批次，失败保留原排期，原修订已经更新或到期发布时拒绝旧页面覆盖。

## 验证

```bash
fvm flutter test --no-pub test/pages/work_editor
```
