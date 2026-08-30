import AdSupport
import AppTrackingTransparency
import Flutter
import GoogleMobileAds
import UIKit
import UserNotifications
import google_mobile_ads

/// 为广告分类标签提供与 Flutter 小说标签一致的水平、垂直内边距。
private final class NativeAdInsetLabel: UILabel {
  private let textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: textInsets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + textInsets.left + textInsets.right,
      height: size.height + textInsets.top + textInsets.bottom
    )
  }
}

/// 手机双列瀑布流的单列纵向原生广告工厂。
///
/// 宽度由 Flutter 瀑布流列约束；该工厂只定义素材排布、法定广告
/// 标识以及 SDK 必需的 NativeAdView 素材注册。
private final class MasonryNativeAdFactory: NSObject, FLTNativeAdFactory {
  weak var layoutChannel: FlutterMethodChannel?

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]?
  ) -> NativeAdView? {
    let isDark = customOptions?["isDark"] as? Bool ?? false
    let advertisementLabel =
      customOptions?["advertisementLabel"] as? String ?? "Ad"
    let slotID = customOptions?["slotId"] as? String
    let cardWidth = (customOptions?["cardWidth"] as? NSNumber)?.doubleValue ?? 180
    let layoutToken = (customOptions?["layoutToken"] as? NSNumber)?.intValue
    let rawMediaAspectRatio = Double(nativeAd.mediaContent.aspectRatio)
    let mediaAspectRatio = rawMediaAspectRatio.isFinite && rawMediaAspectRatio > 0
      ? rawMediaAspectRatio
      : 1
    let mediaHeight = min(max(cardWidth / mediaAspectRatio, 120), 320)
    let cardBackground = isDark
      ? UIColor(red: 23 / 255, green: 28 / 255, blue: 40 / 255, alpha: 1)
      : .white
    let primaryText = isDark
      ? UIColor.white
      : UIColor(red: 22 / 255, green: 28 / 255, blue: 40 / 255, alpha: 1)
    let secondaryText = isDark
      ? UIColor(red: 176 / 255, green: 181 / 255, blue: 192 / 255, alpha: 1)
      : UIColor(red: 116 / 255, green: 124 / 255, blue: 138 / 255, alpha: 1)
    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: cardWidth, height: 1)
    )
    adView.backgroundColor = cardBackground
    adView.layer.cornerRadius = 18
    adView.clipsToBounds = true

    let mediaView = MediaView(frame: .zero)
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.mediaContent = nativeAd.mediaContent
    mediaView.contentMode = .scaleAspectFit
    // 禁用媒体区域内所有 UIScrollView 的滚动指示器，
    // 避免 iOS 在广告卡片上方显示多余的空白滚动条。
    disableScrollIndicators(in: mediaView)
    adView.addSubview(mediaView)
    adView.mediaView = mediaView
#if DEBUG
    print(
      "[MasonryNativeAd] media hasVideoContent="
        + "\(nativeAd.mediaContent.hasVideoContent)"
    )
