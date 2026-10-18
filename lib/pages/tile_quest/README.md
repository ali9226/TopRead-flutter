# Tile Quest

个人中心 → Tile Quest。游戏完全离线，无登录、收费或广告依赖。

## 当前行为与配置

`game/config.dart` 中的 `TileQuestConfig.gameDifficulty` 控制**第二关**难度，范围 1–10，**默认 8**。第一关是独立的简单教学关，不使用第二关的难度规模表。

每次重新进入游戏页面或确认 Restart，都从简单的第一关开始，生成新的 seed、挑战 id 和完整棋盘，仅保留已解锁进度和声音设置。主槽、备用牌、道具余量、Undo 历史、胜负和计时全部重新开始；必须再次通关第一关，再通过 Next 进入第二关。后台与前台切换仍保留当前页面这一局。

第一关仅显示教学棋盘与七格主槽，不显示 Undo/Shuffle/Remove、备用槽、备用牌或结果中的工具统计/撤回按钮；这些界面只在第二关显示。隐藏界面不改变共享的规则引擎、两关相同的棋盘单位尺寸或主槽坐标。

第二关 Remove 当前每局可用 **2 次**，每次移出主槽最前面的至多 3 张，备用容量为 6 张。备用区位于七格主槽**上方**，使用 **3 列叠放**：再次移出会叠在已有牌上，只能点击每列最上方的牌归还，其他列不会横向补位。备用格、备用牌和正常入槽牌共用正方形尺寸及飞行终点。调整 `remove_uses_per_challenge` 时，容量、堆叠高度和道具初始化同步推导；**该配额也是难度 10 能否通关的规则条件**，不是单纯的界面测试参数。Undo、Shuffle 各 1 次，Undo 不退还已经消耗的道具。

## 教学关与统一尺寸

`game/tutorial_layout.dart` 固定生成 **两层 3×3，共 18 张、3 种图案**。每局按 seed 从红色水果、蓝色宝石/雪花/蓝莓、绿色叶片/牛油果三组各选一种并打散，避免固定使用同色的太阳、月亮和星星；每层各图案 3 张，全局各图案 6 张。行列中心间距为 `2.0` 个逻辑牌宽，保留明显空隙；上层与对应下层的 x 完全相同，**只向下偏移半张牌（y + 0.5）**，下层上半张可见但仍被上层阻挡。开局恰有 9 张上层牌可点，有无需道具的完整合法解。

`widgets/scene_layout.dart` 使用配置中的 **7×9 逻辑画布**确定棋盘牌边长，同一视口下第一关、第二关所有难度及随机形状都使用相同边长。实际牌形在棋盘区域居中；已消除牌仍参与原始边界计算，因此消牌不会放大、缩小或平移剩余棋盘。教学关的大间距与第二关的紧密堆叠共用同一坐标映射。

## 第二关的随机布局与难度阶段

`game/layout_patterns.dart` 已取消固定的六种模板。seed 控制随机生长、挖空、逐层多簇及错层位置，生成不同轮廓与遮挡关系；同层邻牌紧贴，完整的设计缺口可以保留，层间半格错位。随机重标 id、存储顺序及图案映射，避免按编号、行列扫描或固定模板顺序直接还原构造路径。固定 seed 和配置仍可完整复现。

开局主区可点 **30–36 张**，包含 **10–12 组完整三同**；难度 5–10 额外露出一张门牌，开局可点 **31–37 张**。`game/type_allocator.dart` 先提供容易消除的开场组合，再随进度增加参与图案种类、槽位压力和闭合延迟，高难度后段会保留未闭合配对。难度 6–10 在开场后立即启用完整的普通图案集合与六槽目标压力，避免十五图案上限下旧的类型爬坡退化成大段连续三同。固定稀有键之前用三步真实匹配窗口检查候选，提前避免多个普通单张堵死下一张必须取出的键。开局容易、深层逐渐困难是构造目标；真实玩家感受仍需试玩校准。

`game/tile_palette.dart` 是十五个真实图案的唯一清单：watermelon、strawberry、pink_flower、blueberries、carrot、apple、grapes、lemon、mushroom、snowflake、potion、leaf、shell、avocado、blue_gem。规则类型与 PNG 一一对应，不能通过取余把不同类型绘成相同图标。

