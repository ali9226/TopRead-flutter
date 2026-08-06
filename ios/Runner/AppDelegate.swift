import AdSupport
import AppTrackingTransparency
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let badgeChannelName = "com.topread.app/badge"
  private static let setBadgeCountMethod = "setBadgeCount"
  private static let advertisingInfoChannelName = "com.topread.novel/advertising_info"
  private static let getAdvertisingIdMethod = "getAdvertisingId"
  private static let isLimitAdTrackingEnabledMethod = "isLimitAdTrackingEnabled"
  private var badgeChannel: FlutterMethodChannel?
  private var advertisingInfoChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

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
      getAdvertisingId(call, result: result)
    case Self.isLimitAdTrackingEnabledMethod:
      result(isLimitAdTrackingEnabled())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getAdvertisingId(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let status = ATTrackingManager.trackingAuthorizationStatus
    NSLog("Debug: ATT trackingAuthorizationStatus: \(status.rawValue)")
    
    switch status {
    case .authorized:
      let id = nonZeroAdvertisingIdentifier()
      NSLog("Debug: ATT authorized, advertisingId: \(id ?? "nil")")
      result(id)
    case .notDetermined:
      let arguments = call.arguments as? [String: Any]
      let shouldRequestAuthorization =
        arguments?["requestTrackingAuthorization"] as? Bool ?? false
      NSLog("Debug: ATT notDetermined, requestTrackingAuthorization: \(shouldRequestAuthorization)")
      guard shouldRequestAuthorization else {
        result(nil)
        return
      }
      ATTrackingManager.requestTrackingAuthorization { [weak self] status in
        DispatchQueue.main.async {
          NSLog("Debug: ATT requestTrackingAuthorization result: \(status.rawValue)")
          guard status == .authorized else {
            result(nil)
            return
          }
          let id = self?.nonZeroAdvertisingIdentifier()
          NSLog("Debug: ATT authorized after request, advertisingId: \(id ?? "nil")")
          result(id)
        }
      }
    case .denied:
      NSLog("Debug: ATT denied")
      result(nil)
    case .restricted:
      NSLog("Debug: ATT restricted")
      result(nil)
    @unknown default:
      NSLog("Debug: ATT unknown status: \(status.rawValue)")
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
}
