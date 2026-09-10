# 作品编辑与发布

- `long_novel_editor/`：未发布长篇，保留基本资料、分类、章节、发布方式四步 UI。章节输入实时进入 `ChapterEditingSession`，保存完整章节数组，重新进入前通过 `backend_draft_loader.dart` 读取正文。
- `short_novel_editor/`：短篇新增和编辑共用页面。已发布作品直接发布修改，不显示草稿保存和定时发布步骤。
- `published_long_novel_editor/`：已发布长篇专用路由，复用 `workspace/` 的资料和分页章节管理。资料编辑仍复用原两步表单，不发送章节数组，也不修改作品原有连载状态。
- `single_chapter/`：原章节修改直接即时发布；新章节允许保存草稿，发布时复用 `chapter_publish_sheet.dart` 选择立即或定时发布。排期章节允许编辑并重新发布，但不能保存草稿。
- `editor_publish_policy.dart`、`draft_persistence.dart`：共用状态规则、保存与发布重试；长短篇分别调用 `creator_work/publish_long` 和 `creator_work/publish_short`。
- `widgets/steps/`、`style.dart`、`widgets/editor_actions.dart`：共用已有资料、分类、正文、时间选择与按钮样式，两个页面独立维护流程。

创作中心分为已发布、未发布长篇、未发布短篇，不再提供审核 Tab。作品发布后或定时发布尚未到期时禁止保存作品草稿。章节换序和删除确认后在后端同一事务内立即生效；失败不残留待提交草稿。定时新章互相独立，也不阻塞原章或作品资料修改。

验证：`fvm flutter test --no-pub test/pages/work_editor`。

定时作品的表单保持可编辑，发布时携带原修订编号和 `replace_scheduled:true` 更新排期内容，默认回显原发布时间；可以修改时间或改为立即发布。服务端在同一事务替换批次，失败保留原排期，原修订已经更新或到期发布时拒绝旧页面覆盖。
