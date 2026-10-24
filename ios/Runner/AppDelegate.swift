import AdSupport
import AppTrackingTransparency
import AVFAudio
import Flutter
import GoogleMobileAds
import UIKit
import UserNotifications
import google_mobile_ads

/// 将 Flutter ARGB 转成 UIKit 颜色，原生端不定义色值。
private func flutterColor(_ value: NSNumber) -> UIColor {
  let argb = value.uint32Value
  let byteMax: CGFloat = 255
  return UIColor(
    red: CGFloat((argb >> 16) & 0xFF) / byteMax,
    green: CGFloat((argb >> 8) & 0xFF) / byteMax,
    blue: CGFloat(argb & 0xFF) / byteMax,
    alpha: CGFloat((argb >> 24) & 0xFF) / byteMax
  )
}

/// 原生广告只解码 Flutter 色板，不在 Swift 内复制主题或标签颜色。
private struct NativeAdPalette {
  private let colors: [String: NSNumber]

  init?(_ customOptions: [AnyHashable: Any]?) {
    guard let colors = customOptions?["palette"] as? [String: NSNumber],
      [
        "card_background", "primary_text", "secondary_text",
        "attribution_text", "attribution_background",
        "advertiser_text", "advertiser_background", "cta_text", "cta_background",
        "overlay_background", "overlay_scrim", "overlay_headline", "overlay_caption",
        "overlay_tag", "overlay_tag_background", "overlay_cta_text",
      ].allSatisfy({ colors[$0] != nil })
    else { return nil }
    self.colors = colors
  }

