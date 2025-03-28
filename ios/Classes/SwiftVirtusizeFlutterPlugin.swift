import Flutter
import UIKit
import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {

	/// The FlutterMethodChannel that will create the communication between Flutter and native iOS
	private var flutterChannel: FlutterMethodChannel?

	private let repository = VirtusizeFlutterRepository.shared
	private var currentWorkItem: DispatchWorkItem?

	/// A set to cache the product data check data of all the visited products
	private var storeProductSet: Set<VirtusizeProduct> = []

	/// A set to cache the store product information of all the visited products
	private var serverStoreProductSet: Set<VirtusizeServerProduct> = []

	/// The last visited store product on the Virtusize webview
	private var lastProductOnVirtusizeWebView: VirtusizeServerProduct?

	private var productTypes: [VirtusizeProductType]? = nil
	private var i18nLocalization: VirtusizeI18nLocalization? = nil
	private var userSessionResponse: String? = ""
	private var userProducts: [VirtusizeServerProduct]? = nil
	private var userBodyProfile: VirtusizeUserBodyProfile? = nil
	private var bodyProfileRecommendedSize: BodyProfileRecommendedSize? = nil
	private var selectedUserProductId: Int? = nil

	init(channel: FlutterMethodChannel) {
		flutterChannel = channel
	}
	
	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "com.virtusize/flutter_virtusize_sdk", binaryMessenger: registrar.messenger())
		let instance = SwiftVirtusizeFlutterPlugin(channel: channel)
		registrar.addMethodCallDelegate(instance, channel: channel)
	}
	
	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
			case VirtusizeFlutterMethod.setVirtusizeParams:
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				if let apiKey = arguments[VirtusizeFlutterKey.apiKey] as? String {
					Virtusize.APIKey = apiKey
				} else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.apiKey))
				}

				if let userId = arguments[VirtusizeFlutterKey.externalUserId] as? String {
					Virtusize.userID = userId
				}
				
				if let envStr = arguments[VirtusizeFlutterKey.environment] as? String,
				   let env = VirtusizeEnvironment.allCases.first(where: { "\($0.self)" == envStr.lowercased() }) {
					Virtusize.environment = env
				}
				
				var virtusizeBuilder = VirtusizeParamsBuilder()
				
				if let langStr = arguments[VirtusizeFlutterKey.language] as? String,
				   let lang = VirtusizeLanguage.allCases.first(where: { $0.langStr == langStr })
				{
					virtusizeBuilder = virtusizeBuilder.setLanguage(lang)
				}
				
				if let showSGI = arguments[VirtusizeFlutterKey.showSGI] as? Bool {
					virtusizeBuilder = virtusizeBuilder.setShowSGI(showSGI)
				}
				
				if let allowedLangStrArray = arguments[VirtusizeFlutterKey.allowedLanguages] as? [String] {
					let allowedLangs = VirtusizeLanguage.allCases
						.filter{ allowedLangStrArray.contains($0.langStr) }
					virtusizeBuilder = virtusizeBuilder.setAllowedLanguages(allowedLangs)
				}
				
				if let detailsPanelCardsStrArray = arguments[VirtusizeFlutterKey.detailsPanelCards] as? [String] {
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
				result([
					VirtusizeFlutterKey.virtusizeParams: arguments,
					VirtusizeFlutterKey.displayLanguage: Virtusize.displayLanguage?.rawValue
				])
			case VirtusizeFlutterMethod.setUserId:
				guard let userId = call.arguments as? String, !userId.isEmpty else {
					result(FlutterError.invalidUserID)
					return
				}
				Virtusize.userID = userId
			case VirtusizeFlutterMethod.getProductDataCheck:
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				guard let productId = arguments[VirtusizeFlutterKey.externalProductId] as? String   else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.externalProductId))
					return
				}
				
				var imageURL: URL? = nil
				if let imageURLString = arguments[VirtusizeFlutterKey.imageURL] as? String {
					imageURL = URL(string: imageURLString)
				}
				
				DispatchQueue.global().async {
					let (product, pdcJsonString) = self.repository.getProductDataCheck(
						messageHandler: self,
						product:
							VirtusizeProduct(
								externalId: productId,
								imageURL: imageURL
							)
					)
					if let product = product {
						self.storeProductSet.insert(product)
					}
					result(pdcJsonString)
				}
			case VirtusizeFlutterMethod.openVirtusizeWebView:
				guard let externalProductId = call.arguments as? String else {
					result(FlutterError.noArguments)
					return
				}
				lastProductOnVirtusizeWebView = serverStoreProductSet.first { $0.externalId == externalProductId}
				let product = storeProductSet.first { $0.externalId == externalProductId }
				if let viewController = VirtusizeWebViewController(
					product: product,
					userSessionResponse: userSessionResponse,
					messageHandler: self,
					processPool: Virtusize.processPool) {
					let flutterRootViewController = UIApplication.shared.windows.first?.rootViewController
					flutterRootViewController?.present(viewController, animated: true)
				}
			case VirtusizeFlutterMethod.getRecommendationText:
				guard let storeProductId = call.arguments as? Int else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.storeProductId))
					return
				}

				let initialDataWorkItem = DispatchWorkItem { [weak self] in
					self?.fetchInitialData(self?.currentWorkItem, result, storeProductId: storeProductId)
				}
				
				let userDataWorkItem = DispatchWorkItem { [weak self] in
					self?.updateUserSession(self?.currentWorkItem, result)
				}
				
				let recommendationItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(self?.currentWorkItem, result, storeProductId: storeProductId)
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
			case VirtusizeFlutterMethod.getPrivacyPolicyLink:
				result(repository.getPrivacyPolicyLink())
			case VirtusizeFlutterMethod.sendOrder:
				guard let orderDict = call.arguments as? [String : Any?] else {
					result(FlutterError.noArguments)
					return
				}
				repository.sendOrder(orderDict, onSuccess: {
					result(orderDict)
				},onError: { error in
					result(FlutterError.sendOrder(error.localizedDescription))
				})
			default:
				result(FlutterMethodNotImplemented)
		}
	}
	
	private func fetchInitialData(_ workItem: DispatchWorkItem?, _ result: @escaping FlutterResult, storeProductId: Int) {
		selectedUserProductId = nil
		
		let storeProduct = repository.getStoreProduct(productId: storeProductId)
		if storeProduct == nil {
			result(FlutterError.nullAPIResult("storeProduct"))
			workItem?.cancel()
			return
		}
		
		self.serverStoreProductSet.insert(storeProduct!)

		DispatchQueue.main.async {
			self.flutterChannel?.invokeMethod(
				VirtusizeFlutterMethod.onProduct,
				arguments: [
					VirtusizeFlutterKey.externalProductId: storeProduct!.externalId,
					VirtusizeFlutterKey.imageType: "store",
					VirtusizeFlutterKey.imageURL: storeProduct!.cloudinaryImageUrlString,
					VirtusizeFlutterKey.productType: storeProduct!.productType,
					VirtusizeFlutterKey.productStyle: storeProduct!.productStyle
				]
			)
		}

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
				DispatchQueue.main.async {
					self.flutterChannel?.invokeMethod(
						VirtusizeFlutterMethod.onRecChange,
						arguments: [
							VirtusizeFlutterKey.externalProductId: self.lastProductOnVirtusizeWebView!.externalId,
							VirtusizeFlutterKey.recText: nil,
							VirtusizeFlutterKey.showUserProductImage: false
						]
					)
				}
			}
			workItem?.cancel()
			return
		}
	}
	
	private func getRecommendation(
		_ workItem: DispatchWorkItem?,
		_ result: FlutterResult? = nil,
		storeProductId: Int? = nil,
		selectedRecommendedType: SizeRecommendationType? = nil,
		shouldUpdateUserProducts: Bool = true,
		shouldUpdateUserBodyProfile: Bool = true,
		shouldUpdateBodyProfileRecommendedSize: Bool = false
	) {
		// The default store product to use for the recommendation is the most recent one
		// But if the store product ID is not null, we update the store product value
		var storeProduct = lastProductOnVirtusizeWebView
		if let productId = storeProductId,
		   let product = serverStoreProductSet.filter({ product in
			product.id == productId
		   }).first {
			storeProduct = product
		}

		if shouldUpdateUserProducts {
			userProducts = repository.getUserProducts()
			if userProducts == nil {
				if let result = result {
					result(FlutterError.nullAPIResult("userProducts"))
				} else {
					DispatchQueue.main.async {
						self.flutterChannel?.invokeMethod(
							VirtusizeFlutterMethod.onRecChange,
							arguments: [
								VirtusizeFlutterKey.externalProductId: storeProduct!.externalId,
								VirtusizeFlutterKey.recText: nil,
								VirtusizeFlutterKey.showUserProductImage: false
							]
						)
					}
				}
				workItem?.cancel()
				return
			}
		}

		let errorCode: Int?
		if shouldUpdateUserBodyProfile {
			(userBodyProfile, errorCode) = repository.getUserBodyProfile()
			if let errorCode = errorCode, errorCode != 404 {
				workItem?.cancel()
				return
			}
		}
		
		if shouldUpdateUserBodyProfile || shouldUpdateBodyProfileRecommendedSize {
			bodyProfileRecommendedSize = (userBodyProfile != nil) ?
				repository.getBodyProfileRecommendedSize(
					productTypes: productTypes!,
					storeProduct: storeProduct!,
					userBodyProfile: userBodyProfile!
				)
				: nil
			bodyProfileRecommendedSize?.product = storeProduct
		}

		let filteredUserProducts = (selectedUserProductId != nil) ?
			userProducts?.filter { $0.id == selectedUserProductId } : userProducts
		
		let userProductRecommendedSize = repository.getUserProductRecommendedSize(
			selectedRecType: selectedRecommendedType,
			userProducts: filteredUserProducts,
			storeProduct: storeProduct!,
			productTypes: productTypes!
		)
		
		DispatchQueue.main.async {
			self.flutterChannel?.invokeMethod(
				VirtusizeFlutterMethod.onProduct,
				arguments:  [
					VirtusizeFlutterKey.externalProductId: storeProduct!.externalId,
					VirtusizeFlutterKey.imageType: "user",
					VirtusizeFlutterKey.imageURL : userProductRecommendedSize?.bestUserProduct?.cloudinaryImageUrlString,
					VirtusizeFlutterKey.productType: userProductRecommendedSize?.bestUserProduct?.productType,
					VirtusizeFlutterKey.productStyle: userProductRecommendedSize?.bestUserProduct?.productStyle
				]
			)
		}
		
		let recText = repository.getRecommendationText(
			selectedRecType: selectedRecommendedType,
			storeProduct: storeProduct!,
			userProductRecommendedSize: userProductRecommendedSize,
			bodyProfileRecommendedSize: bodyProfileRecommendedSize,
			i18nLocalization: i18nLocalization!
		)
		
		let arguments: [String : Any] = [
			VirtusizeFlutterKey.externalProductId: storeProduct!.externalId,
			VirtusizeFlutterKey.recText: recText,
			VirtusizeFlutterKey.showUserProductImage: userProductRecommendedSize?.bestUserProduct != nil
		]

		if let result = result {
			result(arguments)
		} else {
			DispatchQueue.main.async {
				self.flutterChannel?.invokeMethod(
					VirtusizeFlutterMethod.onRecChange,
					arguments: arguments
				)
			}
		}
	}
	
	private func clearUserData() {
		repository.deleteUser()
		
		selectedUserProductId = nil
		userProducts = nil
		bodyProfileRecommendedSize = nil
	}
}

