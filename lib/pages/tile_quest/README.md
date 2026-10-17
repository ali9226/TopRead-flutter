# Tile Quest

个人中心 → Tile Quest。游戏完全离线，无登录、收费或广告依赖。

## 当前行为与配置

`game/config.dart` 中的 `TileQuestConfig.gameDifficulty` 控制**第二关**难度，范围 1–10，**默认 8**。第一关是独立的简单教学关，不使用第二关的难度规模表。

每次重新进入游戏页面或确认 Restart，都从简单的第一关开始，生成新的 seed、挑战 id 和完整棋盘，仅保留已解锁进度和声音设置。主槽、备用牌、道具余量、Undo 历史、胜负和计时全部重新开始；必须再次通关第一关，再通过 Next 进入第二关。后台与前台切换仍保留当前页面这一局。

第一关仅显示教学棋盘与七格主槽，不显示 Undo/Shuffle/Remove、备用槽、备用牌或结果中的工具统计/撤回按钮；这些界面只在第二关显示。隐藏界面不改变共享的规则引擎、两关相同的棋盘单位尺寸或主槽坐标。

第二关 Remove 当前每局可用 **2 次**，每次移出主槽最前面的至多 3 张，备用容量为 6 张。备用区位于七格主槽**上方**，使用 **3 列叠放**：再次移出会叠在已有牌上，只能点击每列最上方的牌归还，其他列不会横向补位。备用格、备用牌和正常入槽牌共用正方形尺寸及飞行终点。调整 `remove_uses_per_challenge` 时，容量、堆叠高度和道具初始化同步推导；**该配额也是难度 10 能否通关的规则条件**，不是单纯的界面测试参数。Undo、Shuffle 各 1 次，Undo 不退还已经消耗的道具。

## 教学关与统一尺寸

`game/tutorial_layout.dart` 固定生成 **两层 3×3，共 18 张、3 种图案**。每局按 seed 从红色水果/爱心/玫瑰、蓝色宝石/雪花、绿色植物三组各选一种并打散，避免固定使用同色的太阳、月亮和星星；每层各图案 3 张，全局各图案 6 张。行列中心间距为 `2.0` 个逻辑牌宽，保留明显空隙；上层与对应下层的 x 完全相同，**只向下偏移半张牌（y + 0.5）**，下层上半张可见但仍被上层阻挡。开局恰有 9 张上层牌可点，有无需道具的完整合法解。

`widgets/scene_layout.dart` 使用配置中的 **7×9 逻辑画布**确定棋盘牌边长，同一视口下第一关、第二关所有难度及随机形状都使用相同边长。实际牌形在棋盘区域居中；已消除牌仍参与原始边界计算，因此消牌不会放大、缩小或平移剩余棋盘。教学关的大间距与第二关的紧密堆叠共用同一坐标映射。

## 第二关的随机布局与难度阶段

`game/layout_patterns.dart` 已取消固定的六种模板。seed 控制随机生长、挖空、逐层多簇及错层位置，生成不同轮廓与遮挡关系；同层邻牌紧贴，完整的设计缺口可以保留，层间半格错位。随机重标 id、存储顺序及图案映射，避免按编号、行列扫描或固定模板顺序直接还原构造路径。固定 seed 和配置仍可完整复现。

开局主区可点 **30–36 张**，包含 **10–12 组完整三同**；难度 10 额外露出一张门牌，开局可点 **31–37 张**。`game/type_allocator.dart` 先提供容易消除的开场组合，再随进度增加参与图案种类、槽位压力和闭合延迟，高难度后段会保留未闭合配对。开局容易、深层逐渐困难是构造目标；真实玩家感受仍需试玩校准。

下表只描述第二关；第一关始终为上述 18 张教学关。

| 第二关难度 | 方块数 | 图案种类 | 层数 |
| --- | ---: | ---: | ---: |
| 1 | 90 | 5 | 4 |
| 2 | 126 | 6 | 6 |
| 3 | 162 | 8 | 8 |
| 4 | 198 | 10 | 10 |
| 5 | 246 | 12 | 13 |
| 6 | 294 | 16 | 16 |
| 7 | 348 | 20 | 20 |
| 8（默认） | 402 | 24 | 24 |
| 9 | 456 | 28 | 28 |
| 10 | 528 | 32 | 32 |