  func color(_ key: String) -> UIColor {
    // 初始化时已验证所有协议字段；颜色数值按 Flutter toARGB32() 解码。
    return flutterColor(colors[key]!)
  }
}

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
    guard let palette = NativeAdPalette(customOptions) else { return nil }
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
    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: cardWidth, height: 1)
    )
    adView.backgroundColor = palette.color("card_background")
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
    attributionLabel.textColor = palette.color("attribution_text")
    attributionLabel.backgroundColor = palette.color("attribution_background")
    attributionLabel.textAlignment = .center
    attributionLabel.layer.cornerRadius = 11
    attributionLabel.clipsToBounds = true
    adView.addSubview(attributionLabel)

    let headlineLabel = makeLabel(
      text: nativeAd.headline,
      font: .systemFont(ofSize: 15, weight: .medium),
      color: palette.color("primary_text"),
      lines: 2
    )
    adView.addSubview(headlineLabel)
    adView.headlineView = headlineLabel

    let bodyLabel = makeLabel(
      text: nativeAd.body,
      font: .systemFont(ofSize: 12, weight: .regular),
      color: palette.color("secondary_text"),
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
    advertiserLabel.textColor = palette.color("advertiser_text")
    advertiserLabel.backgroundColor = palette.color("advertiser_background")
    advertiserLabel.textAlignment = .center
    advertiserLabel.layer.cornerRadius = 11
    advertiserLabel.clipsToBounds = true
    adView.addSubview(advertiserLabel)
    adView.advertiserView = advertiserLabel

    let callToActionLabel = makeLabel(
      text: nativeAd.callToAction,
      font: .systemFont(ofSize: 13, weight: .semibold),
      color: palette.color("cta_text"),
      lines: 1
    )
    callToActionLabel.backgroundColor = palette.color("cta_background")
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
    guard let palette = NativeAdPalette(customOptions) else { return nil }
    let advertisementLabel =
      customOptions?["advertisementLabel"] as? String ?? "Ad"
    let slotID = customOptions?["slotId"] as? String
    let cardWidth = (customOptions?["cardWidth"] as? NSNumber)?.doubleValue
    let layoutToken = (customOptions?["layoutToken"] as? NSNumber)?.intValue

    let resolvedCardWidth =
      cardWidth.flatMap { width in
        width.isFinite && width > 0 ? width : nil
      } ?? 320

    let adView = NativeAdView(
      frame: CGRect(x: 0, y: 0, width: resolvedCardWidth, height: 1)
    )
    adView.backgroundColor = palette.color("overlay_background")
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
    overlayView.backgroundColor = palette.color("overlay_scrim")
    adView.addSubview(overlayView)

    // 标题
    let headlineLabel = UILabel(frame: .zero)
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false
    headlineLabel.text = nativeAd.headline
    headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    headlineLabel.textColor = palette.color("overlay_headline")
    headlineLabel.numberOfLines = 2
    overlayView.addSubview(headlineLabel)
    adView.headlineView = headlineLabel

    // 广告主 + Ad标签 + AdChoices 同一行
    let infoRow = UIView(frame: .zero)
    infoRow.translatesAutoresizingMaskIntoConstraints = false
    overlayView.addSubview(infoRow)

    let attributionLabel = UILabel(frame: .zero)
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false
    attributionLabel.text = advertisementLabel
    attributionLabel.font = .systemFont(ofSize: 10, weight: .regular)
    attributionLabel.textColor = palette.color("overlay_tag")
    attributionLabel.textAlignment = .center
    attributionLabel.backgroundColor = palette.color("overlay_tag_background")
    attributionLabel.layer.cornerRadius = 4
    attributionLabel.clipsToBounds = true
    infoRow.addSubview(attributionLabel)

    let advertiserLabel = UILabel(frame: .zero)
    advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
    advertiserLabel.text = nativeAd.advertiser
    advertiserLabel.font = .systemFont(ofSize: 11, weight: .regular)
    advertiserLabel.textColor = palette.color("overlay_caption")
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
    callToActionLabel.textColor = palette.color("overlay_cta_text")
    callToActionLabel.backgroundColor = palette.color("cta_background")
    callToActionLabel.textAlignment = .center
    callToActionLabel.layer.cornerRadius = 19
    callToActionLabel.clipsToBounds = true
    callToActionLabel.isHidden = nativeAd.callToAction == nil
    overlayView.addSubview(callToActionLabel)
    adView.callToActionView = callToActionLabel

    // 视频静音播放
    nativeAd.mediaContent.videoController.isMuted = true

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
  private static let splashAdAudioChannelName = "com.topread.novel/splash_ad_audio"
  private static let getAdvertisingIdMethod = "getAdvertisingId"
  private static let isLimitAdTrackingEnabledMethod = "isLimitAdTrackingEnabled"
  private static let getTrackingAuthorizationStatusMethod = "getTrackingAuthorizationStatus"
  private static let setSplashAdMutedMethod = "setMuted"
  private static let masonryNativeAdFactoryID = "masonryNativeAdCard"
  private static let shortStoryNativeAdFactoryID = "shortStoryNativeAdCard"
  private var readerBrightnessChannel: FlutterMethodChannel?
  private var readerBrightnessPreview: UIView?
  private var readerBrightnessPreviewValue: Double?
  private var readerBrightnessAppliedPhysical: Double?
  private var badgeChannel: FlutterMethodChannel?
  private var advertisingInfoChannel: FlutterMethodChannel?
  private var masonryNativeAdLayoutChannel: FlutterMethodChannel?
  private var shortStoryNativeAdLayoutChannel: FlutterMethodChannel?
  private var splashAdAudioChannel: FlutterMethodChannel?
  private let masonryNativeAdFactory = MasonryNativeAdFactory()
  private let shortStoryNativeAdFactory = ShortStoryNativeAdFactory()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 开屏广告要求始终静音。必须在 Google Mobile Ads 插件注册和 SDK
    // 初始化前同时设置静音状态与相对音量，避免 iOS 以默认音量创建广告素材。
    MobileAds.shared.isApplicationMuted = true
    MobileAds.shared.applicationVolume = 0

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TileQuestAudioPlugin") {
      TileQuestAudioPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WindowDisplayFeaturesPlugin") {
      WindowDisplayFeaturesPlugin.register(with: registrar)
    }

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

    // 阅读亮度只调整当前屏幕，进入/退出的原值由 Flutter 阅读会话配对保存与恢复。
    let readerBrightnessChannel = FlutterMethodChannel(
      name: "com.topread.novel/reader_brightness",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let readerBrightnessRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ComicReaderBrightness")
    readerBrightnessChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      // 用当前 Flutter 引擎所属场景的屏幕；多窗口或外接屏不能总是写 UIScreen.main。
      let readerWindow = readerBrightnessRegistrar?.viewController?.viewIfLoaded?.window
        ?? self.window
      let readerScreen = readerWindow?.windowScene?.screen ?? UIScreen.main
      switch call.method {
      case "getBrightness":
        let brightness = Double(readerScreen.brightness)
        #if targetEnvironment(simulator)
          let arguments = call.arguments as? [String: Any]
          if arguments?["reset_preview"] as? Bool == true {
            // Hot restart不会销毁AppDelegate，旧Dart会话的预览不能变成新会话的系统亮度。
            self.readerBrightnessPreview?.removeFromSuperview()
            self.readerBrightnessPreview = nil
            self.readerBrightnessPreviewValue = nil
            self.readerBrightnessAppliedPhysical = nil
          }
          if let applied = self.readerBrightnessAppliedPhysical,
            abs(applied - brightness) > 0.001 {
            // 控制中心改变了真实值时，同步阅读预览；不能一直返回上一次滑块值。
            self.readerBrightnessPreview?.alpha = CGFloat((1 - brightness) * 0.75)
            self.readerBrightnessPreviewValue = brightness
            self.readerBrightnessAppliedPhysical = brightness
          }
          // 模拟器没有背光，未设置阅读遮罩时呈现的就是满亮画面，不能显示虚假的中间值。
          let previewValue = self.readerBrightnessPreview?.superview == nil
            ? 1.0 : self.readerBrightnessPreviewValue ?? 1.0
          result(["brightness": previewValue, "override": brightness])
        #else
        result(["brightness": brightness, "override": brightness])
        #endif
      case "setBrightness", "restoreBrightness":
        guard let arguments = call.arguments as? [String: Any],
          let value = arguments["value"] as? NSNumber,
          value.doubleValue.isFinite
        else {
          result(FlutterError(code: "invalid_brightness", message: "Brightness must be finite.", details: nil))
          return
        }
        let brightness = min(1, max(0, value.doubleValue))
        readerScreen.brightness = CGFloat(brightness)
        #if targetEnvironment(simulator)
          // 模拟器没有独立背光：仅模拟器使用不可交互遮罩预览变化，真机始终只写真实屏幕亮度。
          if call.method == "restoreBrightness" {
            self.readerBrightnessPreview?.removeFromSuperview()
            self.readerBrightnessPreview = nil
            self.readerBrightnessPreviewValue = nil
            self.readerBrightnessAppliedPhysical = nil
          } else if let readerWindow = readerWindow,
            let previewColor = arguments["preview_color"] as? NSNumber {
            let preview = self.readerBrightnessPreview ?? UIView(frame: readerWindow.bounds)
            preview.backgroundColor = flutterColor(previewColor)
            preview.isUserInteractionEnabled = false
            preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            preview.alpha = CGFloat((1 - brightness) * 0.75)
            if preview.superview !== readerWindow {
              preview.removeFromSuperview()
              readerWindow.addSubview(preview)
            }
            readerWindow.bringSubviewToFront(preview)
            self.readerBrightnessPreview = preview
            self.readerBrightnessPreviewValue = brightness
            self.readerBrightnessAppliedPhysical = Double(readerScreen.brightness)
          }
        #endif
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.readerBrightnessChannel = readerBrightnessChannel

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

    let splashAdAudioChannel = FlutterMethodChannel(
      name: Self.splashAdAudioChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    splashAdAudioChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleSplashAdAudioMethodCall(call, result: result)
    }
    self.splashAdAudioChannel = splashAdAudioChannel
  }

  /// 在开屏广告展示期间直接静音 iOS 应用音频输出。
  ///
  /// Google 的广告音量设置只保证遵守该设置的广告素材静音。
  /// iOS 26 起通过系统音频会话将当前 App 的输出样本归零，
  /// 广告关闭后由 Flutter 立即恢复。
  private func handleSplashAdAudioMethodCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard call.method == Self.setSplashAdMutedMethod else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let muted = arguments["muted"] as? Bool
    else {
      result(
        FlutterError(
          code: "invalid_splash_ad_audio_state",
          message: "Splash ad muted state must be a boolean.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 26.0, *) else {
      // 低版本 iOS 没有应用音频输出静音 API，继续使用 Google SDK 静音。
      result(nil)
      return
    }

    do {
      let audioVideoManager = MobileAds.shared.audioVideoManager
      let audioSession = AVAudioSession.sharedInstance()
      if muted {
        // 广告期间由 App 管理音频会话，防止 SDK 重新配置会话导致静音失效。
        audioVideoManager.isAudioSessionApplicationManaged = true
      }
      try audioSession.setOutputMuted(muted)
      if !muted {
        audioVideoManager.isAudioSessionApplicationManaged = false
      }
#if DEBUG
      print("[SplashScreenAd] iOS outputMuted=\(audioSession.isOutputMuted)")
#endif
      result(nil)
    } catch {
      if muted {
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = false
      }
      result(
        FlutterError(
          code: "splash_ad_audio_update_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
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

  /// 当 UMP 未触发 ATT 系统弹窗时，由 Dart 层兜底调用此方法直接请求 ATT 授权。
  private static let requestTrackingAuthorizationMethod = "requestTrackingAuthorization"

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
    case Self.requestTrackingAuthorizationMethod:
      requestTrackingAuthorization(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 直接调用 iOS ATT 系统弹窗，返回授权后的状态字符串。
  ///
  /// 仅在 ATT 状态为 notDetermined 时调用，其他状态直接返回当前状态。
  private func requestTrackingAuthorization(result: @escaping FlutterResult) {
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
      result(trackingAuthorizationStatusName(ATTrackingManager.trackingAuthorizationStatus))
      return
    }
    ATTrackingManager.requestTrackingAuthorization { status in
      DispatchQueue.main.async {
        result(self.trackingAuthorizationStatusName(status))
      }
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
