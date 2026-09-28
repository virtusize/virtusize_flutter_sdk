import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // With the UIScene lifecycle, URLs are delivered to the scene delegate instead of
    // `application(_:open:options:)`, so forward them to the Virtusize plugin from here.
    engineBridge.pluginRegistry
      .registrar(forPlugin: "VirtusizeURLHandler")?
      .addSceneDelegate(VirtusizeURLHandler())
  }
}

class VirtusizeURLHandler: NSObject, FlutterSceneLifeCycleDelegate {
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    for context in URLContexts {
      NotificationCenter.default.post(
        name: Notification.Name("VirtusizeFlutterHandleURL"),
        object: context.url
      )
    }
    return false
  }
}
