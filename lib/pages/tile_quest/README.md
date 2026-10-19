# Tile Quest

个人中心 → Tile Quest。游戏完全离线，无登录、收费或广告依赖。

## 当前行为与配置

`game/config.dart` 中的 `TileQuestConfig.gameDifficulty` 控制**第二关**难度，范围 1–10，**默认 8**。第一关是独立的简单教学关，不使用第二关的难度规模表。

每次重新进入游戏页面或确认 Restart，都从简单的第一关开始，生成新的 seed、挑战 id 和完整棋盘，仅保留已解锁进度和声音设置。主槽、备用牌、道具余量、Undo 历史、胜负和计时全部重新开始；必须再次通关第一关，再通过 Next 进入第二关。后台与前台切换仍保留当前页面这一局。

第一关仅显示教学棋盘与七格主槽，不显示 Undo/Shuffle/Remove、备用槽、备用牌或结果中的工具统计/撤回按钮；这些界面只在第二关显示。隐藏界面不改变共享的规则引擎、两关相同的棋盘单位尺寸或主槽坐标。

第二关 Remove 当前每局可用 **2 次**，每次移出主槽最前面的至多 3 张，备用容量为 6 张。普通竖屏的备用区位于七格主槽**上方**，短高竖屏改为托盘下方与道具同行，横屏位于右侧操作栏；均使用 **3 列叠放**：再次移出会叠在已有牌上，只能点击每列最上方的牌归还，其他列不会横向补位。备用格、备用牌和正常入槽牌共用高宽比1.08，备用区尺寸独立保持紧凑，飞行终点统一读取场景坐标表。调整 `remove_uses_per_challenge` 时，容量、堆叠高度和道具初始化同步推导；**该配额也是难度 10 能否通关的规则条件**，不是单纯的界面测试参数。Undo、Shuffle 各 1 次，Undo 不退还已经消耗的道具。

## 教学关与统一尺寸

`game/tutorial_layout.dart` 固定生成 **两层 3×3，共 18 张、3 种图案**。每局按 seed 从草莓/西瓜、手套/雪花、叶片三组各选一种并打散，避免固定使用同色的太阳、月亮和星星；每层各图案 3 张，全局各图案 6 张。横向中心间距 `1.5`、纵向 `1.75` 个逻辑单位：相邻牌组横向空隙由1缩为0.5，纵向由0.5缩为0.25，精确减半；上层与对应下层的 x 完全相同，**只向下偏移半张牌（y + 0.5）**，下层上半张可见但仍被上层阻挡。开局恰有 9 张上层牌可点，有无需道具的完整合法解。

`widgets/scene_layout.dart` 根据安全区域内的实际可用宽高计算网格尺寸。普通竖屏保留6×9参考包络；短高竖屏将互不遮挡的辅助牌岛整体移近主阵，区域间隔为0.18格，使用6×7.36参考包络与全部原始牌矩形共同适配，避免把空的九行框压进收起窗口。旧七列存档、未知分区或跨区相交的手写牌阵按真实边界保守缩放。已消除牌继续参与原始包络，消牌时不放大、缩小或平移。同一视口下教学与挑战使用统一网格比例。第二关同层相邻牌的逻辑间隙为 **0**，实体直边相接；素材圆角自然保留透明度，真实下层有牌时可透见下层，无牌时应显示游戏背景，不能补画人工挡板、封缝圆盘或虚构底层。

`style.dart` 的 `board_tile_width_extra = 2` 控制相对48px参考牌宽的加宽量；原生图集宽200、高216，牌体高宽比1.08，图标保持原比例。最终尺寸由窗口实际约束决定，不能通过全局缩小图标、越界或同层相邻牌重叠来适配。

七格主槽按父容器扣除左右6px和格间3px后均分，普通手机近乎铺满父容器；每槽最大宽度由 `tray_tile_max_width = 60` 控制，达到上限后七格整体居中。备用槽按独立缩放和上限计算，工具区保留56px触摸高度。主牌、主槽和备用区之间以相同宽高比平滑缩放，连续重定向继承位置与尺寸速度。

## 第二关的模板布局与难度阶段