#endif

    // 将 SDK 的 AdChoices 放到和普通小说标签一致的元信息行。
    // 它仍由 Google 渲染并处理点击，不能隐藏或伪装成普通内容。
    let adChoicesView = AdChoicesView(frame: .zero)
    adChoicesView.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(adChoicesView)
    adView.adChoicesView = adChoicesView

    let attributionLabel = NativeAdInsetLabel(frame: .zero)
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false
    attributionLabel.text = advertisementLabel
    attributionLabel.font = .systemFont(ofSize: 11, weight: .regular)
    attributionLabel.textColor = UIColor(
      red: 95 / 255,
      green: 139 / 255,
      blue: 1,
      alpha: 0.96
    )
    attributionLabel.backgroundColor = UIColor(
      red: 95 / 255,
      green: 139 / 255,
      blue: 1,
      alpha: 0.16
    )
    attributionLabel.textAlignment = .center
    attributionLabel.layer.cornerRadius = 11
    attributionLabel.clipsToBounds = true
    adView.addSubview(attributionLabel)

    let headlineLabel = makeLabel(
      text: nativeAd.headline,
      font: .systemFont(ofSize: 15, weight: .medium),
      color: primaryText,
      lines: 2
    )
    adView.addSubview(headlineLabel)
    adView.headlineView = headlineLabel

    let bodyLabel = makeLabel(
      text: nativeAd.body,
      font: .systemFont(ofSize: 12, weight: .regular),
      color: secondaryText,
      lines: 2
    )
    bodyLabel.isHidden = nativeAd.body == nil
    adView.addSubview(bodyLabel)
    adView.bodyView = bodyLabel

    let advertiserLabel = NativeAdInsetLabel(frame: .zero)
    advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
    advertiserLabel.text = nativeAd.advertiser
    advertiserLabel.font = .systemFont(ofSize: 11, weight: .regular)
    advertiserLabel.numberOfLines = 1
    advertiserLabel.lineBreakMode = .byTruncatingTail
    advertiserLabel.isHidden = nativeAd.advertiser == nil
    advertiserLabel.textColor = UIColor(
      red: 47 / 255,
      green: 191 / 255,
      blue: 155 / 255,
      alpha: 0.96
    )
    advertiserLabel.backgroundColor = UIColor(
      red: 47 / 255,
      green: 191 / 255,
      blue: 155 / 255,
      alpha: 0.16
    )
    advertiserLabel.textAlignment = .center
    advertiserLabel.layer.cornerRadius = 11
    advertiserLabel.clipsToBounds = true
    adView.addSubview(advertiserLabel)
    adView.advertiserView = advertiserLabel

    let callToActionLabel = makeLabel(
      text: nativeAd.callToAction,
      font: .systemFont(ofSize: 13, weight: .semibold),
      color: UIColor(red: 42 / 255, green: 36 / 255, blue: 16 / 255, alpha: 1),
      lines: 1
    )
    callToActionLabel.backgroundColor = UIColor(
      red: 248 / 255,
      green: 208 / 255,
      blue: 45 / 255,
      alpha: 1
    )
    callToActionLabel.textAlignment = .center
    callToActionLabel.layer.cornerRadius = 10
    callToActionLabel.clipsToBounds = true
    callToActionLabel.isHidden = nativeAd.callToAction == nil
    let callToActionHeight: CGFloat = nativeAd.callToAction == nil ? 0 : 34
    let callToActionTopSpacing: CGFloat = nativeAd.callToAction == nil ? 0 : 8
    // UILabel 默认不单独处理点击，点击统一交给 Google SDK。
    adView.addSubview(callToActionLabel)
    adView.callToActionView = callToActionLabel

    NSLayoutConstraint.activate([
      mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
      mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      mediaView.heightAnchor.constraint(equalToConstant: mediaHeight),

      headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10),
      headlineLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),

      bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 6),
      bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

      attributionLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
      attributionLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 10),
      attributionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
      attributionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),

      advertiserLabel.leadingAnchor.constraint(equalTo: attributionLabel.trailingAnchor, constant: 6),
      advertiserLabel.centerYAnchor.constraint(equalTo: attributionLabel.centerYAnchor),
      advertiserLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
      advertiserLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 88),
      advertiserLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: adChoicesView.leadingAnchor,
        constant: -6
      ),

      adChoicesView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
      adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),
      adChoicesView.widthAnchor.constraint(equalToConstant: 24),
      adChoicesView.heightAnchor.constraint(equalToConstant: 24),

      callToActionLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      callToActionLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
      callToActionLabel.topAnchor.constraint(
        equalTo: attributionLabel.bottomAnchor,
        constant: callToActionTopSpacing
      ),
      callToActionLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
      callToActionLabel.heightAnchor.constraint(equalToConstant: callToActionHeight),
    ])

    // 必须在所有素材注册完成后再关联，由 SDK 处理点击、曝光、
    // AdChoices 及广告信息/报告入口。
    adView.nativeAd = nativeAd
    reportMeasuredHeight(
      adView: adView,
      cardWidth: cardWidth,
      slotID: slotID,
      layoutToken: layoutToken
    )
    return adView
  }

  private func reportMeasuredHeight(
    adView: NativeAdView,
    cardWidth: Double,
    slotID: String?,
    layoutToken: Int?
  ) {
    guard let slotID, let layoutToken else { return }
    let targetSize = CGSize(
      width: cardWidth,
      height: UIView.layoutFittingCompressedSize.height
    )
    let measuredSize = adView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    guard measuredSize.height.isFinite, measuredSize.height > 0 else { return }
    DispatchQueue.main.async { [weak self] in
      self?.layoutChannel?.invokeMethod(
        "onNativeAdLayout",
        arguments: [
          "slotId": slotID,
          "viewHeight": measuredSize.height,
          "layoutToken": layoutToken,
        ]
      )
    }
  }

  private func makeLabel(
    text: String?,
    font: UIFont,
    color: UIColor,
    lines: Int
  ) -> UILabel {
    let label = UILabel(frame: .zero)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = font
    label.textColor = color
    label.numberOfLines = lines
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  /// 递归禁用媒体视图内部滚动容器的指示器。
  private func disableScrollIndicators(in view: UIView) {
    for subview in view.subviews {
      if let scrollView = subview as? UIScrollView {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
      }
      disableScrollIndicators(in: subview)
    }
  }
}