难度 6–8 分别在 16/20/24 层真实遮挡链中保留一组仅三张的稀有配对，先持有两张、最后一张深埋；除去四种独立门牌与这一种稀有图案，其余 7/8/9 种图案均可参与普通匹配，开场图案仍参与深层，避免减少图案时意外降低难度。难度 8 更早取到第二张、更晚闭合。难度 9 使用更深的 40 层依赖与两组稀有配对，中段持续占四槽，并保留经过独立规则重放的完整含道具证书。难度 10 则使用下述严格容量门槛。

下表只描述第二关；第一关始终为上述 18 张教学关。

| 第二关难度 | 方块数 | 图案种类 | 层数 |
| --- | ---: | ---: | ---: |
| 1 | 90 | 5 | 4 |
| 2 | 126 | 6 | 6 |
| 3 | 162 | 8 | 8 |
| 4 | 198 | 10 | 10 |
| 5 | 246 | 11 | 13 |
| 6 | 294 | 12 | 16 |
| 7 | 348 | 13 | 20 |
| 8（默认） | 402 | 14 | 24 |
| 9 | 456 | 15 | 40 |
| 10 | 528 | 15 | 48 |

- `game/generator.dart` 先生成几何和合法拓扑移除顺序，再分配图案。最多尝试 8 次、预算 800 ms，没有无界搜索。
- `game/validator.dart` 独立检查遮挡、库存、重复点击、七槽结算以及完整回放。**教学关及难度 1–4 有完整无道具解；5–9 必须使用至少一次 Remove，且有真实规则验证的单次 Remove 通关见证；10 在默认两次 Remove 下无解。**
- `game/geometry.dart` 缓存严格正面积的跨层矩形覆盖关系，只在规则变化时刷新遮挡。
- `game/engine.dart` 使用同步原子动作和不可变快照，先三消再检查第七格失败。Undo 恢复完整前态并保留已花费道具，不能通过撤回来增加可用容量。
- 普通 Shuffle 保持几何、图案总库存、主槽及备用牌，构造并验证完整后续解；与初始生成共享 `TileQuestTypeAllocator` 的后段分配逻辑，避免把所有剩余图案排成连续三同而降低难度。预算为 250 ms，失败不扣次、不改状态。

初始解序列仅供验证和开发测试，普通游戏不会读取它来修改牌面或控制胜负。偏离构造解后可能形成真实的不可解局面，不能把“开局有解”理解为任意点击顺序都能通关。

## 难度 5–9 的强制道具门槛

难度 **5（含）至9** 均包含固定的12张依赖核心：七张门牌按 A/B/C/A/B/C/D 顺序逐张遮挡，五张伙伴牌 A/B/C/D/D 全在最后一张门牌之后。四种图案在整局各只有这三张，普通区域不能提供额外配对。必须先取走七张尚不能三消的门牌，才可触及任何补齐牌；主槽安全容量只有六张，所以**不用道具在任何点击顺序下均无法通关**。这依赖真实初始牌面与遮挡，不在最后一步临时阻止胜利。

一次 Remove 足够：取 A/B/C 后移到三个备用列，再取 A/B/C/D，逐列归还先前的 A、B、C 并取对应伙伴闭合，最后两张 D 清槽。构造器独立重放完整路径，证书中的 `-1` 表示 Remove，重复的牌 id 表示按堆顶归还备用牌。普通区域、门牌、备用区均使用同一个实际引擎结算。

Shuffle 不把伙伴洗到门前；5–8级未动核心时可在普通区域构造真实续解，9级固定原有匹配和稀有键关系，仅在证明续解后执行等库存的整类图案交换。无法在统一250ms预算内证明安全续解时原子拒绝、不扣次数。Undo不退还已用道具。存档必须包含当前难度的合法门结构；旧版5–9级无门棋盘会安全重开并保留经过独立检查的声音、解锁进度和seed。

`mandatory_tool_test.dart` 覆盖零道具失败、单次移出通关、每步JSON往返、备用列、Undo、Shuffle以及损坏与旧版快照拒绝。图案总数、牌数及层数保持上表。

## 难度 10 的严格容量门槛