- `game/generator.dart` 先生成几何和合法拓扑移除顺序，再分配图案。最多尝试 8 次、预算 800 ms，没有无界搜索。
- `game/validator.dart` 独立检查遮挡、库存、重复点击、七槽结算以及完整回放。**难度 1–9 均有经过真实规则重放的完整无道具解**；教学关也有完整无道具解。
- `game/geometry.dart` 缓存严格正面积的跨层矩形覆盖关系，只在规则变化时刷新遮挡。
- `game/engine.dart` 使用同步原子动作和不可变快照，先三消再检查第七格失败。Undo 恢复完整前态并保留已花费道具，不能通过撤回来增加可用容量。
- 普通 Shuffle 保持几何、图案总库存、主槽及备用牌，构造并验证完整后续解；与初始生成共享 `TileQuestTypeAllocator` 的后段分配逻辑，避免把所有剩余图案排成连续三同而降低难度。预算为 250 ms，失败不扣次、不改状态。

初始解序列仅供验证和开发测试，普通游戏不会读取它来修改牌面或控制胜负。偏离构造解后可能形成真实的不可解局面，不能把“开局有解”理解为任意点击顺序都能通关。

## 难度 10 的严格容量门槛

最新需求要求难度 10 在默认道具次数下无法通关，**覆盖最初“所有难度都必须有解”的要求**。`game/expert_barrier.dart` 为难度 10 加入静态的 39 张依赖核心：**13 张不同图案的门牌，以及各自的 2 张伙伴牌**。门牌依次遮挡，所有伙伴都在最后一张门牌之后；门牌的图案不会出现在其他前导区。几何、图案和依赖在开局固定，不会依据玩家操作临时改变。

最后一张门牌离开前，13 张不同图案都无法三消，必须同时存放。保持 playing 的主槽最多放 6 张，默认两次 Remove 最多额外存 6 张，安全容量为 **6 + 2×3 = 12 < 13**，因此任何操作顺序都无法越过该门槛。Undo 不退款，不能扩大容量；关闭的门依赖也受 Shuffle 保护：仅允许不破坏依赖和库存的变换，无法验证安全变换时拒绝且不扣次数，不能把门后伙伴洗到门前。

这与“测试的机器人都没过”有明确区别：默认两次 Remove 时的必败来自上述容量与静态遮挡不变量。增加到 **3 次 Remove** 后安全容量变为 15，模块保留包含三次移出、按列堆顶归还和后续消除的完整见证，并通过真实引擎回放证明可通关。相关依赖、配额、存档、Undo 及 Shuffle 回归见 `expert_barrier_test.dart`；普通无道具证书与此含道具见证不混用。

## 公开玩法研究的范围