/// 将短篇原生广告的真实视频播放事件回传 Flutter。
private final class ShortStoryNativeVideoObserver: NSObject, VideoControllerDelegate {
  weak var layoutChannel: FlutterMethodChannel?
  let slotID: String
  let layoutToken: Int

  init(layoutChannel: FlutterMethodChannel?, slotID: String, layoutToken: Int) {
    self.layoutChannel = layoutChannel
    self.slotID = slotID
    self.layoutToken = layoutToken
  }

  func videoControllerDidPlayVideo(_ videoController: VideoController) {
    report(playbackState: "playing", isMuted: videoController.isMuted)
  }

  func videoControllerDidPauseVideo(_ videoController: VideoController) {
    report(playbackState: "paused", isMuted: videoController.isMuted)
  }

  func videoControllerDidEndVideoPlayback(_ videoController: VideoController) {
    report(playbackState: "ended", isMuted: videoController.isMuted)
  }

  func videoControllerDidMuteVideo(_ videoController: VideoController) {
    report(playbackState: "muted", isMuted: true)
  }

  func videoControllerDidUnmuteVideo(_ videoController: VideoController) {
    report(playbackState: "unmuted", isMuted: false)
  }

  /// 将视频播放状态回传 Flutter 日志层。
  private func report(playbackState: String, isMuted: Bool) {
    layoutChannel?.invokeMethod(
      "onNativeAdVideoPlayback",
      arguments: [
        "slotId": slotID,
        "playbackState": playbackState,
        "isMuted": isMuted,
        "layoutToken": layoutToken,
      ]
    )
  }
}

/// 短篇正文中接近效果图沉浸式视频卡片的原生高级广告工厂。
private final class ShortStoryNativeAdFactory: NSObject, FLTNativeAdFactory {
  private struct NativeAdMediaState {
    let layoutToken: Int
    let hasVideoContent: Bool
  }