`game/layout_patterns.dart` 先生成完整的规则槽位模板，再分配图案。seed共同决定多个分散深度中心、非对称上层、贯穿所有层的真实槽道/孔洞、两侧辅助列、镜像及图案；中央仍以六列五行网格为边界，但不再固定为中心收缩金字塔或完整矩形底座。半格相位分别作用于x/y，同层不意外重叠。真实空格穿过全部普通层，容量链也不得填平通道。

`core`表示种子生成的局部深度盆地，不再固定中央3×3。上下 `side_top` / `side_bottom` 为真实交错砖墙：整格的n张宽排与半格错位的n−1张窄排交替，窄排每张牌覆盖两张真实下牌，宽排内部牌也覆盖两张窄排下牌；只有外侧肩部在交替层存在单张支撑，不再形成每个位置都一对一重叠的孤立竖柱。辅助牌区与普通主阵共用同一个图案供给池，层数与库存直接来自实际几何。强制道具依赖放入主阵底层的随机安全锚点，开局被普通牌真实矩形遮盖，不再作为唯一固定边缘牌堆单独暴露。

普通开局真实可点12–24张且为3的倍数。`game/type_allocator.dart`独立决定开场三同、类型供给、槽位压力和闭合延迟。连续稀有牌窗口采用有界六步前瞻并延伸完整强制窗口，以库存/持有计数等价类合并分支，避免分叉布局的第四张稀有牌导致分配耗尽。几何模板与压力参数分开，难度1–10仍由图案数、依赖深度、压力、延迟和道具容量共同构成。

`game/tile_palette.dart` 是十五个真实图案的唯一清单：mushroom、carrot、watermelon、lemon、shovel、glove、leaf、strawberry、milk_bottle、scissors、hay、yarn、star、grapes、snowflake。规则类型与 PNG 一一对应，不能通过取余把不同类型绘成相同图标。

难度 6–8 分别在 16/20/24 层真实遮挡链中保留一组仅三张的稀有配对，先持有两张、最后一张深埋；除去四种独立门牌与这一种稀有图案，其余 7/8/9 种图案均可参与普通匹配，开场图案仍参与深层，避免减少图案时意外降低难度。难度 8 更早取到第二张、更晚闭合。难度 9 使用更深的 40 层依赖与两组稀有配对，中段持续占四槽，并保留经过独立规则重放的完整含道具证书。难度 10 则使用下述严格容量门槛。

下表只描述第二关；第一关始终为上述 18 张教学关。

| 第二关难度 | 方块数 | 图案种类 | 普通牌阵层数 |
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
- `game/geometry.dart` 缓存实际矩形的跨层覆盖关系；重叠面积/下层面积超过0.0001才构成遮挡，接边与同层均不互挡，每次移牌立即刷新可点击状态。
- `game/engine.dart` 使用同步原子动作和不可变快照，先三消再检查第七格失败。Undo 恢复完整前态并保留已花费道具，不能通过撤回来增加可用容量。
- 普通 Shuffle 保持几何、图案总库存、主槽及备用牌，构造并验证完整后续解；与初始生成共享 `TileQuestTypeAllocator` 的后段分配逻辑，避免把所有剩余图案排成连续三同而降低难度。预算为 250 ms，失败不扣次、不改状态。

初始解序列仅供验证和开发测试，普通游戏不会读取它来修改牌面或控制胜负。偏离构造解后可能形成真实的不可解局面，不能把“开局有解”理解为任意点击顺序都能通关。

## 难度 5–9 的强制道具门槛

难度 **5（含）至9** 均包含固定的12张依赖核心：七张门牌按 A/B/C/A/B/C/D 顺序逐张遮挡，五张伙伴牌 A/B/C/D/D 全在最后一张门牌之后。四种图案在整局各只有这三张，普通区域不能提供额外配对。必须先取走七张尚不能三消的门牌，才可触及任何补齐牌；主槽安全容量只有六张，所以**不用道具在任何点击顺序下均无法通关**。这依赖真实初始牌面与遮挡，不在最后一步临时阻止胜利。

一次 Remove 足够：取 A/B/C 后移到三个备用列，再取 A/B/C/D，逐列归还先前的 A、B、C 并取对应伙伴闭合，最后两张 D 清槽。构造器独立重放完整路径，证书中的 `-1` 表示 Remove，重复的牌 id 表示按堆顶归还备用牌。普通区域、门牌、备用区均使用同一个实际引擎结算。

