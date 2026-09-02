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
    let isDark = customOptions?["isDark"] as? Bool ?? false
    let advertisementLabel =
      customOptions?["advertisementLabel"] as? String ?? "Ad"
    let slotID = customOptions?["slotId"] as? String
    let cardWidth = (customOptions?["cardWidth"] as? NSNumber)?.doubleValue
    let layoutToken = (customOptions?["layoutToken"] as? NSNumber)?.intValue

    let resolvedCardWidth =
      cardWidth.flatMap { width in
        width.isFinite && width > 0 ? width : nil
      } ?? 320

    // 颜色定义 - 遮罩层统一使用半透明黑色
    let overlayColor = UIColor(white: 0, alpha: 0.8)
    let headlineColor = UIColor.white
    let advertiserColor = UIColor(red: 204 / 255, green: 204 / 255, blue: 204 / 255, alpha: 1)

    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: resolvedCardWidth, height: 1)
    )
    adView.backgroundColor = .black
    adView.layer.cornerRadius = 16
    adView.clipsToBounds = true

    // 媒体区域
    let mediaView = MediaView(frame: .zero)
    mediaView.translatesAutoresizingMaskIntoConstraints = false
    mediaView.mediaContent = nativeAd.mediaContent
    mediaView.contentMode = .scaleAspectFill
    mediaView.clipsToBounds = true
    disableScrollIndicators(in: mediaView)
    adView.addSubview(mediaView)
    adView.mediaView = mediaView

    // 底部信息遮罩层
    let overlayView = UIView(frame: .zero)
    overlayView.translatesAutoresizingMaskIntoConstraints = false
    overlayView.backgroundColor = overlayColor
    adView.addSubview(overlayView)

    // 标题
    let headlineLabel = UILabel(frame: .zero)
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false
    headlineLabel.text = nativeAd.headline
    headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    headlineLabel.textColor = headlineColor
    headlineLabel.numberOfLines = 2
    overlayView.addSubview(headlineLabel)
    adView.headlineView = headlineLabel

    // 广告主 + Ad标签 + AdChoices 同一行
    let infoRow = UIView(frame: .zero)
    infoRow.translatesAutoresizingMaskIntoConstraints = false
    overlayView.addSubview(infoRow)

    // 从 Flutter 端获取随机颜色
    let tagColorRed = (customOptions?["tagColorRed"] as? NSNumber)?.doubleValue ?? 255
    let tagColorGreen = (customOptions?["tagColorGreen"] as? NSNumber)?.doubleValue ?? 77
    let tagColorBlue = (customOptions?["tagColorBlue"] as? NSNumber)?.doubleValue ?? 77

    let attributionLabel = UILabel(frame: .zero)
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false
    attributionLabel.text = advertisementLabel
    attributionLabel.font = .systemFont(ofSize: 10, weight: .regular)
    attributionLabel.textColor = UIColor(
      red: tagColorRed / 255,
      green: tagColorGreen / 255,
      blue: tagColorBlue / 255,
      alpha: 1
    )
    attributionLabel.textAlignment = .center
    attributionLabel.backgroundColor = UIColor(
      red: tagColorRed / 255,
      green: tagColorGreen / 255,
      blue: tagColorBlue / 255,
      alpha: 0.15
    )
    attributionLabel.layer.cornerRadius = 4
    attributionLabel.clipsToBounds = true
    infoRow.addSubview(attributionLabel)

    let advertiserLabel = UILabel(frame: .zero)
    advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
    advertiserLabel.text = nativeAd.advertiser
    advertiserLabel.font = .systemFont(ofSize: 11, weight: .regular)
    advertiserLabel.textColor = advertiserColor
    advertiserLabel.numberOfLines = 1
    advertiserLabel.isHidden = nativeAd.advertiser == nil
    infoRow.addSubview(advertiserLabel)
    adView.advertiserView = advertiserLabel

    let adChoicesView = AdChoicesView(frame: .zero)
    adChoicesView.translatesAutoresizingMaskIntoConstraints = false
    infoRow.addSubview(adChoicesView)
    adView.adChoicesView = adChoicesView

    // CTA 按钮
    let callToActionLabel = UILabel(frame: .zero)
    callToActionLabel.translatesAutoresizingMaskIntoConstraints = false
    callToActionLabel.text = nativeAd.callToAction
    callToActionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    callToActionLabel.textColor = UIColor(red: 34 / 255, green: 34 / 255, blue: 34 / 255, alpha: 1)
    callToActionLabel.backgroundColor = UIColor(red: 248 / 255, green: 208 / 255, blue: 45 / 255, alpha: 1)
    callToActionLabel.textAlignment = .center
    callToActionLabel.layer.cornerRadius = 19
    callToActionLabel.clipsToBounds = true
    callToActionLabel.isHidden = nativeAd.callToAction == nil
    overlayView.addSubview(callToActionLabel)
    adView.callToActionView = callToActionLabel

    // 视频静音播放
    nativeAd.mediaContent.videoController.mute(true)

    let hasVideoContent = nativeAd.mediaContent.hasVideoContent
    reportMediaType(hasVideoContent: hasVideoContent, slotID: slotID, layoutToken: layoutToken)
    monitorVideoPlayback(nativeAd: nativeAd, hasVideoContent: hasVideoContent, slotID: slotID, layoutToken: layoutToken)

    // 布局约束
    NSLayoutConstraint.activate([
      // 媒体区域
      mediaView.topAnchor.constraint(equalTo: adView.topAnchor),
      mediaView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      mediaView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      mediaView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

      // 遮罩层在底部
      overlayView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
      overlayView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),

      // 标题
      headlineLabel.topAnchor.constraint(equalTo: overlayView.topAnchor, constant: 8),
      headlineLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 12),
      headlineLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -12),

      // 信息行（广告主 + Ad + AdChoices）
      infoRow.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
      infoRow.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      infoRow.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
      infoRow.heightAnchor.constraint(equalToConstant: 18),

      attributionLabel.leadingAnchor.constraint(equalTo: infoRow.leadingAnchor),
      attributionLabel.centerYAnchor.constraint(equalTo: infoRow.centerYAnchor),

      advertiserLabel.leadingAnchor.constraint(equalTo: attributionLabel.trailingAnchor, constant: 6),
      advertiserLabel.centerYAnchor.constraint(equalTo: infoRow.centerYAnchor),
      advertiserLabel.trailingAnchor.constraint(lessThanOrEqualTo: adChoicesView.leadingAnchor, constant: -4),

      adChoicesView.trailingAnchor.constraint(equalTo: infoRow.trailingAnchor),
      adChoicesView.centerYAnchor.constraint(equalTo: infoRow.centerYAnchor),

      // CTA 按钮
      callToActionLabel.topAnchor.constraint(equalTo: infoRow.bottomAnchor, constant: 8),
      callToActionLabel.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 12),
      callToActionLabel.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -12),
      callToActionLabel.heightAnchor.constraint(equalToConstant: 38),
      callToActionLabel.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -10),
    ])

    // 测量并设置高度
    let measuredHeight = resolveMeasuredHeight(adView: adView, cardWidth: resolvedCardWidth)
    adView.frame = CGRect(x: 0, y: 0, width: resolvedCardWidth, height: measuredHeight)
    adView.setNeedsLayout()
    adView.layoutIfNeeded()
    adView.nativeAd = nativeAd

    // 视频自动播放（nativeAd 绑定后调用）
    if hasVideoContent {
      nativeAd.mediaContent.videoController.play()
    }

    reportMeasuredHeight(measuredHeight: measuredHeight, slotID: slotID, layoutToken: layoutToken)
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
