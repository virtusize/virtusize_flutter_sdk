import Flutter
import UIKit
import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {
	
	private var flutterChannel: FlutterMethodChannel?
	
	private let repository = VirtusizeFlutterRepository.shared
	private var workItem: DispatchWorkItem?
	private var product: VirtusizeProduct?
	private var productCheckData: [String: Any]?
	private var storeProduct: VirtusizeStoreProduct? = nil
	private var productTypes: [VirtusizeProductType]? = nil
	private var i18nLocalization: VirtusizeI18nLocalization? = nil
	private var userSessionResponse: String? = ""
	private var userProducts: [VirtusizeStoreProduct]? = nil
	private var bodyProfileRecommendedSize: BodyProfileRecommendedSize? = nil
	private var selectedUserProductId: Int? = nil

	init(channel: FlutterMethodChannel) {
		flutterChannel = channel
	}
	
	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "com.virtusize/virtusize_flutter_plugin", binaryMessenger: registrar.messenger())
		let instance = SwiftVirtusizeFlutterPlugin(channel: channel)
		registrar.addMethodCallDelegate(instance, channel: channel)
	}
	
	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
			case "setVirtusizeProps":
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				if let apiKey = arguments["apiKey"] as? String {
					Virtusize.APIKey = apiKey
				} else {
					result(FlutterError.argumentNotSet("apiKey"))
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
			case "getProductDataCheck":
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				guard let productId = arguments["externalId"] as? String   else {
					result(FlutterMethodNotImplemented)
					return
				}
				
				var imageURL: URL? = nil
				if let imageURLString = arguments["imageUrl"] as? String {
					imageURL = URL(string: imageURLString)
				}
				
				DispatchQueue.main.async {
					var pdcJsonString: String? = nil
					(self.product, pdcJsonString) = self.repository.getProductDataCheck(
						product:
							VirtusizeProduct(
								externalId: productId,
								imageURL: imageURL
							)
					)
					self.productCheckData = self.product?.dictionary["data"] as? [String: Any]
					result(pdcJsonString)
				}
			case "openVirtusizeWebView":
				if let viewController = VirtusizeWebViewController(
					product: product,
					userSessionResponse: userSessionResponse,
					eventHandler: self,
					processPool: Virtusize.processPool) {
					let flutterRootViewController = UIApplication.shared.windows.first?.rootViewController
					flutterRootViewController?.present(viewController, animated: true)
				}
			case "getRecommendationText":
				guard let storeProductId = self.productCheckData?["productDataId"] as? Int else {
					result(FlutterError.unKnownError)
					return
				}
				workItem = DispatchWorkItem {
					self.fetchInitialData(result, storeProductId: storeProductId)
					self.updateUserSession(result)
					self.getRecommendation(result)
				}
				DispatchQueue.main.async(execute: workItem!)
			default:
				result(FlutterMethodNotImplemented)
		}
	}
	
	private func fetchInitialData(_ result: @escaping FlutterResult, storeProductId: Int) {
		storeProduct = repository.getStoreProduct(productId: storeProductId)
		if storeProduct == nil {
			result(FlutterError.nullAPIResult("storeProduct"))
			workItem?.cancel()
		}
		
		productTypes = repository.getProductTypes()
		if productTypes == nil {
			result(FlutterError.nullAPIResult("productTypes"))
			workItem?.cancel()
		}

		i18nLocalization = repository.getI18nLocalization()
		if i18nLocalization == nil {
			result(FlutterError.nullAPIResult("i18nLocalization"))
			workItem?.cancel()
		}
	}
	
	private func updateUserSession(_ result: FlutterResult? = nil) {
		userSessionResponse = repository.getUserSessionResponse()
		if userSessionResponse == nil {
			if let result = result {
				result(FlutterError.nullAPIResult("userSessionResponse"))
			} else {
				flutterChannel?.invokeMethod("onRecTextChange", arguments: nil)
			}
			workItem?.cancel()
		}
	}
	
	private func getRecommendation(
		_ result: FlutterResult? = nil,
		selectedRecommendedType: SizeRecommendationType? = nil,
		shouldUpdateUserProducts: Bool = true,
		shouldUpdateUserBodyProfile: Bool = true
	) {
		if shouldUpdateUserProducts {
			userProducts = repository.getUserProducts()
			if userProducts == nil {
				if let result = result {
					result(FlutterError.nullAPIResult("userProducts"))
				} else {
					flutterChannel?.invokeMethod("onRecTextChange", arguments: nil)
				}
				workItem?.cancel()
			}
		}

		if shouldUpdateUserBodyProfile {
			let userBodyProfile = repository.getUserBodyProfile()
			bodyProfileRecommendedSize = (userBodyProfile != nil) ?
				repository.getBodyProfileRecommendedSize(
					productTypes: productTypes!,
					storeProduct: storeProduct!,
					userBodyProfile: userBodyProfile!
				)
				: nil
		}
		

		let recText = repository.getRecommendationText(
			selectedRecType: selectedRecommendedType,
			userProducts: (selectedUserProductId != nil) ?
				userProducts?.filter { $0.id == selectedUserProductId } : userProducts,
			storeProduct: storeProduct!,
			productTypes: productTypes!,
			bodyProfileRecommendedSize: bodyProfileRecommendedSize,
			i18nLocalization: i18nLocalization!
		)
		
		if let result = result {
			result(recText)
		} else {
			flutterChannel?.invokeMethod("onRecTextChange", arguments: recText)
		}
	}
}

extension SwiftVirtusizeFlutterPlugin: VirtusizeEventHandler {
	public func userOpenedWidget() {
		
	}
	
	public func userAuthData(bid: String?, auth: String?) {
		
	}
	
	public func userLoggedIn() {
		
	}
	
	public func clearUserData() {
		
	}
	
	public func userSelectedProduct(userProductId: Int?) {
		
	}
	
	public func userAddedProduct(userProductId: Int?) {
		
	}
	
	public func userUpdatedBodyMeasurements(recommendedSize: String?) {
		
	}
	
	public func userChangedRecommendationType(changedType: SizeRecommendationType?) {
		
	}
}