Shuffle 不把伙伴洗到门前；5–8级未动核心时可在普通区域构造真实续解，9级固定原有匹配和稀有键关系，仅在证明续解后执行等库存的整类图案交换。无法在统一250ms预算内证明安全续解时原子拒绝、不扣次数。Undo不退还已用道具。存档必须包含当前难度的合法门结构；旧版5–9级无门棋盘会安全重开并保留经过独立检查的声音、解锁进度和seed。

`mandatory_tool_test.dart` 覆盖零道具失败、单次移出通关、每步JSON往返、备用列、Undo、Shuffle以及损坏与旧版快照拒绝。图案总数、牌数及普通牌阵层数保持上表；容量依赖占用独立低层编号，普通层在其上方，不通过额外y位移伪造高度。

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

界面采用统一棋盘、主槽和备用区坐标映射。顶部不显示剩余方块数量。正常牌体直接使用用户原图 `assets/img/tile_quest/lattice.png`（500×487），保留完整高光、倒角与底部厚度，将牌体展开到1.08高宽比，使顶部瓷面接近正方形；图标保持原比例，牌体不填入图集的阴影留白。素材缺失时才使用一次烘焙的向量回退。

十五个卡通图标从用户 `assets/img/tile_quest/1.png` 按原始RGB和alpha提取，保留描边、抗锯齿、剪刀/铲柄镂空，去除游离透明碎点；源文件保持不动。切图位于 `assets/img/tile_quest/icons/`，均为256px透明画布、主体216px，通过 `quest_tile_asset_path` 统一解析。图标显示在瓷面中心，实际主体约占牌宽67.5%；图标接触影、向右下的柔影，以及整牌层间软影均只在准备共享图集时合成。240×256px绘制格含四边各20px阴影留白，逻辑牌200×216px，规则遮挡与点击位置保持一致；静态、飞牌、洗牌和三消共用同一图集。交互帧只批量采样纹理，没有逐牌实时模糊。皮肤与图标共用Flutter解码缓存，场景持有独立引用并完整处理迟到回调、换bundle、失败恢复和退出释放。

棋盘保留一个静态画布，只将真实牌面按层序写入同一缓冲区，仅一次drawRawAtlas。图集仅含各图案的普通/遮挡版本，不包含人工封缝纹理；生产绘制没有独立底板或圆盘挡板，最后一层的共享圆角应透出真实背景。静态完全同矩形遮盖时只画最高牌；部分覆盖牌保留，按压时额外保留直接下层，移除或Undo后立即重建可见牌。逻辑frames、命中、语义、遮挡关系仍完整，完全同位的深层牌不重复叠加投影；入场/飞牌/洗牌不做这项静态剔除。入场、飞牌、洗牌与三消共用动态画布。每张牌从点击起连续飞行，解析Hermite曲线继承当前位置与一阶速度；连续插入不在卡槽上方悬停，三消尾迹独立并行。视效使用规则事务结果，胜负提示等待最新视觉事务完成。

揭开下层牌时，规则立即允许点击，遮罩沿共享时钟在220ms内连续退去；快速连点起飞、Undo反向遮挡、备用堆、旋屏与洗牌沿用当前明暗值和速度，不闪回端点。过渡仅在现有有序图集批次对变化牌叠加两种纹理，结束后恢复静态单精灵；冷启动或图集故障回退也支持连续权重，不引入逐牌Widget、saveLayer或实时模糊。底板原文件保留，在一次烘焙中提升暗部黑位，奶油高光及图案饱和度保持；整牌软影与被遮挡边缘的环境影同步减轻，避免暗边叠加。

