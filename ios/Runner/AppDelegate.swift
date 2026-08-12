import AdSupport
import AppTrackingTransparency
import Flutter
import GoogleMobileAds
import UIKit
import UserNotifications
import google_mobile_ads

/// 为广告分类标签提供与 Flutter 小说标签一致的水平、垂直内边距。
private final class MasonryInsetLabel: UILabel {
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

    let attributionLabel = MasonryInsetLabel(frame: .zero)
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

    let advertiserLabel = MasonryInsetLabel(frame: .zero)
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
      adChoicesView.bottomAnchor.constraint(
        lessThanOrEqualTo: attributionLabel.bottomAnchor,
        constant: 4
      ),

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
}

/// 短篇正文中接近效果图沉浸式视频卡片的原生高级广告工厂。
private final class ShortStoryNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]?
  ) -> NativeAdView? {
    // 颜色与 Flutter 端 ColorConstants 保持一致，修改时需同步更新：
    // - Flutter: lib/config/color_config.dart
    // - Android: android/app/.../ShortStoryNativeAdFactory.kt

    let isDark = customOptions?["isDark"] as? Bool ?? false
    // 广告卡片背景色：夜间 #1E2430，日间对应 ColorConstants.whiteColor (white)。
    let cardBackground = isDark
      ? UIColor(red: 30 / 255, green: 36 / 255, blue: 48 / 255, alpha: 1)
      : UIColor.white
    // 主要文字颜色：夜间白色，日间对应 ColorConstants.lightTextColor (#222222)。
    let primaryText = isDark
      ? UIColor.white
      : UIColor(red: 34 / 255, green: 34 / 255, blue: 34 / 255, alpha: 1)
    // 次要文字颜色：夜间 #B0B5C0，日间 #7E7660。
    let secondaryText = isDark
      ? UIColor(red: 176 / 255, green: 181 / 255, blue: 192 / 255, alpha: 1)
      : UIColor(red: 126 / 255, green: 118 / 255, blue: 96 / 255, alpha: 1)

    // 广告卡片容器（圆角 16pt，裁剪内容）。
    let adView = NativeAdView(frame: .zero)
    adView.backgroundColor = cardBackground
    adView.layer.cornerRadius = 16
    adView.clipsToBounds = true

    // 视频/图片媒体区域。
    let mediaView = MediaView(frame: .zero)
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.mediaContent = nativeAd.mediaContent
    mediaView.contentMode = .scaleAspectFill
    adView.addSubview(mediaView)
    adView.mediaView = mediaView
#if DEBUG
    print(
      "[ShortStoryNativeAd] media hasVideoContent="
        + "\(nativeAd.mediaContent.hasVideoContent)"
    )
#endif

    // AdChoices 广告标识（右上角）。
    let adChoicesView = AdChoicesView(frame: .zero)
    adChoicesView.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(adChoicesView)
    adView.adChoicesView = adChoicesView

    // 广告标题（居中，最多 2 行）。
    let headlineLabel = makeLabel(
      text: nativeAd.headline,
      font: .systemFont(ofSize: 20, weight: .semibold),
      color: primaryText,
      lines: 2
    )
    headlineLabel.textAlignment = .center
    adView.addSubview(headlineLabel)
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
    adView.addSubview(advertiserLabel)
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
    adView.addSubview(callToActionLabel)
    adView.callToActionView = callToActionLabel

    // 布局约束：媒体区域 → 标题 → 广告主 → Open 按钮。
    NSLayoutConstraint.activate([
      // 媒体区域：顶部撑满，固定高度 260pt。
      mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
      mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      mediaView.heightAnchor.constraint(equalToConstant: 260),

      // AdChoices 标识：右上角。
      adChoicesView.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      adChoicesView.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -10),

      // 标题：媒体下方 14pt，左右各 14pt。
      headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 14),
      headlineLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 14),
      headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -14),

      // 广告主名称：标题下方 5pt。
      advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 5),
      advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),

      // Open 按钮：广告主下方至少 12pt，固定高度 46pt，底部 14pt。
      callToActionLabel.topAnchor.constraint(
        greaterThanOrEqualTo: advertiserLabel.bottomAnchor,
        constant: 12
      ),
      callToActionLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      callToActionLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
      callToActionLabel.heightAnchor.constraint(equalToConstant: 46),
      callToActionLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -14),
    ])

    adView.nativeAd = nativeAd
    return adView
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
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let badgeChannelName = "com.topread.app/badge"
  private static let setBadgeCountMethod = "setBadgeCount"
  private static let advertisingInfoChannelName = "com.topread.novel/advertising_info"
  private static let masonryNativeAdLayoutChannelName =
    "com.topread.novel/masonry_native_ad_layout"
  private static let getAdvertisingIdMethod = "getAdvertisingId"
  private static let isLimitAdTrackingEnabledMethod = "isLimitAdTrackingEnabled"
  private static let getTrackingAuthorizationStatusMethod = "getTrackingAuthorizationStatus"
  private static let masonryNativeAdFactoryID = "masonryNativeAdCard"
  private static let shortStoryNativeAdFactoryID = "shortStoryNativeAdCard"
  private var badgeChannel: FlutterMethodChannel?
  private var advertisingInfoChannel: FlutterMethodChannel?
  private var masonryNativeAdLayoutChannel: FlutterMethodChannel?
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
