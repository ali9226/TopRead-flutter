import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let badgeChannelName = "com.topread.app/badge"
  private static let setBadgeCountMethod = "setBadgeCount"
  private var badgeChannel: FlutterMethodChannel?

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
}