每个新挑战播放约 900 ms 的错落落牌入场，所有未移除的牌从屏幕上沿外落到原始坐标，低层先落定、高层随后覆盖；两关、重置和重新进入均会播放。Shuffle 用 2100 ms 把全部剩余棋盘牌（含被遮挡牌）平滑聚拢为一个正圆，连续转动 3.8 圈，再减速分散回原位；旋转阶段所有牌共用同一个固定像素半径与圆心，横纵等比，不再使用逐牌环带或半径起伏，所有牌全程保持棋盘上的正常尺寸（横纵缩放均为 1），不再缩到 62% 或压窄翻转；每张牌仍轻摆，并以同尺寸旧底板和新图案渐变叠加换面，阶段交界的位置和速度连续，主槽和备用牌保持不动。入场与全局洗牌期间锁定棋盘、备用牌与道具，普通飞牌仍支持快速连续点击。洗牌使用单个 `CustomPainter` 和一次 `drawRawAtlas` 绘制全部棋盘牌，逐事务缓存牌序、坐标和三角函数，复用纹理与变换缓冲区；不创建逐牌隐藏组件，也不使用逐牌 `saveLayer`。场景提前加载与静态卡片共用解码缓存的纹理，生成含正常/遮挡两种牌面的图集，退出页面释放自有图片、图集和监听；图集未就绪时用同一皮肤与图标回退绘制。待开始的洗牌排除已经由飞行层绘制的牌，保证撤回衔接期间同一牌只出现一次。视觉动画结束后继续使用同一份规则状态及几何坐标，动效不改变合法操作或道具结算。

游戏背景直接使用 `assets/img/tile_quest/background.png`，通过独立静态 RepaintBoundary 加载并裁切铺满，日夜主题仅叠加静态可读性渐变。三道具从用户 `2.png` 精确裁成透明纹理 `powerups/{undo,shuffle,remove}.png`，保留边缘与内部镂空，按128px共享缓存键解码；名称、可用状态与次数由实时规则显示，不烘焙进图片。使用 `tool/tile_quest/extract_powerups.py` 可重建切图，提取区域与指纹见 `powerups/extract_powerups.json`。原始1.png和2.png不打包。旧素材目录已清除，仍用到的入口图标迁移至 `tile_quest/app_icon.png`。

横屏使用独立宽画布（最大1280），44px紧凑顶栏及右侧自适应操作区；主阵/核心共享平移，独立辅助岛转为两列，基准9.5×6格，图标本身不旋转。全部静态牌、飞牌、洗牌、命中与调试框共用同一映射，逐对验证难度1–10、四组种子的重叠面积比例保持不变。已移除牌仍参与边界计算，连续消除不跳动；未知分区、非方形辅助牌或跨区重叠的旧存档保守回退原坐标缩放。844×390可用区域牌宽约48.5px，720×320约38px；实际值按安全区域宽高共同计算。七格槽保持自适应与最大宽度，飞牌入槽连续缩放。短屏、大字体、长翻译的道具与备用区说明均限制在实际控件边界内。

短高竖屏按真实可用高度启用44px紧凑顶栏，七格托盘继续按父级宽度自适应，备用槽和三个道具同行；备用槽居中，不显示会被挤断的可见说明，保留完整无障碍标签。工具按钮在窄宽度下改为图标、名称与次数竖排。iPhone Duo收起时实际Flutter窗口为466×678，安全区为右84、下34，游戏内容为 **382×644**，该约束下主牌约 **57px**，三个道具触摸区域均不小于44px；展开已覆盖951×669横向窗口与669×951纵向窗口。这些是布局尺寸，不是帧率或音频延迟测量。

`widgets/playfield.dart` 按窗口的真实displayFeatures及非对称SafeArea计算场景，不把cutout当作折痕。足够宽的左右子屏分别放置主牌阵和备用区、七格槽、三个道具，交互矩形均不跨折痕；窄子屏或上下分屏安全退化到较大的完整区域，完整气氛背景仍铺满窗口。展开横屏先保留可读主牌尺寸，再分配操作栏宽度，Duo真实867×635安全区内七槽单格约45.26px，半折叠约44.21px；普通窄横屏受真实空间约束。暂停、结果、错误与重开确认面板使用单个完整子屏。展开、收起及半折叠只改变约束和坐标映射，保持同一游戏子树、牌局与飞牌状态，不重开或重新生成关卡；飞牌、Undo、Remove、Shuffle途中切换姿态的存档和最终落点均有回归覆盖。未知或相交牌岛不做可能改变遮挡的重排。Duo三态真实素材预览可通过 `--dart-define=TILE_QUEST_EXPORT_DUO=true` 运行预览测试生成。

已适配日夜主题、四语翻译、CJK/拉丁文字、SafeArea、短屏横屏和平板。四语备用区提示均说明只可归还顶层牌。声音使用 7 段原创合成 PCM WAV：木片点击、泡泡与上扬三消、移出/撤回、入场柔风、洗牌沙沙、胜利短句及柔和失败下行音；不复用聊天铃声。七段共 246828 Bytes，均为 22050 Hz 单声道 16-bit，首尾平滑淡入淡出，详见 `assets/audio/tile_quest/README.md`。

