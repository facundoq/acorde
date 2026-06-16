import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let wakelockChannel = FlutterMethodChannel(name: "com.example.acorde/wakelock",
                                                binaryMessenger: controller.binaryMessenger)
      wakelockChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "enable" {
          UIApplication.shared.isIdleTimerDisabled = true
          result(nil)
        } else if call.method == "disable" {
          UIApplication.shared.isIdleTimerDisabled = false
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
    
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