最新需求要求难度 10 在默认道具次数下无法通关，**覆盖最初“所有难度都必须有解”的要求**。`game/expert_barrier.dart` 为难度 10 加入静态的 **21 张依赖核心：13 张门牌与 8 张伙伴牌，共 7 种真实图案**。门牌依次遮挡，图案顺序为 A/B/C/D/E/F/A/B/C/D/E/F/G；前六种各出现两张，G 出现一张。所有补齐三同的伙伴都在最后一张门牌之后，这七种图案不会出现在其他前导区。前导区使用剩余八种图案，完整棋盘仅使用指定的十五张 PNG，规则类型与图案一一对应，不以隐藏类型拆分相同图案。

最后一张门牌离开前，任何一种门牌图案都凑不出三同，13 张门牌必须同时存放。保持 playing 的主槽最多放 6 张，默认两次 Remove 最多额外存 6 张，安全容量为 **6 + 2×3 = 12 < 13**，因此任何操作顺序都无法越过该门槛。Undo 不退款，不能扩大容量；关闭的门依赖也受 Shuffle 保护：仅允许不破坏依赖和库存的图案整体重命名，无法验证安全变换时拒绝且不扣次数，不能把门后伙伴洗到门前。

默认必败结论来自容量与静态遮挡不变量，而非机器人样本零胜率。增加到 **3 次 Remove** 后安全容量变为 15，模块保留完整含道具见证：前三批分别移出 A/B/C、D/E/F、A/B/C，形成 `[A,D,A]`、`[B,E,B]`、`[C,F,C]` 三列；余下 D/E/F/G 入槽后，依次按堆顶归还并与 D/A/E/B/F/C/G/G 伙伴完成三消。独立规则重放验证该路径始终不占满七槽且最终清空棋盘、主槽和备用牌。相关依赖、配额、存档、Undo 及 Shuffle 回归见 `expert_barrier_test.dart`；1–4级无道具证书与5–10级含道具见证均按实际步骤回放。

## 公开玩法研究的范围