`TileQuestFeedbackService.play(event)` 保留可注入接口，可选 `TileQuestFeedbackLifecycle` 提供预载、停止和销毁。音频与关卡生成并行预载，首次显示最多等待 240 ms；11 个自有声部允许点击及三消重叠，逐声部队列和取消 token 避免静音、后台、切换挑战或页面销毁后的迟到播放。三消的三张牌各分解为 144 个保留完整立体牌颜色的碎粒，从原图位置错落散开、轻微旋转并在 480 ms 内淡出；缓冲区和随机参数仅创建一次，以三次 atlas 绘制复用同一场景时钟，无额外 ticker；粒子缓动及透明度使用解析多项式，避免逐粒贝塞尔求根与幂运算。三消在粒子分解开始时发声，入场与洗牌各播放一次整段声音，胜负音跟随对应视觉事务结束。长时间无帧后的追赶会跳过过期音效，避免回前台同帧集中补播。音频失败不阻断规则或存档；Android 不请求独占焦点。

iOS短PCM音效使用 `services/ios_audio_voice.dart` 与 `ios/Runner/tile_quest_audio.swift` 的 `AVAudioEngine` 固定声部池。WAV仅在预载阶段解码一次为可复用的Float32 PCM；音频图固定连接到Mixer，已使用的节点预先进入playing状态，空闲时不产生音频数据。连续点击只调用一次原生restart，以 `scheduleBuffer(.interrupts)` 投递内存缓冲，不执行AVPlayer异步seek、AVAudioPlayer播放位置重置、节点stop/play或引擎重启。各类声音独立等待自身预载；静音、后台、中断及销毁才停止自有节点，恢复只预热、不补播过期声音。会话使用ambient混音并尊重静音开关，不在每次点击时切换共享会话。真机探针 `tool/tile_quest_ios_audio_probe.dart` 记录平台调用往返耗时与失败；这些指标不等于扬声器声学输出延迟。

2026-10-19 在同一台 iPhone 16 Pro Max 的 profile 模式运行上述探针：20次40ms间隔点击、2次并发三消和1次道具，共23次restart。AVAudioPlayer版本的平台往返p50/p95/最大值为42.044/89.372/107.651ms；固定AVAudioEngine版本为0.489/0.750/0.956ms。新版本全部44次prepare/restart/stop/dispose调用成功。这组数据验证平台调用路径消除了原有数十毫秒阻塞，未测量触摸到扬声器实际发声的声学延迟。

## 难度评估与数据边界

```sh
fvm dart run tool/tile_quest_evaluate.dart 30 3
```

当前配置的标准评估见 `tool/tile_quest/sample_evaluation.json`：30个seed×11种策略×10档，共3300次无道具模拟，5–10级全部未通关。当前9级带道具策略基准与独立样本均为0/40，见 `tool/tile_quest/tool_evaluation.json` 与 `tool/tile_quest/tool_evaluation_heldout.json`；该程序能够查看隐藏图案，样本不是人类胜率；独立构造见证仍能真实通关。更改容量门槛后，旧配置的通关率不适用于当前棋盘；报告以实际记录的参数、seed和配置为准。标准策略均不读取证书、不使用道具。5–10级的零道具无解来自静态门槛，并不依赖有限策略的失败样本。

难度9保留40层真实依赖、两组稀有配对和四槽持续占用；洗牌固定所有匹配与稀有键关系。仅在有界搜索验证当前牌面的续解时接受偏离证书后的洗牌，否则不改牌、不扣次。完整合法通关见证包含一次移出，但不是正常玩家的提示或自动改牌来源。

```sh
fvm dart run tool/tile_quest/tools_evaluator.dart 40 9 baseline
```

机器人样本通关率不能等同于人类通关率，也不能证明9级只有理论可能通过。牌数、层数、普通图案与隐藏配对压力随难度递增；5级开始另有强制道具门槛。10级默认配额必败则有独立数学容量证明。

## 文件清单

新增：

- `game/geometry_style.dart`：真实面积遮挡阈值与区域标识校验。
- `widgets/layout_debug.dart`：Debug专用的区域、层级、碰撞框与数量开关。
- `test/pages/tile_quest/{structured_layout,region_geometry,layout_debug}_test.dart`：规则分区、多峰槽道、半格核心、几何阈值、元数据往返与不拦截输入的调试验收。