参考了玩家本人发布的公开玩法记录：[《羊了个羊》自创通关攻略](https://www.taptap.cn/moment/321248637285829033) 描述深层主区、普通叠层和密集辅助堆的不同用途，主张优先推进深层并保留辅助牌；[《羊了个羊》第二关图文通关秘籍](https://www.taptap.cn/moment/321248061831512333) 记录前半段较易、后半段更依赖顺序规划。两篇均发表于 2022 年 9 月 20 日。

也查看了作者公开发布的[实机通关演示](https://www.bilibili.com/video/BV1e24y1Z7od/)；本轮按可观察的牌面反馈及用户提出的多圈洗牌要求，设计原创动效与音效，不声称原作的精确圈数或粒子实现。

这些是可观察玩法和玩家经验，不是私有源码或官方生成算法。本模块采用自己的随机几何、分阶段图案分配、合法解验证和难度 10 容量门槛，不声称复刻原作内部算法，也不把历史攻略中的版本表现当作当前原作的保证。

## 存档、会话与界面

`logic.dart` 使用 Getx，生成及洗牌在移动端 compute isolate 执行。`services/save_service.dart` 复用 StorageUtil/GetStorage，保存完整挑战快照以验证进度和偏好，但重新进入页面时不续玩旧牌局。写入立即捕获 JSON 后排队，并等待 GetStorage 写入栅栏；读取等待先前保存，损坏存档安全恢复，存储故障可重试。同一保存服务使用单写者会话租约，旧页面与迟到计算不能覆盖新页面进度。退出开始时同步撤销未完成洗牌/关卡生成的提交资格，重复退出共享同一保存栅栏；重开只等待新盘生成，存档快照排队写入，慢写入不持续锁住棋盘。重置确认框单实例并只响应一次确认；模态暂停与系统前后台分别记录，系统恢复不能提前解除弹层暂停。新局及洗牌递增牌面版本，旧画面的按钮、点牌和反馈回调不能操作新版本。

当前游戏状态存档版本为 **v2**，含稳定的 `reserve_columns`、每种道具原始配额 `tool_limits` 及适用时的专家门依赖。读取支持 v1（Remove 原配额 1）及早期未写 `tool_limits` 的 v2（Remove 原配额 2），根据旧配额计算实际已消耗次数，再映射到当前配额；提高测试配额不会抹掉已使用记录。工具库存、列归属、三消库存、普通解证书与专家门依赖均经过校验。

界面采用统一棋盘、主槽和备用区坐标映射。顶部不显示剩余方块数量；不透明底面封住同层内部共享边与 PNG 圆角接缝，内部交汇增加像素覆盖以消除浮点透底，教学关的整组间隔和第二关的设计缺口仍保留。所有动画消费规则结果，不参与规则提交。同帧点击有独立事件记录并按顺序到位；整局动作保留到换局，不能用固定 256 条滑窗截掉尚未呈现的动作；`settlement_tray` 记录插入后、消除前的真实槽顺序，依次播放后牌让位、飞入、消除和收拢。胜负提示等待最新视觉事务结束；备用区归还时顶层飞牌保持在底层牌上方。

每个新挑战播放约 900 ms 的错落落牌入场，所有未移除的牌从屏幕上沿外落到原始坐标，低层先落定、高层随后覆盖；两关、重置和重新进入均会播放。Shuffle 用 2100 ms 把全部剩余棋盘牌（含被遮挡牌）平滑聚拢为一个正圆，连续转动 3.8 圈，再减速分散回原位；旋转阶段所有牌共用同一个固定像素半径与圆心，横纵等比，不再使用逐牌环带或半径起伏，所有牌全程保持棋盘上的正常尺寸（横纵缩放均为 1），不再缩到 62% 或压窄翻转；每张牌仍轻摆，并以同尺寸旧底板和新图案渐变叠加换面，阶段交界的位置和速度连续，主槽和备用牌保持不动。入场与全局洗牌期间锁定棋盘、备用牌与道具，普通飞牌仍支持快速连续点击。逐事务缓存牌序、集合和索引，减少大棋盘洗牌每帧的重复计算。视觉动画结束后继续使用同一份规则状态及几何坐标，动效不改变合法操作或道具结算。

已适配日夜主题、四语翻译、CJK/拉丁文字、SafeArea、短屏横屏和平板。四语备用区提示均说明只可归还顶层牌。声音使用 7 段原创合成 PCM WAV：木片点击、泡泡与上扬三消、移出/撤回、入场柔风、洗牌沙沙、胜利短句及柔和失败下行音；不复用聊天铃声。七段共 246828 Bytes，均为 22050 Hz 单声道 16-bit，首尾平滑淡入淡出，详见 `assets/audio/tile_quest/README.md`。

`TileQuestFeedbackService.play(event)` 保留可注入接口，可选 `TileQuestFeedbackLifecycle` 提供预载、停止和销毁。音频与关卡生成并行预载，首次显示最多等待 240 ms；11 个自有声部允许点击及三消重叠，逐声部队列和取消 token 避免静音、后台、切换挑战或页面销毁后的迟到播放。三消的三张牌各分解为 144 个保留真实原图颜色的碎粒，从原图位置错落散开、轻微旋转并在 480 ms 内淡出；缓冲区和随机参数仅创建一次，以三次 atlas 绘制复用同一场景时钟，无额外 ticker。三消在粒子分解开始时发声，入场与洗牌各播放一次整段声音，胜负音跟随对应视觉事务结束。长时间无帧后的追赶会跳过过期音效，避免回前台同帧集中补播。音频失败不阻断规则或存档；Android 不请求独占焦点，iOS ambient 混音并尊重静音开关。

## 难度评估与数据边界

```sh
fvm dart run tool/tile_quest_evaluate.dart 30 3
```

最终标准评估报告见 `tool/tile_quest/sample_evaluation.json`。本轮已完成每难度 30 个 seed、11 种策略，共 300 张棋盘、3300 次无道具模拟，JSON 已替换旧配置报告。乐观三步搜索在第二关难度 1–10 分别通关 **30、30、28、24、18、5、2、1、0、0 / 30**；参数、其他策略及完整数据以该 JSON 为准。

有限搜索每次决策最多向前 3 手、96 个节点（含根节点），可以预知未来揭开的隐藏图案，属于乐观基准；其他策略依据当前可操作牌及各自的空间顺序决策。所有标准策略均不读取证书，也不使用道具。

本轮核对发现旧版本难度 9 的 Shuffle 会重建普通牌的配对，使同一带道具策略达到 10/20 通关。现在难度 9 的洗牌保留所有匹配与遮挡关系，只交换库存相同且不影响持有牌及稀有牌的图案；偏离已验证路线后，仅在有界搜索验证原牌面的续解时才接受，否则不改牌、不扣次。另沿真实依赖链交错两种各三张的稀有牌，保留三张持续占槽的区间，并仍独立回放完整无道具解。

修正后的独立带道具策略使用两次 Remove、一次 Undo 及需要时的 Shuffle，不读取生成证书或 seed 选择操作，使用乐观的三步前瞻。原组 20 个 seed 通关 2 局，另组 20 个独立 seed 通关 1 局，合计 **3/40**。这比旧版 10/20 改善，但**仍不足以承诺难度 9 仅有理论通关可能**，该项极限难度要求仍需继续校准；不沿用旧源码的 0/60 空间审计充当本轮证据。

**机器人样本通关率不是人类通关率**，有限样本的结果也不能证明无人能通关。`target_failure_rate` 仍是尚未用真实玩家校准的设计目标。难度 10 默认配额下的必败结论则来自独立验证的容量门槛，不依赖样本通关率。

## 文件清单

新增：

- `lib/pages/tile_quest/{index,logic,style}.dart`、本说明。
- `lib/pages/tile_quest/game/{config,models,geometry,generator,layout_patterns,validator,engine}.dart`。
- `lib/pages/tile_quest/game/tutorial_layout.dart`：固定双层 3×3 教学关。
- `lib/pages/tile_quest/game/type_allocator.dart`：生成与 Shuffle 共用的分阶段图案分配。
- `lib/pages/tile_quest/game/expert_barrier.dart`：难度 10 静态门依赖、容量边界和三次 Remove 见证。
- `lib/pages/tile_quest/services/{save_service,work_service,feedback_service}.dart`。
- `lib/pages/tile_quest/widgets/{atmosphere,tile_card,quest_scene,quest_controls,quest_result,quest_text,session_pause}.dart`。
- `lib/pages/tile_quest/widgets/{scene_layout,slot_wells,scene_motion,board_backing}.dart`。
- `lib/pages/tile_quest/widgets/board_motion.dart`：入场及洗牌的独立几何动效。
- `lib/pages/tile_quest/widgets/match_particles.dart`：复用纹理 atlas 和场景时钟的粒子消除。
- `lib/pages/user_info/widgets/tile_quest_entry/{index,style}.dart`。
- `test/pages/tile_quest/{core,persistence,layout,entry,evaluator}_test.dart`。
- `test/pages/tile_quest/{compact_geometry,scene_layout,motion_regression,board_backing}_test.dart`。
- `test/pages/tile_quest/{fresh_entry,irregular_levels,irregular_layout_preview,stacked_reserve,stacked_reserve_layout}_test.dart`。
- `test/pages/tile_quest/{audio_feedback,feedback_timing,entrance_shuffle_motion}_test.dart`：音频资产、声池、视觉时序及全局动效回归。
- `test/pages/tile_quest/tutorial_scale_test.dart`：教学双层半牌遮挡、命中、三色图案及各关等大验收。
- `test/pages/tile_quest/tutorial_controls_test.dart`：第一关无工具/备用区域、第二关恢复显示及真实通关/重置切换验收。
- `test/pages/tile_quest/{match_particles,shuffle_polish}_test.dart`：粒子像素与时序、正圆轨迹、洗牌圈数、速度连续和原尺寸渐变换面验收。
- `test/pages/tile_quest/action_fuzz_test.dart`：真实规则随机混合操作、库存守恒、重复点击、堆顶及存档恢复压力回归。
- `test/pages/tile_quest/rapid_interaction_test.dart`：300 次同帧真实控制器事务、飞行时点下层、工具交错、换局、尺寸变换及长帧追赶。
- `test/pages/tile_quest/interaction_races_test.dart`：慢存储、异步计算退出、重复重置、系统生命周期与弹层、旧版本输入/反馈及胜利按钮竞态。
- `test/pages/tile_quest/visual_motion_preview_test.dart`：可选真实 Flutter 动图导出，400 张棋盘牌运动、持有牌不动及终点验收；通过 `--dart-define=TILE_QUEST_EXPORT_MOTION=true` 显式启用；普通回归还对真实牌面逐帧检查屏幕变换两轴均未缩放或压窄、同尺寸换面及持有牌不动。
- `test/pages/tile_quest/{expert_barrier,type_allocator,shuffle_pressure}_test.dart`：严格门槛、分阶段分配与洗牌后压力回归。
- `tool/tile_quest_evaluate.dart`、`tool/tile_quest/{evaluator.dart,sample_evaluation.json}`。
- `tool/tile_quest/generate_audio.py`：可复现的原创音频合成脚本。
- `assets/audio/tile_quest/{tap,match,tool,entry,shuffle,won,lost}.wav` 及音频说明。

修改：

- `lib/pages/user_info/index.dart`：访客与登录用户均可见的入口。
- `lib/components/app_wrapper/router/route_config.dart`：独立 `/tile_quest` 路由。
- `pubspec.yaml`：注册现有 `assets/img/game/` 及原创 `assets/audio/tile_quest/`，复用项目已有依赖，未新增依赖。
- `assets/i18n/{en,zh,fr,sw}.json`：游戏翻译，保留已有内容。

## 验证与现有项目限制

```sh
fvm flutter pub get
fvm flutter test --no-pub test/pages/tile_quest
fvm dart analyze lib/pages/tile_quest test/pages/tile_quest
fvm flutter test --no-pub
fvm flutter build apk --debug --no-pub
fvm flutter build ios --debug --no-codesign --no-pub
```

- 本轮最终运行游戏模块及路由、个人中心生命周期回归：**222 项通过，1 项可选动图导出默认跳过**；该动图导出用显式开关另跑 1 项并通过。`fvm dart analyze` 检查游戏源码、测试及评估工具：无问题。Android debug APK 和 iOS device debug（未签名）均在本轮构建成功。
- 本轮补充 40 个种子、3,840 次混合规则动作、901 次重复点击和 360 次真实 JSON 存档恢复检查；另覆盖 300 次同帧真实控制器动作、工具密集交错、10 分钟长帧追赶、旋转屏幕、异步计算期间退出和切会话、重复弹窗/确认、慢存档、弹层前后台及旧牌面回调，相关回归均通过。未发现上述覆盖范围内的库存/道具守恒或呈现队列异常，不将有限测试视为所有操作组合的绝对保证。
- 教学与统一尺寸验收覆盖两层各 9 张、三种图案、仅竖直半牌偏移、大行列间距、下层半张可见但不可点，以及 8 种视口下第一关与第二关全部难度/多 seed 的同边长与边界；已消牌不会触发缩放。
- 随机布局与阶段测试检查轮廓互异、逐层多簇、开局完整三同、前后段类型和压力变化、普通完整证书、id 重标及编号/空间策略。难度 10 另检查静态依赖、两次配额容量不足、三次配额真实回放、Undo 和 Shuffle 保持门槛。
- 新局测试覆盖旧胜负、主槽、备用牌、道具和撤回历史清空，从第一关重新开始，解锁和声音继承、新 seed、防止旧异步任务覆盖；道具测试覆盖两次移出、堆顶访问、列归属稳定、归还、Undo、洗牌、v1/v2 配额迁移及严格库存校验。
- 声音与动效测试覆盖全部牌屏外入场、两关重播、正圆完整 3 圈以上、所有牌半径一致且横纵直径相同、交界速度连续、逐牌原尺寸渐变换图、真实纹理碎粒渐散、被遮挡牌参与且无静态牌背残留、持有牌不动、动效输入锁，以及真实页面的三消/胜负视觉时点。声音池测试覆盖 PCM、固定声部重叠及预载/停止/销毁竞态；预载超时和 10 秒长帧不会阻塞或补播过期音效。
- 界面验证保留小屏、刘海 SafeArea、短屏横屏、平板、法语/中文大字体、命中坐标、备用区顺序、等大正方形和两批飞行动画。预览测试导出教学关、六个不同 seed 的真实随机布局、难度 10 和两次 Remove 后的实际 PNG；快速连点、三消插入、撤回及牌缝遮挡继续由回归覆盖。
- 当前 Flutter 3.44.2 的 `flutter analyze` 在中文项目根路径中曾出现 LSP JSON 截断；原项目 `fvm dart analyze` 可作为检查方式。
- 全项目历史上有漫画封面布局及登录语种切换测试失败，iOS 模拟器历史上受 DKPhotoGallery 的 SwiftCompile 错误影响；本模块不改动这些业务、原生工程或依赖。最终全量检查情况以本轮实际运行结果为准。尚无真机或低端设备帧率实测。
