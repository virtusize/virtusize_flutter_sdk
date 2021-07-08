import Flutter
import UIKit
import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {
	
	private var flutterChannel: FlutterMethodChannel?
	
	private let repository = VirtusizeFlutterRepository.shared
	private var currentWorkItem: DispatchWorkItem?
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
				
				DispatchQueue.global().async {
					let (product, pdcJsonString) = self.repository.getProductDataCheck(
						product:
							VirtusizeProduct(
								externalId: productId,
								imageURL: imageURL
							)
					)
					self.product = product
					self.productCheckData = self.product?.dictionary["data"] as? [String: Any]
					result(pdcJsonString)
				}
			case "openVirtusizeWebView":
				if let viewController = VirtusizeWebViewController(
					product: product,
					userSessionResponse: userSessionResponse,
					messageHandler: self,
					processPool: Virtusize.processPool) {
					let flutterRootViewController = UIApplication.shared.windows.first?.rootViewController
					flutterRootViewController?.present(viewController, animated: true)
				}
			case "getRecommendationText":
				guard let storeProductId = self.productCheckData?["productDataId"] as? Int else {
					result(FlutterError.unKnownError)
					return
				}
				let initialDataWorkItem = DispatchWorkItem { [weak self] in
					self?.fetchInitialData(self?.currentWorkItem, result, storeProductId: storeProductId)
				}
				
				let userDataWorkItem = DispatchWorkItem { [weak self] in
					self?.updateUserSession(self?.currentWorkItem, result)
				}
				
				let recommendationItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(self?.currentWorkItem, result)
				}

				currentWorkItem = initialDataWorkItem
				DispatchQueue.global().async(execute: initialDataWorkItem)
				
				initialDataWorkItem.notify(queue: .global()) { [weak self] in
					if self?.currentWorkItem?.isCancelled != true {
						self?.currentWorkItem = userDataWorkItem
						userDataWorkItem.perform()
					}
				}
				
				userDataWorkItem.notify(queue: .global()) { [weak self] in
					if self?.currentWorkItem?.isCancelled != true {
						self?.currentWorkItem = recommendationItem
						recommendationItem.perform()
					}
				}
			case "getPrivacyPolicyLink":
				result(repository.getPrivacyPolicyLink())
			default:
				result(FlutterMethodNotImplemented)
		}
	}
	
	private func fetchInitialData(_ workItem: DispatchWorkItem?, _ result: @escaping FlutterResult, storeProductId: Int) {
		storeProduct = repository.getStoreProduct(productId: storeProductId)
		if storeProduct == nil {
			result(FlutterError.nullAPIResult("storeProduct"))
			workItem?.cancel()
			return
		}

		flutterChannel?.invokeMethod(
			"onProduct",
			arguments: [
				"imageType": "store",
				"imageUrl" : storeProduct?.cloudinaryImageUrlString
			]
		)

		productTypes = repository.getProductTypes()
		if productTypes == nil {
			result(FlutterError.nullAPIResult("productTypes"))
			workItem?.cancel()
			return
		}

		i18nLocalization = repository.getI18nLocalization()
		if i18nLocalization == nil {
			result(FlutterError.nullAPIResult("i18nLocalization"))
			workItem?.cancel()
			return
		}
	}
	
	private func updateUserSession(_ workItem: DispatchWorkItem?, _ result: FlutterResult? = nil) {
		userSessionResponse = repository.getUserSessionResponse()
		if userSessionResponse == nil {
			if let result = result {
				result(FlutterError.nullAPIResult("userSessionResponse"))
			} else {
				flutterChannel?.invokeMethod("onRecTextChange", arguments: nil)
			}
			workItem?.cancel()
			return
		}
	}
	
	private func getRecommendation(
		_ workItem: DispatchWorkItem?,
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
				return
			}
		}

		if shouldUpdateUserBodyProfile {
			let (userBodyProfile, errorCode) = repository.getUserBodyProfile()
			if let errorCode = errorCode, errorCode != 404 {
				workItem?.cancel()
				return
			}
			bodyProfileRecommendedSize = (userBodyProfile != nil) ?
				repository.getBodyProfileRecommendedSize(
					productTypes: productTypes!,
					storeProduct: storeProduct!,
					userBodyProfile: userBodyProfile!
				)
				: nil
		}
		
		let filteredUserProducts = (selectedUserProductId != nil) ?
		userProducts?.filter { $0.id == selectedUserProductId } : userProducts
		
		flutterChannel?.invokeMethod(
			"onProduct",
			arguments:  [
				"imageType": "user",
				"imageUrl" : filteredUserProducts?.first?.cloudinaryImageUrlString
			]
		)

		let recText = repository.getRecommendationText(
			selectedRecType: selectedRecommendedType,
			userProducts: filteredUserProducts,
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
	
	private func clearUserData() {
		repository.deleteUser()
		
		userProducts = nil
		bodyProfileRecommendedSize = nil
	}
}