- `lib/pages/tile_quest/{index,logic,style}.dart`、本说明。
- `lib/pages/tile_quest/game/{config,models,geometry,generator,layout_patterns,validator,engine}.dart`。
- `lib/pages/tile_quest/game/tutorial_layout.dart`：固定双层 3×3 教学关。
- `lib/pages/tile_quest/game/type_allocator.dart`：生成与 Shuffle 共用的分阶段图案分配。
- `lib/pages/tile_quest/game/expert_barrier.dart`：5–9级强制单次移出与10级三次移出门槛、静态依赖及含道具见证。
- `lib/pages/tile_quest/services/{save_service,work_service,feedback_service,audio_voice,ios_audio_voice}.dart`，以及 `ios/Runner/tile_quest_audio.swift`：存档、异步规则工作与平台音频声部。
- `lib/pages/tile_quest/widgets/{atmosphere,tile_card,quest_scene,quest_controls,quest_result,quest_text,session_pause}.dart`。
- `tool/tile_quest/extract_icons.py`：从用户原始图集裁出十五个透明图标，保持原图颜色与轮廓。
- `lib/pages/tile_quest/widgets/{scene_layout,slot_wells,scene_motion,compact_board_layout,landscape_board_layout,playfield}.dart`：统一坐标、独立牌岛适配与安全子屏。
- `lib/pages/tile_quest/widgets/board_motion.dart`：入场及洗牌的独立几何动效。
- `lib/pages/tile_quest/widgets/insertion_timeline.dart`：位置及速度连续的飞行、槽位让位与并行三消尾迹调度。
- `lib/pages/tile_quest/widgets/{board_canvas,motion_canvas,tile_batch,tile_frame}.dart`：实际绘制、圆角命中、语义及共享图集批次。
- `lib/pages/tile_quest/widgets/{tile_surface,tile_surface_style}.dart`：与透明图标独立的立体牌皮肤。
- `lib/pages/tile_quest/widgets/{shuffle_motion,shuffle_textures}.dart`：单画布图集绘制、纹理预载和资源生命周期。
- `lib/pages/tile_quest/widgets/match_particles.dart`：复用纹理 atlas 和场景时钟的粒子消除。
- `lib/pages/user_info/widgets/tile_quest_entry/{index,style}.dart`。
- `test/pages/tile_quest/{core,persistence,layout,entry,evaluator}_test.dart`。
- `test/pages/tile_quest/{compact_geometry,scene_layout,motion_regression,board_corner_transparency,compact_window_layout}_test.dart`：真实透明圆角、短高窗口、非对称安全区、分隔子屏及折叠中飞牌恢复。
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
- `pubspec.yaml`：仅注册 `assets/img/tile_quest/` 中在用的底板、背景、入口图标、十五个透明切图和道具切图，以及原创 `assets/audio/tile_quest/`；原始整图不打包，复用项目已有依赖，未新增依赖。
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

