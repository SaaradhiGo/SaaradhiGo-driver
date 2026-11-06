import AudioToolbox
import Flutter
import GoogleMaps
import UIKit

// The Google Maps iOS SDK (owner decision D1, 2026-11-02). The key comes from
// the `GMSApiKey` entry in Info.plist, `$(MAPS_API_KEY)`: an xcconfig value fed
// by a CI secret and restricted to this bundle ID. Never write a key here.
// With no key the app still starts; the map simply has no tiles.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !key.isEmpty, !key.hasPrefix("$(")
    {
      GMSServices.provideAPIKey(key)
    }
    GeneratedPluginRegistrant.register(with: self)
    // The offer chime. An alert sound follows the silent switch: it buzzes
    // instead of playing when the phone is on silent.
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "saaradhigo/alert", binaryMessenger: controller.binaryMessenger)
        .setMethodCallHandler { call, result in
          if call.method == "offer" {
            AudioServicesPlayAlertSound(SystemSoundID(1007))
            result(nil)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