参考了玩家本人发布的公开玩法记录：[《羊了个羊》自创通关攻略](https://www.taptap.cn/moment/321248637285829033) 描述深层主区、普通叠层和密集辅助堆的不同用途，主张优先推进深层并保留辅助牌；[《羊了个羊》第二关图文通关秘籍](https://www.taptap.cn/moment/321248061831512333) 记录前半段较易、后半段更依赖顺序规划。两篇均发表于 2022 年 9 月 20 日。

也查看了作者公开发布的[实机通关演示](https://www.bilibili.com/video/BV1e24y1Z7od/)；本轮按可观察的牌面反馈及用户提出的多圈洗牌要求，设计原创动效与音效，不声称原作的精确圈数或粒子实现。

这些是可观察玩法和玩家经验，不是私有源码或官方生成算法。本模块采用自己的随机几何、分阶段图案分配、合法解验证和难度 10 容量门槛，不声称复刻原作内部算法，也不把历史攻略中的版本表现当作当前原作的保证。

## 存档、会话与界面

`logic.dart` 使用 Getx，生成及洗牌在移动端 compute isolate 执行。`services/save_service.dart` 复用 StorageUtil/GetStorage，保存完整挑战快照以验证进度和偏好，但重新进入页面时不续玩旧牌局。普通点击和备用牌归还在固定的 240 ms 窗口内合并保存，后续点击不会推迟窗口截止时间；终局、道具、声音偏好、切后台、离开和重开会取消窗口并立即保存。写入立即捕获当前态与 Undo 态的不可变引用，在工作 isolate 转换并编码 JSON；尚未开始的写入合并到最新快照，并等待 GetStorage 写入栅栏；读取等待先前保存，损坏存档安全恢复，存储故障可重试。同一保存服务使用单写者会话租约，旧页面与迟到计算不能覆盖新页面进度。退出开始时同步撤销未完成洗牌/关卡生成的提交资格，重复退出共享同一保存栅栏；重开只等待新盘生成，存档快照排队写入，慢写入不持续锁住棋盘。重置确认框单实例并只响应一次确认；模态暂停与系统前后台分别记录，系统恢复不能提前解除弹层暂停。新局及洗牌递增牌面版本，旧画面的按钮、点牌和反馈回调不能操作新版本。

当前游戏状态存档版本为 **v2**，含稳定的 `reserve_columns`、每种道具原始配额 `tool_limits` 及适用时的专家门依赖。读取支持 v1（Remove 原配额 1）及早期未写 `tool_limits` 的 v2（Remove 原配额 2），根据旧配额计算实际已消耗次数，再映射到当前配额；提高测试配额不会抹掉已使用记录。工具库存、列归属、三消库存、普通解证书与专家门依赖均经过校验。旧32图案和缺少强制道具核心的高难度存档不会以取余或补造门牌迁移；棋盘校验失败后仅恢复经独立类型和范围检查的解锁进度、声音设置与前一局 seed，再生成新教学关。

界面采用统一棋盘、主槽和备用区坐标映射。顶部不显示剩余方块数量。15 张 PNG 仅包含透明背景图标；牌面按参考图采用约 6.9% 的灰粉褐色薄侧壁、连续圆润倒角、象牙白瓷面及向右下的柔和接触投影，移除厚棕底条、底座亮线及整圈深色描边。材质仅生成一张 192px GPU 底板，柔影与倒角在其中栅格化一次，之后与图标一起预烘焙进入图集；冷启动回退也不执行逐牌模糊。PNG 画布已有透明留白，绘制大小补偿后实际图案约占牌宽 68–74%。遮挡牌保留暖灰瓷面和图标颜色，层间主要依靠真实重叠与局部软投影表现深度。每张牌的厚度和阴影都在统一正方形牌格内，棋盘、主槽、备用区与飞牌共用同一外形。棋盘只保留一个静态画布，入场、飞牌、洗牌与三消共用一个动态画布，时钟直接触发绘制，不再逐帧创建或布局卡片组件。点击采用实际瓷面与厚底的圆角形状命中；被遮挡牌仍遵守原有规则。所有动画消费规则结果，不参与规则提交。同帧点击有独立事件记录，连续插入由 `insertion_timeline.dart` 统一调度槽位，每张牌从点击起连续飞行，普通批次约 340 ms 入槽；跨组三消只错开必要的槽位释放时间，不在槽上方悬停。三消粒子尾迹独立并行，后续飞牌不等待 480 ms 消散结束；同一张牌的移动始终由连续路径管理，重定向继承当前位置、尺寸和一阶速度；解析 Hermite 曲线避免每次插入把运动速度重置为零，也避免旧事务快照把牌拉回或跳槽。整局动作保留到换局，不能用固定 256 条滑窗截掉尚未呈现的动作；`settlement_tray` 提供插入后、消除前的真实槽顺序，道具在前一插入批次呈现完成后执行。胜负提示等待最新视觉事务结束；备用区归还时顶层飞牌保持在底层牌上方。

每个新挑战播放约 900 ms 的错落落牌入场，所有未移除的牌从屏幕上沿外落到原始坐标，低层先落定、高层随后覆盖；两关、重置和重新进入均会播放。Shuffle 用 2100 ms 把全部剩余棋盘牌（含被遮挡牌）平滑聚拢为一个正圆，连续转动 3.8 圈，再减速分散回原位；旋转阶段所有牌共用同一个固定像素半径与圆心，横纵等比，不再使用逐牌环带或半径起伏，所有牌全程保持棋盘上的正常尺寸（横纵缩放均为 1），不再缩到 62% 或压窄翻转；每张牌仍轻摆，并以同尺寸旧底板和新图案渐变叠加换面，阶段交界的位置和速度连续，主槽和备用牌保持不动。入场与全局洗牌期间锁定棋盘、备用牌与道具，普通飞牌仍支持快速连续点击。洗牌使用单个 `CustomPainter` 和一次 `drawRawAtlas` 绘制全部棋盘牌，逐事务缓存牌序、坐标和三角函数，复用纹理与变换缓冲区；不创建逐牌隐藏组件，也不使用逐牌 `saveLayer`。场景提前加载与静态卡片共用解码缓存的纹理，生成含正常/遮挡两种牌面的图集，退出页面释放自有图片、图集和监听；图集未就绪时用同一皮肤与图标回退绘制。待开始的洗牌排除已经由飞行层绘制的牌，保证撤回衔接期间同一牌只出现一次。视觉动画结束后继续使用同一份规则状态及几何坐标，动效不改变合法操作或道具结算。

已适配日夜主题、四语翻译、CJK/拉丁文字、SafeArea、短屏横屏和平板。四语备用区提示均说明只可归还顶层牌。声音使用 7 段原创合成 PCM WAV：木片点击、泡泡与上扬三消、移出/撤回、入场柔风、洗牌沙沙、胜利短句及柔和失败下行音；不复用聊天铃声。七段共 246828 Bytes，均为 22050 Hz 单声道 16-bit，首尾平滑淡入淡出，详见 `assets/audio/tile_quest/README.md`。

`TileQuestFeedbackService.play(event)` 保留可注入接口，可选 `TileQuestFeedbackLifecycle` 提供预载、停止和销毁。音频与关卡生成并行预载，首次显示最多等待 240 ms；11 个自有声部允许点击及三消重叠，逐声部队列和取消 token 避免静音、后台、切换挑战或页面销毁后的迟到播放。三消的三张牌各分解为 144 个保留完整立体牌颜色的碎粒，从原图位置错落散开、轻微旋转并在 480 ms 内淡出；缓冲区和随机参数仅创建一次，以三次 atlas 绘制复用同一场景时钟，无额外 ticker；粒子缓动及透明度使用解析多项式，避免逐粒贝塞尔求根与幂运算。三消在粒子分解开始时发声，入场与洗牌各播放一次整段声音，胜负音跟随对应视觉事务结束。长时间无帧后的追赶会跳过过期音效，避免回前台同帧集中补播。音频失败不阻断规则或存档；Android 不请求独占焦点，iOS ambient 混音并尊重静音开关。

## 难度评估与数据边界

```sh
fvm dart run tool/tile_quest_evaluate.dart 30 3
```

当前配置的标准评估见 `tool/tile_quest/sample_evaluation.json`：30个seed×11种策略×10档，共3300次无道具模拟，5–10级全部未通关。当前9级带道具策略40个seed为0/40，见 `tool/tile_quest/tool_evaluation.json`；独立构造见证仍能真实通关。更改容量门槛后，旧配置的通关率不适用于当前棋盘；报告以实际记录的参数、seed和配置为准。标准策略均不读取证书、不使用道具。5–10级的零道具无解来自静态门槛，并不依赖有限策略的失败样本。

难度9保留40层真实依赖、两组稀有配对和四槽持续占用；洗牌固定所有匹配与稀有键关系。仅在有界搜索验证当前牌面的续解时接受偏离证书后的洗牌，否则不改牌、不扣次。完整合法通关见证包含一次移出，但不是正常玩家的提示或自动改牌来源。

```sh
fvm dart run tool/tile_quest/tools_evaluator.dart 40 9 baseline
```

机器人样本通关率不能等同于人类通关率，也不能证明9级只有理论可能通过。牌数、层数、普通图案与隐藏配对压力随难度递增；5级开始另有强制道具门槛。10级默认配额必败则有独立数学容量证明。

## 文件清单

新增：

- `lib/pages/tile_quest/{index,logic,style}.dart`、本说明。
- `lib/pages/tile_quest/game/{config,models,geometry,generator,layout_patterns,validator,engine}.dart`。
- `lib/pages/tile_quest/game/tutorial_layout.dart`：固定双层 3×3 教学关。
- `lib/pages/tile_quest/game/type_allocator.dart`：生成与 Shuffle 共用的分阶段图案分配。
- `lib/pages/tile_quest/game/expert_barrier.dart`：5–9级强制单次移出与10级三次移出门槛、静态依赖及含道具见证。
- `lib/pages/tile_quest/services/{save_service,work_service,feedback_service}.dart`。
- `lib/pages/tile_quest/widgets/{atmosphere,tile_card,quest_scene,quest_controls,quest_result,quest_text,session_pause}.dart`。
- `lib/pages/tile_quest/widgets/{scene_layout,slot_wells,scene_motion,board_backing}.dart`。
- `lib/pages/tile_quest/widgets/board_motion.dart`：入场及洗牌的独立几何动效。
- `lib/pages/tile_quest/widgets/insertion_timeline.dart`：位置及速度连续的飞行、槽位让位与并行三消尾迹调度。
- `lib/pages/tile_quest/widgets/{board_canvas,motion_canvas,tile_batch,tile_frame}.dart`：实际绘制、圆角命中、语义及共享图集批次。
- `lib/pages/tile_quest/widgets/{tile_surface,tile_surface_style}.dart`：与透明图标独立的立体牌皮肤。
- `lib/pages/tile_quest/widgets/{shuffle_motion,shuffle_textures}.dart`：单画布图集绘制、纹理预载和资源生命周期。
- `lib/pages/tile_quest/widgets/match_particles.dart`：复用纹理 atlas 和场景时钟的粒子消除。
- `lib/pages/user_info/widgets/tile_quest_entry/{index,style}.dart`。
- `test/pages/tile_quest/{core,persistence,layout,entry,evaluator}_test.dart`。
- `test/pages/tile_quest/{compact_geometry,scene_layout,motion_regression,board_backing}_test.dart`。
- `test/pages/tile_quest/{fresh_entry,irregular_levels,irregular_layout_preview,stacked_reserve,stacked_reserve_layout}_test.dart`。
- `test/pages/tile_quest/{audio_feedback,feedback_timing,entrance_shuffle_motion}_test.dart`：音频资产、声池、视觉时序及全局动效回归。
- `test/pages/tile_quest/tutorial_scale_test.dart`：教学双层半牌遮挡、命中、三色图案及各关等大验收。
- `test/pages/tile_quest/tutorial_controls_test.dart`：第一关无工具/备用区域、第二关恢复显示及真实通关/重置切换验收。
- `test/pages/tile_quest/{match_particles,shuffle_polish}_test.dart`：粒子像素与时序、正圆轨迹、洗牌圈数、速度连续和原尺寸渐变换面验收。
- `test/pages/tile_quest/{canvas_perf,insertion_timeline,tile_surface}_test.dart`：固定组件/渲染节点、语义命中、位置/速度连续及立体牌像素验收。
- `test/pages/tile_quest/{shuffle_rendering,shuffle_textures}_test.dart`：402/528 张牌的固定组件树、图集与直接绘制像素对比、图片缓存复用、增量加载与异步释放。
- `test/pages/tile_quest/{state_lookup,work_service_isolate}_test.dart`：不可变快照索引、真实 isolate 洗牌、Undo 及损坏存档校验。
- `test/pages/tile_quest/action_fuzz_test.dart`：真实规则随机混合操作、库存守恒、重复点击、堆顶及存档恢复压力回归。
- `test/pages/tile_quest/rapid_interaction_test.dart`：300 次同帧真实控制器事务、飞行时点下层、工具交错、换局、尺寸变换及长帧追赶。
- `test/pages/tile_quest/interaction_races_test.dart`：慢存储、异步计算退出、重复重置、系统生命周期与弹层、旧版本输入/反馈及胜利按钮竞态。
- `test/pages/tile_quest/visual_motion_preview_test.dart`：可选真实 Flutter 动图导出，400 张棋盘牌运动、持有牌不动及终点验收；通过 `--dart-define=TILE_QUEST_EXPORT_MOTION=true` 显式启用；普通回归还对真实牌面逐帧检查屏幕变换两轴均未缩放或压窄、同尺寸换面及持有牌不动。
- `test/pages/tile_quest/{expert_barrier,type_allocator,shuffle_pressure}_test.dart`：严格门槛、分阶段分配与洗牌后压力回归。
- `tool/tile_quest_evaluate.dart`、`tool/tile_quest/{evaluator.dart,sample_evaluation.json}`。
- `tool/tile_quest/{tools_evaluator.dart,tool_evaluation.json}`：可复现的真实引擎带道具策略与当前40局记录。
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

- 本次强制道具规则后的游戏模块回归：**284项通过，1项可选动图导出跳过**。`fvm dart analyze` 检查游戏源码、测试、帧耗时入口及两套难度评估工具：无问题。正式 Android profile APK 已构建成功；本次未重新运行全项目测试或 iOS 构建，旧轮次结果不作为本次验证。
- 本轮补充 40 个种子、3,840 次混合规则动作、901 次重复点击和 360 次真实 JSON 存档恢复检查；另覆盖 300 次同帧真实控制器动作、工具密集交错、10 分钟长帧追赶、旋转屏幕、异步计算期间退出和切会话、重复弹窗/确认、慢存档、弹层前后台及旧牌面回调，相关回归均通过。未发现上述覆盖范围内的库存/道具守恒或呈现队列异常，不将有限测试视为所有操作组合的绝对保证。
- 教学与统一尺寸验收覆盖两层各 9 张、三种图案、仅竖直半牌偏移、大行列间距、下层半张可见但不可点，以及 8 种视口下第一关与第二关全部难度/多 seed 的同边长与边界；已消牌不会触发缩放。
- 随机布局与阶段测试检查轮廓互异、逐层多簇、开局完整三同、前后段类型和压力变化、普通区域证书、含道具完整证书、id重标及编号/空间策略。5–9级另检查零道具容量不足及单次移出真实回放；10级检查两次配额容量不足及三次配额真实回放；Undo和Shuffle均保持门槛。
- 新局测试覆盖旧胜负、主槽、备用牌、道具和撤回历史清空，从第一关重新开始，解锁和声音继承、新 seed、防止旧异步任务覆盖；道具测试覆盖两次移出、堆顶访问、列归属稳定、归还、Undo、洗牌、v1/v2 配额迁移及严格库存校验。
- 声音与动效测试覆盖全部牌屏外入场、两关重播、正圆完整 3 圈以上、所有牌半径一致且横纵直径相同、交界速度连续、逐牌原尺寸渐变换图、真实纹理碎粒渐散、被遮挡牌参与且无静态牌背残留、持有牌不动、动效输入锁，以及真实页面的三消/胜负视觉时点。声音池测试覆盖 PCM、固定声部重叠及预载/停止/销毁竞态；预载超时和 10 秒长帧不会阻塞或补播过期音效。
- 界面验证保留小屏、刘海 SafeArea、短屏横屏、平板、法语/中文大字体、命中坐标、备用区顺序、等大正方形和两批飞行动画。预览测试导出教学关、六个不同 seed 的真实随机布局、难度 10 和两次 Remove 后的实际 PNG；快速连点、三消插入、撤回及牌缝遮挡继续由回归覆盖。
- 当前 Flutter 3.44.2 的 `flutter analyze` 在中文项目根路径中曾出现 LSP JSON 截断；原项目 `fvm dart analyze` 可作为检查方式。
- 全项目历史上有漫画封面布局及登录语种切换测试失败，iOS 模拟器历史上受 DKPhotoGallery 的 SwiftCompile 错误影响；本模块不改动这些业务、原生工程或依赖。最终全量检查情况以本轮实际运行结果为准。小米 17 的独立 profile 包及单 CPU 亲和压力样本见 `tool/tile_quest_profile_results.json`，复现入口为 `tool/tile_quest_profile.sh`；这些样本不能替代真实传音机型的验收。

## 本次参考材质与真机验收

强制道具规则后的小米17独立profile包对难度8/9/10（402/456/528牌）分别测试洗牌与60次、间隔40ms连续点击；再将基准自身的51个线程绑定CPU0重复六个场景，共2606个记录帧。12个场景均完成视觉事务，构建或栅格耗时超过16.67ms的记录帧为0；常规最大14.084ms，单CPU最大6.885ms。逐阶段p50/p95/max、完整源码与入口指纹见 `tool/tile_quest_profile_results.json`，此前结果保留为历史记录。采样副本的全部游戏Dart源码和15张PNG与工作区逐字节一致。这测量线程预算，不等于所有显示呈现期限；未测试实体传音手机，也不包含其他正式页面、音频和GetStorage全盒磁盘刷新。

正式Android profile APK：`build/tile_quest/tile-quest-profile.apk`；实际绘制预览：`build/tile_quest/raised_tiles.png`。更新静态材质或PNG类型表后须完整重启调试进程或安装新APK，热重载会保留已有静态材质和图集。

用户已授权更新手机正式TopRead：本轮强制道具版APK已安装并保留应用数据，冷启动进入 `/tile_quest`，当前停留在全新教学关。安装后再次读取设备APK的SHA-256，与 `build/tile_quest/tile-quest-profile.apk` 完全一致；校验记录为 `build/tile_quest/install_receipt.json`，现场画面为 `build/tile_quest/formal_app_current.png`。帧耗时仍来自独立基准，不把正式App的画面核对视作额外帧采样。