extension SwiftVirtusizeFlutterPlugin: VirtusizeMessageHandler {
	public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveError error: VirtusizeError) {
		currentWorkItem = DispatchWorkItem { [weak self] in
			DispatchQueue.main.async {
				self?.self.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.onVSError, arguments: error.debugDescription)
			}
		}
		DispatchQueue.global().async(execute: currentWorkItem!)
	}
	
	public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveEvent event: VirtusizeEvent) {
	    let eventData = event.data as? [String: Any]
		let eventsWorkItem = DispatchWorkItem { [weak self] in
			if let eventData = eventData,
			   let eventName = eventData[VirtusizeEventKey.shortEventName] ?? eventData[VirtusizeEventKey.eventName] {
				DispatchQueue.main.async {
					self?.self.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.onVSEvent, arguments: eventName)
				}
			}
		}
		
		var userDataWorkItem: DispatchWorkItem = DispatchWorkItem { }
		var recommendationWorkItem: DispatchWorkItem? = nil
		switch VirtusizeEventName.init(rawValue: event.name) {
			case .userOpenedWidget:
				// Unset the selected user product ID
				selectedUserProductId = nil
				
				// If the store product that is associated with the current body profile recommended size is different from the most recent one,
				// we should update the data for the body profile recommended size
				let shouldUpdateBodyProfileRecommendedSize = bodyProfileRecommendedSize?.product?.externalId != lastProductOnVirtusizeWebView?.externalId

				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false,
						shouldUpdateBodyProfileRecommendedSize: shouldUpdateBodyProfileRecommendedSize
					)
				}
			case .userAuthData:
				if let data = eventData {
					repository.updateUserAuthData(bid: data["x-vs-bid"] as? String, auth: data["x-vs-auth"] as? String)
				}
			case .userSelectedProduct:
				if let userProductId = eventData?[VirtusizeEventKey.userProductID] as? Int {
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
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						selectedRecommendedType: SizeRecommendationType.compareProduct,
						shouldUpdateUserBodyProfile: false
					)
				}
			case .userDeletedProduct:
			    if let deletedUserProductId = eventData?[VirtusizeEventKey.userProductID] as? Int {
					userProducts = userProducts?.filter { userProduct in userProduct.id != deletedUserProductId }
                }
				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false
					)
				}
			case .userChangedRecommendationType:
				let recommendationType = eventData?[VirtusizeEventKey.recType] as? String
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
				if let sizeRecName = eventData?[VirtusizeEventKey.sizeRecName] as? String {
					bodyProfileRecommendedSize = BodyProfileRecommendedSize(sizeName: sizeRecName, product: lastProductOnVirtusizeWebView)
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
