import Flutter
import UIKit

import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.virtusize/virtusize_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftVirtusizeFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

	let factory = FLVirtusizeWebViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "VirtusizeWebView")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