- 当前游戏模块回归：**358项通过，3项可选图片/动图导出跳过**；游戏源码、布局与相关测试静态分析无问题。另显式启用Duo三态真实素材导出1项通过；Duo、分隔子屏和横屏专项20项通过。全项目最终1147项通过、5项可选导出跳过；静态分析0 error、13项既有warning，与上一版逐条一致。
- 本轮补充 40 个种子、3,840 次混合规则动作、901 次重复点击和 360 次真实 JSON 存档恢复检查；另覆盖 300 次同帧真实控制器动作、工具密集交错、10 分钟长帧追赶、旋转屏幕、异步计算期间退出和切会话、重复弹窗/确认、慢存档、弹层前后台及旧牌面回调，相关回归均通过。未发现上述覆盖范围内的库存/道具守恒或呈现队列异常，不将有限测试视为所有操作组合的绝对保证。
- 教学与统一尺寸验收覆盖两层各 9 张、三种图案、仅竖直半牌偏移、大行列间距、下层半张可见但不可点，以及 8 种视口下第一关与第二关全部难度/多 seed 的同边长与边界；已消牌不会触发缩放。
- 随机布局与阶段测试检查轮廓互异、逐层多簇、开局完整三同、前后段类型和压力变化、普通区域证书、含道具完整证书、id重标及编号/空间策略。5–9级另检查零道具容量不足及单次移出真实回放；10级检查两次配额容量不足及三次配额真实回放；Undo和Shuffle均保持门槛。
- 新局测试覆盖旧胜负、主槽、备用牌、道具和撤回历史清空，从第一关重新开始，解锁和声音继承、新 seed、防止旧异步任务覆盖；道具测试覆盖两次移出、堆顶访问、列归属稳定、归还、Undo、洗牌、v1/v2 配额迁移及严格库存校验。
- 声音与动效测试覆盖全部牌屏外入场、两关重播、正圆完整 3 圈以上、所有牌半径一致且横纵直径相同、交界速度连续、逐牌原尺寸渐变换图、真实纹理碎粒渐散、被遮挡牌参与且无静态牌背残留、持有牌不动、动效输入锁，以及真实页面的三消/胜负视觉时点。声音池测试覆盖 PCM、固定声部重叠、iOS原子重播以及预载/停止/销毁竞态；预载超时和 10 秒长帧不会阻塞或补播过期音效。
- 界面验证保留小屏、刘海 SafeArea、短屏横屏、平板、法语/中文大字体、命中坐标、备用区顺序、统一加高比例与大小牌连续缩放和两批飞行动画。预览测试导出教学关、六个不同 seed 的真实随机布局、难度 10 和两次 Remove 后的实际 PNG；快速连点、三消插入、撤回及最后一层圆角透出真实背景继续由回归覆盖。Duo专项使用完整466×678窗口与右84/下34非对称安全区，并检查纵向/横向分隔、非对称子屏选择、飞行中折叠及展开恢复时状态和落槽坐标不变。
- 当前 Flutter 3.44.2 的 `flutter analyze` 在中文项目根路径中曾出现 LSP JSON 截断；原项目 `fvm dart analyze` 可作为检查方式。
- 全项目历史测试或原生编译限制均不代表本轮结果；本轮另有全项目窗口适配和iOS原生音频变更，最终全量检查情况以实际执行记录为准。历史1.2.2+21、+22性能报告分别保存在 `tool/tile_quest/evaluation_history/v21_performance_results.json`、`v22_performance_results.json`；8791帧为+22历史结果。+23当前源码已重新采集，报告见 `tool/tile_quest_profile_results.json`：常规/单核各12场景，合计4428帧；常规最大build 7.611ms、raster 10.807ms，单核最大build 7.496ms、raster 8.15ms；两轮线程耗时超过16.67ms共0帧，全部动作接受、动画结算。各场景系统报告刷新率含60/120Hz，逐场原值保留，不宣称稳定120fps。原始日志已归档为 `evaluation_history/v23_android_profile_*.log`。这不是实体传音测试，也不能证明120Hz逐帧无丢帧。iPhone 16 Pro Max profile同一音频探针的23次播放调用往返中位0.489ms、P95 0.750ms、最大0.956ms，见 `tool/tile_quest/ios_audio_probe_results.json`；该指标不等于扬声器声学输出延迟。复现入口为 `tool/tile_quest_profile.sh` 与 `tool/tile_quest_ios_audio_probe.dart`。

## 开发调试

Debug构建显示独立的Layout debug开关；开启后以真实场景矩形绘制碰撞框、layer和region_id，并显示当前可点/被遮挡数量、各层剩余数量与seed。调试绘制使用IgnorePointer，不拦截牌面点击；关闭时不绘制调试矩形；紧凑顶栏没有第二行空位时，开关只放到未占用的棋盘边角，没有安全空位则不创建，不能挡住重开键或方块。Profile/Release不创建调试组件。

```sh
fvm flutter run --dart-define=TILE_QUEST_LAYOUT_DEBUG=true --dart-define=TILE_QUEST_SEED=12345
```

固定seed只在Debug生效，允许重新进入或Restart复现同一牌阵；未设置时仍每次产生新局。region_id随copy与JSON完整保存，旧存档缺失时默认为main；grid_row/grid_column与offset_x/offset_y从实际坐标派生，避免存在第二套坐标真源。

## 前一轮背景、道具与横屏验收（1.2.2+20历史记录）

