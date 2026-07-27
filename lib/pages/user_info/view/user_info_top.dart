import 'dart:io';
import 'dart:math';
import 'package:app/config/font_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/user_info/view/utils/upload_avatar.dart';
import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/router/router_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/pages/user_info/view/top_user_info/index.dart';
import 'package:app/stores/user_information.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/stores/device_info.dart';
import 'package:get/get.dart';
import 'login_register_button.dart';
import '../style.dart';

// TODO 用户信息顶部的视图
class UserInfoTop extends StatefulWidget {
  const UserInfoTop({super.key});

  @override
  State<UserInfoTop> createState() => _UserInfoTopState();
}

// TODO 用户信息的区域
class _UserInfoTopState extends State<UserInfoTop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final userInformation = Get.find<UserInformation>();
  final deviceInfo = Get.find<DeviceInfo>();
  bool _profileVisible = false;

  /// 当前随机头像索引，登录后固定，下拉刷新时更新。
  int _randomAvatarIndex = 0;

  /// 本地头像路径（上传中时显示本地图片）。
  String _localAvatarPath = '';

  /// 头像是否正在上传中。
  bool _isAvatarUploading = false;

  /// 重新生成随机头像索引，供外部（下拉刷新）调用。
  void refreshRandomAvatar() {
    setState(() {
      _randomAvatarIndex = Random().nextInt(10);
    });
  }

  @override
  void initState() {
    super.initState();

    /// 初始化随机头像索引。
    _randomAvatarIndex = Random().nextInt(10);

    // TODO 控制器：控制多久时间完成一次动画，单位：秒
    const int seconds = 1;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: seconds),
    )..repeat(reverse: true);

    /// repeat + reverse 实现来回循环

    // TODO 动画范围：0 到 10（px 偏移量）
    _animation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _profileVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /* TODO
   * 统一处理头像来源选择。
   *
   * [source] 表示用户选择的图片来源：
   * - [ImageSource.gallery] 从相册选择
   * - [ImageSource.camera] 打开相机拍照
   *
   * 这里先请求权限再调用 ImagePicker，避免 iOS 在权限文案缺失或首轮授权阶段出现卡死感。
   */
  Future<void> _pickAvatarImage({
    required BuildContext bottomSheetContext,
    required ImagePicker picker,
    required ImageSource source,
  }) async {
    // TODO 弹窗已由公共组件 showImageSourceSheet 关闭，此处不再 pop
    try {
      // TODO 仅相机需要手动请求权限，相册由 ImagePicker 自动处理
      if (!kIsWeb && source == ImageSource.camera) {
        final PermissionStatus status = await Permission.camera.request();
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          await showMessage(
            message: easy.tr("UserInfo.take_photo_tips_01"),
            leftButtonText: easy.tr("constant.cancel"),
            allowMaskDismiss: true,
            rightButtonText: easy.tr("UserInfo.take_photo_tips_02"),
            onRightPressed: () async {
              final opened = await openAppSettings();
              if (!opened) {
                showBottomTip(easy.tr("UserInfo.take_photo_error_02"));
              }
            },
          );
          return;
        }
      }

      final XFile? image = await picker.pickImage(source: source);
      if (image == null) {
        showBottomTip(
          easy.tr(
            source == ImageSource.camera
                ? "UserInfo.take_photo_error_01"
                : "UserInfo.choose_gallery_error_01",
          ),
        );
        return;
      }

      // TODO 立即显示本地图片，后台上传
      setState(() {
        _localAvatarPath = image.path;
        _isAvatarUploading = true;
      });

      await uploadAvatar(File(image.path));

      // TODO 上传完成，清除本地路径
      if (mounted) {
        setState(() {
          _localAvatarPath = '';
          _isAvatarUploading = false;
        });
      }
    } catch (e) {
      await showMessage(
        message: easy.tr("UserInfo.take_photo_tips_01"),
        leftButtonText: easy.tr("constant.cancel"),
        allowMaskDismiss: true,
        rightButtonText: easy.tr("UserInfo.take_photo_tips_02"),
        onRightPressed: () async {
          final opened = await openAppSettings();
          if (!opened) {
            showBottomTip(easy.tr("UserInfo.take_photo_error_02"));
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.of(context).padding;
    final double statusBarHeight = mediaPadding.top;
    final double safeLeft = mediaPadding.left;
    final double safeRight = mediaPadding.right;
    final double safeHorizontal = mediaPadding.horizontal;
    final bool isImmersiveStatusBar = statusBarHeight > 0;
    final double resolvedTopPadding =
        Style.topPadding + (isImmersiveStatusBar ? statusBarHeight : 0);
    final double contentTopPadding =
        resolvedTopPadding + Style.avatarSpacingFromLanguage;

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: -safeLeft,
                child: SizedBox(
                  width: constraints.maxWidth + safeLeft + safeRight,
                  child: Obx(() {
                    /// 读取当前主题，决定是否给背景图增加夜间遮罩。
                    final bool isDark = deviceInfo.dark.value;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/img/user_info_background_image.webp",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        /// 夜间模式下给顶部背景图叠一层轻微暗色遮罩，
                        /// 避免头部视觉过亮，影响整体夜间观感。
                        if (isDark)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Style.top_background_dark_overlay_color
                                  .withValues(
                                    alpha:
                                        Style
                                            .top_background_dark_overlay_opacity,
                                  ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SafeArea(
                    top: false,
                    left: true,
                    right: true,
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: statusBarHeight + 20,
                        bottom: Style.bottomPadding,
                      ),
                      child: Obx(() {
                        final isDark = deviceInfo.dark.value;
                        final userInfo = userInformation.userInfo.value;
                        final bool isLoggedIn =
                            userInfo != null && userInfo.id != 0;

                        Widget avatarWidget;

                        /// 已登录但无头像时，使用固定的随机头像索引。
                        final String randomAvatarName =
                            "avatar_${_randomAvatarIndex.toString().padLeft(2, '0')}";

                        /// 未登录时显示的默认 logo 头像。
                        final Widget defaultLogoWidget = Container(
                          width: Style.avatarSize,
                          height: Style.avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF8DB7FF).withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF8DB7FF).withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.34),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: isDark
                                ? Container(
                                    width: Style.avatarSize,
                                    height: Style.avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstants.nightBackgroundColor,
                                    ),
                                    alignment: Alignment.center,
                                    child: SvgIcon(
                                      key: ValueKey("default_avatar_dark_theme"),
                                      name: "logo",
                                      width: Style.logoSize,
                                      height: Style.logoSize,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    width: Style.avatarSize,
                                    height: Style.avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                    alignment: Alignment.center,
                                    child: SvgIcon(
                                      key: ValueKey("logo"),
                                      name: "logo",
                                      width: Style.logoSize,
                                      height: Style.logoSize,
                                    ),
                                  ),
                          ),
                        );

                        /// 已登录但无头像时显示的随机默认头像。
                        final Widget defaultAvatarWidget = Container(
                          width: Style.avatarSize,
                          height: Style.avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF8DB7FF).withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF8DB7FF).withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.34),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: SvgIcon(
                            key: ValueKey(randomAvatarName),
                            name: randomAvatarName,
                            width: Style.avatarSize - 10,
                            height: Style.avatarSize - 10,
                          ),
                        );

                        // TODO 上传中：显示本地图片 + 遮罩进度
                        if (_localAvatarPath.isNotEmpty) {
                          avatarWidget = Container(
                            width: Style.avatarSize + 6,
                            height: Style.avatarSize + 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF8DB7FF).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Stack(
                                children: <Widget>[
                                  Image.file(
                                    File(_localAvatarPath),
                                    width: Style.avatarSize + 6,
                                    height: Style.avatarSize + 6,
                                    fit: BoxFit.cover,
                                  ),
                                  if (_isAvatarUploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.4),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.white,
                                              backgroundColor: Colors.white.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } else if (userInfo != null && userInfo.avatarUrl.isNotEmpty) {
                          avatarWidget = Container(
                            width: Style.avatarSize + 6,
                            height: Style.avatarSize + 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF8DB7FF).withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF8DB7FF).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                                child: CachedNetworkImage(
                                imageUrl: userInfo.avatarUrl,
                                width: Style.avatarSize - 4,
                                height: Style.avatarSize - 4,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 180),
                                fadeOutDuration: const Duration(milliseconds: 120),
                                memCacheWidth: ((Style.avatarSize - 4) * MediaQuery.of(context).devicePixelRatio).toInt(),
                                placeholder: (context, url) => const SizedBox.shrink(),
                                errorWidget: (context, url, error) {
                                  return isLoggedIn
                                      ? defaultAvatarWidget
                                      : defaultLogoWidget;
                                },
                              ),
                            ),
                          );
                        } else if (isLoggedIn) {
                          /// 已登录但无头像，显示随机默认头像。
                          avatarWidget = defaultAvatarWidget;
                        } else {
                          /// 未登录，显示 logo。
                          avatarWidget = defaultLogoWidget;
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (!userInformation.isLoggedIn.value) {
                                  routerUtil(path: '/login');
                                  return;
                                }
                                final ImagePicker picker = ImagePicker();

                                // TODO 弹出图片来源选择弹窗（公共组件）
                                showImageSourceSheet(
                                  context: context,
                                  on_gallery: () => _pickAvatarImage(
                                    bottomSheetContext: context,
                                    picker: picker,
                                    source: ImageSource.gallery,
                                  ),
                                  on_camera: () => _pickAvatarImage(
                                    bottomSheetContext: context,
                                    picker: picker,
                                    source: ImageSource.camera,
                                  ),
                                );
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.98,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey<String>(
                                    userInfo?.avatarUrl.isNotEmpty == true
                                        ? userInfo!.avatarUrl
                                        : 'logo',
                                  ),
                                  child: avatarWidget,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: isLoggedIn
                                  ? Style.nicknameSpacingFromAvatar
                                  : Style.loginButtonSpacingFromAvatar,
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              opacity: _profileVisible ? 1 : 0,
                              child: isLoggedIn
                                  ? TopUserInfo(
                                      balanceTrailing: _buildLuckyBagEntry(),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const LoginRegisterButton(),
                                        const SizedBox(
                                          height: Style
                                              .guestLuckyBagSpacingFromLoginButton,
                                        ),
                                        Row(
                                          children: [
                                            const Spacer(),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right:
                                                    safeHorizontal / 2 +
                                                    Style.luckyBagRight,
                                              ),
                                              child: _buildLuckyBagEntry(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // TODO 保留原福袋入口实现，当前通过 Offstage 隐藏，方便后续恢复。
  Widget _buildLuckyBagEntry() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, Style.luckyBagOffsetY + _animation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          /// 点击福袋后进入文图详情页，并固定传递 type=59。
          routerUtil(path: '/image_text?type=59');
        },
        child: SvgIcon(
          name: "gold",
          width: Style.luckyBagSize,
          height: Style.luckyBagSize,
        ),
      ),
    );
  }
}

class _AvatarActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  const _AvatarActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dark,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? const Color(0xFF161F2B) : const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE7ECF3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: dark
                            ? Colors.white.withValues(alpha: 0.55)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: dark
                    ? Colors.white.withValues(alpha: 0.45)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