  weak var layoutChannel: FlutterMethodChannel? {
    didSet {
      layoutChannel?.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }
        self.handleLayoutMethodCall(call, result: result)
      }
    }
  }

  /// 供 Flutter 主动查询的媒体素材状态，解决平台视图回调时序竞争。
  private var mediaStateBySlotID: [String: NativeAdMediaState] = [:]

  /// 强引用视频事件监听器，因为 Google SDK 的 delegate 属性为弱引用。
  private var videoObserversBySlotID: [String: ShortStoryNativeVideoObserver] = [:]

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]?
  ) -> NativeAdView? {
    // 颜色与 Flutter 端 ColorConstants 保持一致，修改时需同步更新：
    // - Flutter: lib/config/color_config.dart
    // - Android: android/app/.../ShortStoryNativeAdFactory.kt

    let isDark = customOptions?["isDark"] as? Bool ?? false
    let advertisementLabel =
      customOptions?["advertisementLabel"] as? String ?? "Ad"
    let slotID = customOptions?["slotId"] as? String
    let cardWidth = (customOptions?["cardWidth"] as? NSNumber)?.doubleValue
    let layoutToken = (customOptions?["layoutToken"] as? NSNumber)?.intValue
    // 广告卡片背景色：夜间 #1E2430，日间对应 ColorConstants.whiteColor (white)。
    let cardBackground =
      isDark
      ? UIColor(red: 30 / 255, green: 36 / 255, blue: 48 / 255, alpha: 1)
      : UIColor.white
    // 主要文字颜色：夜间白色，日间对应 ColorConstants.lightTextColor (#222222)。
    let primaryText =
      isDark
      ? UIColor.white
      : UIColor(red: 34 / 255, green: 34 / 255, blue: 34 / 255, alpha: 1)
    // 次要文字颜色：夜间 #B0B5C0，日间 #7E7660。
    let secondaryText =
      isDark
      ? UIColor(red: 176 / 255, green: 181 / 255, blue: 192 / 255, alpha: 1)
      : UIColor(red: 126 / 255, green: 118 / 255, blue: 96 / 255, alpha: 1)

    // 广告卡片容器（圆角 16pt，裁剪内容）。
    let resolvedCardWidth =
      cardWidth.flatMap { width in
        width.isFinite && width > 0 ? width : nil
      } ?? 320
    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: resolvedCardWidth, height: 1)
    )
    adView.backgroundColor = cardBackground
    adView.layer.cornerRadius = 16
    adView.clipsToBounds = true

    // 使用单一纵向栈确保归因栏、媒体和信息区域物理隔离。
    let contentStackView = UIStackView(frame: .zero)
    contentStackView.translatesAutoresizingMaskIntoConstraints = false
    contentStackView.axis = .vertical
    contentStackView.alignment = .fill
    contentStackView.distribution = .fill
    contentStackView.spacing = 0
    adView.addSubview(contentStackView)

    // Google SDK 根据 NativeAdOptions 把 AdChoices 自动放在
    // NativeAdView 右上角，归因栏右半部分不放置其他素材。
    let attributionHeaderView = UIView(frame: .zero)
    attributionHeaderView.translatesAutoresizingMaskIntoConstraints = false
    attributionHeaderView.backgroundColor = cardBackground
    contentStackView.addArrangedSubview(attributionHeaderView)

    let attributionLabel = NativeAdInsetLabel(frame: .zero)
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false
    attributionLabel.text = advertisementLabel
    attributionLabel.font = .systemFont(ofSize: 11, weight: .regular)
    attributionLabel.textColor = UIColor(
      red: 95 / 255,
      green: 139 / 255,
      blue: 1,
      alpha: 0.96
    )
    attributionLabel.backgroundColor = UIColor(
      red: 95 / 255,
      green: 139 / 255,
      blue: 1,
      alpha: 0.16
    )
    attributionLabel.textAlignment = .center
    attributionLabel.numberOfLines = 1
    attributionLabel.lineBreakMode = .byTruncatingTail
    attributionLabel.layer.cornerRadius = 10
    attributionLabel.clipsToBounds = true
    attributionHeaderView.addSubview(attributionLabel)

    // 媒体外再增加一层强制裁剪容器。图片素材的内部 UIImageView
    // 与视频素材的内部层级不同，只修改 MediaView 本身不足以
    // 保证图片不越界覆盖归因栏、标题和按钮。
    let mediaClipView = UIView(frame: .zero)
    mediaClipView.translatesAutoresizingMaskIntoConstraints = false
    mediaClipView.backgroundColor = cardBackground
    mediaClipView.clipsToBounds = true
    mediaClipView.layer.masksToBounds = true
    contentStackView.addArrangedSubview(mediaClipView)

    let mediaView = MediaView(frame: .zero)
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.mediaContent = nativeAd.mediaContent
    let hasVideoContent = nativeAd.mediaContent.hasVideoContent
    mediaView.contentMode = hasVideoContent ? .scaleAspectFill : .scaleAspectFit
    mediaView.clipsToBounds = true
    mediaView.layer.masksToBounds = true
    // 禁用媒体区域内所有 UIScrollView 的滚动指示器，
    // 避免 iOS 在广告卡片上方显示多余的空白滚动条。
    disableScrollIndicators(in: mediaView)
    mediaClipView.addSubview(mediaView)
    adView.mediaView = mediaView
    reportMediaType(
      hasVideoContent: hasVideoContent,
      slotID: slotID,
      layoutToken: layoutToken
    )
    monitorVideoPlayback(
      nativeAd: nativeAd,
      hasVideoContent: hasVideoContent,
      slotID: slotID,
      layoutToken: layoutToken
    )
    #if DEBUG
      let mediaType = hasVideoContent ? "视频广告" : "图片广告"
      print("[ShortStoryNativeAd] 广告素材类型: \(mediaType)")
    #endif

    let informationView = UIView(frame: .zero)
    informationView.translatesAutoresizingMaskIntoConstraints = false
    informationView.backgroundColor = cardBackground
    contentStackView.addArrangedSubview(informationView)

    // 广告标题（居中，最多 3 行）。
    let headlineLabel = makeLabel(
      text: nativeAd.headline,
      font: .systemFont(ofSize: 16, weight: .semibold),
      color: primaryText,
      lines: 3
    )
    headlineLabel.textAlignment = .center
    headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    informationView.addSubview(headlineLabel)
    adView.headlineView = headlineLabel

    // 广告主名称（居中，单行）。
    let advertiserLabel = makeLabel(
      text: nativeAd.advertiser,
      font: .systemFont(ofSize: 12, weight: .regular),
      color: secondaryText,
      lines: 1
    )
    advertiserLabel.textAlignment = .center
    advertiserLabel.isHidden = nativeAd.advertiser == nil
    if nativeAd.advertiser != nil {
      advertiserLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    let advertiserTopSpacing: CGFloat = nativeAd.advertiser == nil ? 0 : 5
    let advertiserHeightConstraint =
      nativeAd.advertiser == nil
      ? advertiserLabel.heightAnchor.constraint(equalToConstant: 0)
      : nil
    informationView.addSubview(advertiserLabel)
    adView.advertiserView = advertiserLabel

    // Open 按钮：背景色对应 ColorConstants.themeColor (#F8D02D)，
    // 文字色对应 ColorConstants.lightTextColor (#222222)。
    let callToActionLabel = makeLabel(
      text: nativeAd.callToAction,
      font: .systemFont(ofSize: 16, weight: .semibold),
      color: UIColor(red: 34 / 255, green: 34 / 255, blue: 34 / 255, alpha: 1),
      lines: 1
    )
    callToActionLabel.backgroundColor = UIColor(
      red: 248 / 255,
      green: 208 / 255,
      blue: 45 / 255,
      alpha: 1
    )
    callToActionLabel.textAlignment = .center
    callToActionLabel.layer.cornerRadius = 23
    callToActionLabel.clipsToBounds = true
    callToActionLabel.isHidden = nativeAd.callToAction == nil
    if nativeAd.callToAction != nil {
      callToActionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    let callToActionHeight: CGFloat = nativeAd.callToAction == nil ? 0 : 46
    let callToActionTopSpacing: CGFloat = nativeAd.callToAction == nil ? 0 : 12
    informationView.addSubview(callToActionLabel)
    adView.callToActionView = callToActionLabel

    // 布局约束：根栈 → 归因栏 → 媒体裁剪容器 → 信息区域。
    NSLayoutConstraint.activate([
      contentStackView.topAnchor.constraint(equalTo: adView.topAnchor),
      contentStackView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      contentStackView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      contentStackView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

      // 归因栏：左侧仅放置自有 Ad 标签，右侧留给 SDK 的 AdChoices。
      attributionHeaderView.heightAnchor.constraint(equalToConstant: 36),
      attributionLabel.leadingAnchor.constraint(
        equalTo: attributionHeaderView.leadingAnchor,
        constant: 10
      ),
      attributionLabel.centerYAnchor.constraint(equalTo: attributionHeaderView.centerYAnchor),
      attributionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
      attributionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
      attributionLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: attributionHeaderView.centerXAnchor
      ),

      // 媒体裁剪容器和 MediaView 始终等尺寸。
      mediaClipView.heightAnchor.constraint(equalToConstant: 260),
      mediaView.topAnchor.constraint(equalTo: mediaClipView.topAnchor),
      mediaView.leadingAnchor.constraint(equalTo: mediaClipView.leadingAnchor),
      mediaView.trailingAnchor.constraint(equalTo: mediaClipView.trailingAnchor),
      mediaView.bottomAnchor.constraint(equalTo: mediaClipView.bottomAnchor),

      // 信息区内使用严格纵向约束，不允许标题或按钮向上压入媒体区。
      headlineLabel.topAnchor.constraint(equalTo: informationView.topAnchor, constant: 14),
      headlineLabel.leadingAnchor.constraint(equalTo: informationView.leadingAnchor, constant: 14),
      headlineLabel.trailingAnchor.constraint(
        equalTo: informationView.trailingAnchor, constant: -14),

      // 广告主名称：标题下方；素材为空时不保留空白。
      advertiserLabel.topAnchor.constraint(
        equalTo: headlineLabel.bottomAnchor,
        constant: advertiserTopSpacing
      ),
      advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

      // Open 按钮：广告主名称下方，底部固定 14pt。
      callToActionLabel.topAnchor.constraint(
        equalTo: advertiserLabel.bottomAnchor,
        constant: callToActionTopSpacing
      ),
      callToActionLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      callToActionLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
      callToActionLabel.heightAnchor.constraint(equalToConstant: callToActionHeight),
      callToActionLabel.bottomAnchor.constraint(
        equalTo: informationView.bottomAnchor,
        constant: -14
      ),
    ])
    advertiserHeightConstraint?.isActive = true

    // 程序化创建的 NativeAdView 初始高度只有 1pt。先测量并完成布局，
    // 再绑定 nativeAd，避免 SDK 在首次校验时看到所有素材重叠在原点。
    let measuredHeight = resolveMeasuredHeight(
      adView: adView,
      cardWidth: resolvedCardWidth
    )
    adView.frame = CGRect(
      x: 0,
      y: 0,
      width: resolvedCardWidth,
      height: measuredHeight
    )
    adView.setNeedsLayout()
    adView.layoutIfNeeded()
    adView.nativeAd = nativeAd
    // nativeAd 绑定时 SDK 才可能创建图片/视频内部视图，
    // 再次禁用内部滚动指示器，外层 mediaClipView 始终负责硬裁剪。
    disableScrollIndicators(in: mediaView)
    #if DEBUG
      let attributionFrame = attributionLabel.convert(attributionLabel.bounds, to: adView)
      let mediaFrame = mediaClipView.convert(mediaClipView.bounds, to: adView)
      let headlineFrame = headlineLabel.convert(headlineLabel.bounds, to: adView)
      let advertiserFrame = advertiserLabel.convert(advertiserLabel.bounds, to: adView)
      let callToActionFrame = callToActionLabel.convert(callToActionLabel.bounds, to: adView)
      let hasAssetOverlap =
        mediaFrame.intersects(headlineFrame)
        || (!advertiserLabel.isHidden && mediaFrame.intersects(advertiserFrame))
        || (!callToActionLabel.isHidden && mediaFrame.intersects(callToActionFrame))
      print(
        "[ShortStoryNativeAd] 布局校验: "
          + "height=\(measuredHeight), "
          + "ad=\(NSStringFromCGRect(attributionFrame)), "
          + "media=\(NSStringFromCGRect(mediaFrame)), "
          + "headline=\(NSStringFromCGRect(headlineFrame)), "
          + "advertiser=\(NSStringFromCGRect(advertiserFrame)), "
          + "cta=\(NSStringFromCGRect(callToActionFrame)), "
          + "overlap=\(hasAssetOverlap)"
      )
    #endif
    reportMeasuredHeight(
      measuredHeight: measuredHeight,
      slotID: slotID,
      layoutToken: layoutToken
    )
    return adView
  }

  /// 将广告的媒体素材类型回传 Flutter 日志层。
  private func reportMediaType(
    hasVideoContent: Bool,
    slotID: String?,
    layoutToken: Int?
  ) {
    guard let slotID, let layoutToken else { return }
    mediaStateBySlotID[slotID] = NativeAdMediaState(
      layoutToken: layoutToken,
      hasVideoContent: hasVideoContent
    )
    DispatchQueue.main.async { [weak self] in
      self?.layoutChannel?.invokeMethod(
        "onNativeAdMediaType",
        arguments: [
          "slotId": slotID,
          "hasVideoContent": hasVideoContent,
          "layoutToken": layoutToken,
        ]
      )
    }
  }

  /// 监听视频真实的播放、暂停、结束和静音状态。
  private func monitorVideoPlayback(
    nativeAd: NativeAd,
    hasVideoContent: Bool,
    slotID: String?,
    layoutToken: Int?
  ) {
    guard hasVideoContent, let slotID, let layoutToken else { return }
    let observer = ShortStoryNativeVideoObserver(
      layoutChannel: layoutChannel,
      slotID: slotID,
      layoutToken: layoutToken
    )
    videoObserversBySlotID[slotID] = observer
    nativeAd.mediaContent.videoController.delegate = observer
  }

  /// 处理 Flutter 对媒体素材状态的主动查询和释放请求。
  private func handleLayoutMethodCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let arguments = call.arguments as? [String: Any]
    let slotID = arguments?["slotId"] as? String

    switch call.method {
    case "getNativeAdMediaType":
      let layoutToken = (arguments?["layoutToken"] as? NSNumber)?.intValue
      guard
        let slotID,
        let layoutToken,
        let mediaState = mediaStateBySlotID[slotID],
        mediaState.layoutToken == layoutToken
      else {
        result(nil)
        return
      }
      result(mediaState.hasVideoContent)
    case "clearNativeAdMediaState":
      if let slotID {
        mediaStateBySlotID.removeValue(forKey: slotID)
        videoObserversBySlotID.removeValue(forKey: slotID)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 按实际标题、广告主和按钮内容测量卡片高度。
  private func resolveMeasuredHeight(
    adView: NativeAdView,
    cardWidth: Double
  ) -> CGFloat {
    let fallbackHeight: CGFloat = 460
    let targetSize = CGSize(
      width: cardWidth,
      height: UIView.layoutFittingCompressedSize.height
    )
    let measuredSize = adView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    guard measuredSize.height.isFinite, measuredSize.height > 0 else {
      return fallbackHeight
    }
    return measuredSize.height.rounded(.up)
  }

  /// 将绑定广告前已确定的卡片高度通知 Flutter。
  private func reportMeasuredHeight(
    measuredHeight: CGFloat,
    slotID: String?,
    layoutToken: Int?
  ) {
    guard let slotID, let layoutToken else { return }
    DispatchQueue.main.async { [weak self] in
      self?.layoutChannel?.invokeMethod(
        "onNativeAdLayout",
        arguments: [
          "slotId": slotID,
          "viewHeight": measuredHeight,
          "layoutToken": layoutToken,
        ]
      )
    }
  }

  /// 创建 UILabel 快捷方法。
  ///
  /// - Parameters:
  ///   - text: 初始文本。
  ///   - font: 字体。
  ///   - color: 文字颜色。
  ///   - lines: 最大行数。
  /// - Returns: 配置完成的 UILabel。
  private func makeLabel(
    text: String?,
    font: UIFont,
    color: UIColor,
    lines: Int
  ) -> UILabel {
    let label = UILabel(frame: .zero)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = text
    label.font = font
    label.textColor = color
    label.numberOfLines = lines
    label.lineBreakMode = .byTruncatingTail
    return label
  }

  /// 递归禁用视图层级中所有 UIScrollView 的滚动指示器。
  ///
  /// Google AdMob 的 MediaView 内部可能包含 WKWebView 或其他
  /// 嵌套滚动容器，iOS 默认显示滚动指示器会在广告卡片上方产生
  /// 一条空白滚动条。递归遍历确保所有层级的滚动指示器都被禁用。
  private func disableScrollIndicators(in view: UIView) {
    for subview in view.subviews {
      if let scrollView = subview as? UIScrollView {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
      }
      disableScrollIndicators(in: subview)
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let badgeChannelName = "com.topread.app/badge"
  private static let setBadgeCountMethod = "setBadgeCount"
  private static let advertisingInfoChannelName = "com.topread.novel/advertising_info"
  private static let masonryNativeAdLayoutChannelName =
    "com.topread.novel/masonry_native_ad_layout"
  private static let shortStoryNativeAdLayoutChannelName =
    "com.topread.novel/short_story_native_ad_layout"
  private static let getAdvertisingIdMethod = "getAdvertisingId"
  private static let isLimitAdTrackingEnabledMethod = "isLimitAdTrackingEnabled"
  private static let getTrackingAuthorizationStatusMethod = "getTrackingAuthorizationStatus"
  private static let masonryNativeAdFactoryID = "masonryNativeAdCard"
  private static let shortStoryNativeAdFactoryID = "shortStoryNativeAdCard"
  private var badgeChannel: FlutterMethodChannel?
  private var advertisingInfoChannel: FlutterMethodChannel?
  private var masonryNativeAdLayoutChannel: FlutterMethodChannel?
  private var shortStoryNativeAdLayoutChannel: FlutterMethodChannel?
  private let masonryNativeAdFactory = MasonryNativeAdFactory()
  private let shortStoryNativeAdFactory = ShortStoryNativeAdFactory()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: Self.masonryNativeAdFactoryID,
      nativeAdFactory: masonryNativeAdFactory
    )
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: Self.shortStoryNativeAdFactoryID,
      nativeAdFactory: shortStoryNativeAdFactory
    )

    let masonryLayoutChannel = FlutterMethodChannel(
      name: Self.masonryNativeAdLayoutChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    masonryNativeAdFactory.layoutChannel = masonryLayoutChannel
    masonryNativeAdLayoutChannel = masonryLayoutChannel

    let shortStoryLayoutChannel = FlutterMethodChannel(
      name: Self.shortStoryNativeAdLayoutChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    shortStoryNativeAdFactory.layoutChannel = shortStoryLayoutChannel
    shortStoryNativeAdLayoutChannel = shortStoryLayoutChannel

    let channel = FlutterMethodChannel(
      name: Self.badgeChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleBadgeMethodCall(call, result: result)
    }
    badgeChannel = channel

    let advertisingInfoChannel = FlutterMethodChannel(
      name: Self.advertisingInfoChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    advertisingInfoChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleAdvertisingInfoMethodCall(call, result: result)
    }
    self.advertisingInfoChannel = advertisingInfoChannel
  }

  private func handleBadgeMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == Self.setBadgeCountMethod else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let count = arguments["count"] as? NSNumber
    else {
      result(
        FlutterError(
          code: "invalid_badge_count",
          message: "Badge count must be an integer.",
          details: nil
        )
      )
      return
    }

    let normalizedCount = max(0, count.intValue)
    UNUserNotificationCenter.current().setBadgeCount(normalizedCount) { error in
      DispatchQueue.main.async {
        if let error {
          result(
            FlutterError(
              code: "badge_update_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        result(nil)
      }
    }
  }

  private func handleAdvertisingInfoMethodCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case Self.getAdvertisingIdMethod:
      getAdvertisingId(result: result)
    case Self.isLimitAdTrackingEnabledMethod:
      result(isLimitAdTrackingEnabled())
    case Self.getTrackingAuthorizationStatusMethod:
      result(trackingAuthorizationStatusName(ATTrackingManager.trackingAuthorizationStatus))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getAdvertisingId(result: @escaping FlutterResult) {
    let status = ATTrackingManager.trackingAuthorizationStatus

    switch status {
    case .authorized:
      result(nonZeroAdvertisingIdentifier())
    case .notDetermined:
      result(nil)
    case .denied, .restricted:
      result(nil)
    @unknown default:
      result(nil)
    }
  }

  private func isLimitAdTrackingEnabled() -> Bool {
    return ATTrackingManager.trackingAuthorizationStatus != .authorized
  }

  private func nonZeroAdvertisingIdentifier() -> String? {
    let identifier = ASIdentifierManager.shared().advertisingIdentifier
    return identifier == UUID(uuidString: "00000000-0000-0000-0000-000000000000")
      ? nil
      : identifier.uuidString
  }

  private func trackingAuthorizationStatusName(
    _ status: ATTrackingManager.AuthorizationStatus
  ) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    @unknown default:
      return "unknown"
    }
  }

}