该历史轮次游戏模块 **324项通过，2项可选图片/动图导出跳过**；另显式运行最终素材导出3项通过，精确切图Python测试4项通过，源码、测试、入口及性能工具静态分析无问题。Android profile ARM64正式包版本为1.2.2+20，路径 `build/tile_quest/tile-quest-profile.apk`。

小米17对难度8/9/10（402/456/528牌）的横竖屏分别完成洗牌和60次、间隔40ms连点，再将基准自身51个线程绑定CPU0重复，共24场景、4429个记录帧。操作全部被实际引擎接受，所有呈现事务完成。构建或栅格线程耗时超过16.67ms的记录帧为0，常规最大11.893ms，单CPU最大15.366ms。横屏实际安全区域771.08×313.23时牌宽36.94px，竖屏375.38×755.08时46.51px；测试设备报告竖屏120Hz、横屏60Hz。源码、基准入口及用户素材副本逐字节一致；p50/p95/max、指纹及历史样本见 `tool/tile_quest_profile_results.json`。线程预算统计不等于所有显示期限；没有实体传音机型测试，其他正式页面、音频与GetStorage全盒磁盘刷新不在这批样本范围内。

真实场景导出：`build/tile_quest/new_assets_portrait.png`、`build/tile_quest/new_assets_landscape.png`。正式包已保留数据更新、冷启动并在第二关核验横竖屏，新版现场截图为 `build/tile_quest/formal_app_new_background_portrait.png` 与 `build/tile_quest/formal_app_new_background_landscape.png`；原系统旋转设置已恢复。设备验证记录见 `build/tile_quest/install_receipt.json`；热重载不能证明图集与素材已更新。

牌面图标可执行 `tool/tile_quest/extract_icons.py --preview /tmp/tile_icons.png` 重建，三道具可执行 `tool/tile_quest/extract_powerups.py` 重建，均依赖Pillow/numpy。源图、提取区域、alpha清理及输出SHA-256分别记录在 `icons/extract_icons.json` 和 `powerups/extract_powerups.json`。原始1.png、2.png、lattice.png与background.png保持不变。当前 `board_atlas_batch_test.dart` 验证48层真实牌只提交一次atlas、牌面层序及按压坐标，不再包含人工封缝；纹理测试覆盖跨行边界、迟到释放、换bundle与失败恢复。

## 历史多峰槽道、揭牌与亮底验收（1.2.2+21）

以下记录只适用于1.2.2+21源码，不能用作本版帧耗时、安装或设备验收结论。

该历史轮次模块343项回归通过，2项可选导出跳过；另显式运行4项场景/素材导出通过，源码、测试、两套难度工具及性能入口静态分析无问题。额外1000局覆盖1–10档的种子构造、3300次无道具策略模拟及难度9两组各40局带道具策略；历史评估完整归档。当时的规则指纹与评估一致，容量证明未以机器人失败样本代替。

揭牌Flutter实绘：0ms下牌亮度与点击前相同，50/110/220ms单调增加；110ms立即点击下牌，飞行0ms继承相同亮度，50ms继续变亮。PNG与采样值在 `build/tile_quest/reveal_*.png`、`reveal_luminance.json`、`reveal_flight_luminance.json`。六组真实牌阵预览在 `build/tile_quest/organic_layout_seed_*.png`，包含全层空洞/槽道与散布上层。

小米17实际横竖屏、常规及单CPU亲和测试共24场景、7846记录帧。洗牌和60次40ms快速点击均由实际引擎接受，呈现队列全部收敛；构建/栅格线程超过16.67ms的记录帧为0，常规最大14.163ms，单CPU最大13.236ms。两种方向均报告120Hz；16.67ms预算统计不等于120Hz无丢帧保证，也不代替实体传音机型测试。场景包含用户背景/工具PNG与安全区；正式其他页面、原生音频和GetStorage全盒磁盘刷新不在独立帧样本范围内。完整数据、指纹及历史见 `tool/tile_quest_profile_results.json`。

正式App 1.2.2+21已保留数据更新并冷启动，ADB按真实可点击牌分组连续点击18次、清除教学18张并赢得教学关，再进入全新第二关。实际横竖屏截图：`build/tile_quest/formal_v21_tutorial.png`、`formal_v21_organic_portrait.png`、`formal_v21_organic_landscape.png`。安装后的APK SHA与输出文件一致，原系统旋转设置已恢复，核验见 `build/tile_quest/install_receipt.json`。
