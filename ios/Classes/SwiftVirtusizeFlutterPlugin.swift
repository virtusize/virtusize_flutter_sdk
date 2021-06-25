import Flutter
import UIKit
import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.virtusize/virtusize_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftVirtusizeFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
	if(call.method == "setVirtusizeProps") {
		guard let arguments = call.arguments as? [String: Any] else {
			result(
				FlutterError(code: "-1", message: "Missing Arguments: apiKey is null", details: nil)
			)
			return
		}
		if let apiKey = arguments["apiKey"] as? String {
			Virtusize.APIKey = apiKey
		} else {
			result(
				FlutterError(code: "-1", message: "Missing Arguments: apiKey is null", details: nil)
			)
		}

		if let userID = arguments["externalUserId"] as? String {
			Virtusize.userID = userID
		}

		if let envStr = arguments["env"] as? String,
		   let env = VirtusizeEnvironment.allCases.first(where: { "\($0.self)" == envStr.lowercased() }) {
			Virtusize.environment = env
		}

		var virtusizeBuilder = VirtusizeParamsBuilder()
		
		if let langStr = arguments["language"] as? String,
		   let lang = VirtusizeLanguage.allCases.first(where: { $0.rawValue == langStr.lowercased() })
		   {
			virtusizeBuilder = virtusizeBuilder.setLanguage(lang)
		}
		
		if let showSGI = arguments["showSGI"] as? Bool {
			virtusizeBuilder = virtusizeBuilder.setShowSGI(showSGI)
		}
	
		if let allowedLangStrArray = arguments["allowedLanguages"] as? [String] {
			let allowedLangs = VirtusizeLanguage.allCases
				.filter{ allowedLangStrArray.contains($0.shortDescription) }
			virtusizeBuilder = virtusizeBuilder.setAllowedLanguages(allowedLangs)
		}
		
		if let detailsPanelCardsStrArray = arguments["detailsPanelCards"] as? [String] {
			let detailsPanelCards = VirtusizeInfoCategory.allCases
				.filter{ detailsPanelCardsStrArray
					.map {
						$0.replacingOccurrences(of: "_", with: "")
					}
					.contains("\($0.self)")
				}
			virtusizeBuilder = virtusizeBuilder.setDetailsPanelCards(detailsPanelCards)
		}
		
		Virtusize.params = virtusizeBuilder.build()
	}
  }
}