extension SwiftVirtusizeFlutterPlugin: VirtusizeMessageHandler {
	public func virtusizeController(_ controller: VirtusizeWebViewController, didReceiveError error: VirtusizeError) {
		currentWorkItem = DispatchWorkItem { [weak self] in
			self?.flutterChannel?.invokeMethod("onVSError", arguments: error.debugDescription)
		}
		DispatchQueue.global().async(execute: currentWorkItem!)
	}
	
	public func virtusizeController(_ controller: VirtusizeWebViewController, didReceiveEvent event: VirtusizeEvent) {
		let eventsWorkItem = DispatchWorkItem { [weak self] in
			self?.flutterChannel?.invokeMethod("onVSEvent", arguments: event.data)
		}
		
		var userDataWorkItem: DispatchWorkItem = DispatchWorkItem {}
		var recommendationWorkItem: DispatchWorkItem? = nil
		
		switch VirtusizeEventName.init(rawValue: event.name) {
			case .userOpenedWidget:
				selectedUserProductId = nil
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false
					)
				}
			case .userAuthData:
				if let data = event.data as? [String: Any] {
					repository.updateUserAuthData(bid: data["x-vs-bid"] as? String, auth: data["x-vs-auth"] as? String)
				}
			case .userSelectedProduct:
				if let userProductId = (event.data as? [String: Any])?["userProductId"] as? Int {
					selectedUserProductId = userProductId
				}
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						selectedRecommendedType: SizeRecommendationType.compareProduct,
						shouldUpdateUserProducts: false
					)
				}
			case .userAddedProduct:
				if let userProductId = (event.data as? [String: Any])?["userProductId"] as? Int {
					selectedUserProductId = userProductId
				}
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						selectedRecommendedType: SizeRecommendationType.compareProduct,
						shouldUpdateUserBodyProfile: false
					)
				}
			case .userChangedRecommendationType:
				let recommendationType = (event.data as? [String: Any])?["recommendationType"] as? String
				let changedType = (recommendationType != nil) ? SizeRecommendationType.init(rawValue: recommendationType!) : nil
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						selectedRecommendedType: changedType,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false
					)
				}
			case .userUpdatedBodyMeasurements:
				if let sizeRecName = (event.data as? [String: Any])?["sizeRecName"] as? String {
					bodyProfileRecommendedSize = BodyProfileRecommendedSize(sizeName: sizeRecName)
					recommendationWorkItem = DispatchWorkItem { [weak self] in
						self?.getRecommendation(
							self?.currentWorkItem,
							selectedRecommendedType: SizeRecommendationType.body,
							shouldUpdateUserProducts: false,
							shouldUpdateUserBodyProfile: false
						)
					}
				}
			case .userLoggedIn:
				userDataWorkItem = DispatchWorkItem { [weak self] in
					self?.updateUserSession(self?.currentWorkItem)
				}
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(self?.currentWorkItem)
				}
			case .userLoggedOut, .userDeletedData:
				userDataWorkItem = DispatchWorkItem { [weak self] in
					self?.clearUserData()
					self?.updateUserSession(self?.currentWorkItem)
				}
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false
					)
				}
			default:
				break
		}

		currentWorkItem = eventsWorkItem
		DispatchQueue.global().async(execute: eventsWorkItem)
		
		eventsWorkItem.notify(queue: .global()) { [weak self] in
			if self?.currentWorkItem?.isCancelled != true {
				self?.currentWorkItem = userDataWorkItem
				userDataWorkItem.perform()
			}
		}
		
		userDataWorkItem.notify(queue: .global()) { [weak self] in
			if self?.currentWorkItem?.isCancelled != true {
				self?.currentWorkItem = recommendationWorkItem
				recommendationWorkItem?.perform()
			}
		}
	}
}
