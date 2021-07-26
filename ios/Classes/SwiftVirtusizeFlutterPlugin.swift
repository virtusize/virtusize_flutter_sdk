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

	/// A stack implemented by a list to record the visited order of the external product IDs that are tied with the Virtusize widgets created on a client's app
	private var externalProductIDStack: [String] = []

	/// A set to cache the store product information of all the visited products
	private var serverStoreProductSet: Set<VirtusizeServerProduct> = []

	/// The most recent visited store product on a client's app
	private var storeProduct: VirtusizeServerProduct? {
		get {
			serverStoreProductSet.filter({ $0.externalId == externalProductIDStack.last }).first
		}
	}

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
				if let apiKey = arguments[VirtusizeFlutterKey.apiKey] as? String {
					Virtusize.APIKey = apiKey
				} else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.apiKey))
				}

				if let userID = arguments[VirtusizeFlutterKey.externalUserID] as? String {
					Virtusize.userID = userID
				}
				
				if let envStr = arguments[VirtusizeFlutterKey.env] as? String,
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
					VirtusizeFlutterKey.virtusizeProps: arguments,
					VirtusizeFlutterKey.displayLanguage: Virtusize.displayLanguage?.rawValue
				])
			case "setUserID":
				guard let userID = call.arguments as? String, !userID.isEmpty else {
					result(FlutterError.invalidUserID)
					return
				}
				Virtusize.userID = userID
			case "getProductDataCheck":
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				guard let productId = arguments[VirtusizeFlutterKey.externalProductID] as? String   else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.externalProductID))
					return
				}
				
				var imageURL: URL? = nil
				if let imageURLString = arguments[VirtusizeFlutterKey.imageUrl] as? String {
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
			case "openVirtusizeWebView":
				let product = storeProductSet.first { $0.externalId == externalProductIDStack.last }
				if let viewController = VirtusizeWebViewController(
					product: product,
					userSessionResponse: userSessionResponse,
					messageHandler: self,
					processPool: Virtusize.processPool) {
					let flutterRootViewController = UIApplication.shared.windows.first?.rootViewController
					flutterRootViewController?.present(viewController, animated: true)
				}
			case "getRecommendationText":
				guard let storeProductId = call.arguments as? Int else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.productID))
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
			case "getPrivacyPolicyLink":
				result(repository.getPrivacyPolicyLink())
			case "sendOrder":
				guard let orderDict = call.arguments as? [String : Any?] else {
					result(FlutterError.noArguments)
					return
				}
				repository.sendOrder(orderDict, onSuccess: {
					result(orderDict)
				},onError: { error in
					result(FlutterError.sendOrder(error.localizedDescription))
				})
			case "addProduct":
				guard let externalProductId = call.arguments as? String else {
					result(FlutterError.argumentNotSet(VirtusizeFlutterKey.externalProductID))
					return
				}
				
				externalProductIDStack.append(externalProductId)
			case "removeProduct":
				externalProductIDStack.removeLast()
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

		flutterChannel?.invokeMethod(
			"onProduct",
			arguments: [
				VirtusizeFlutterKey.productID: storeProduct!.id,
				VirtusizeFlutterKey.imageType: "store",
				VirtusizeFlutterKey.imageUrl: storeProduct!.cloudinaryImageUrlString,
				VirtusizeFlutterKey.productType: storeProduct!.productType,
				VirtusizeFlutterKey.productStyle: storeProduct!.productStyle
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
				flutterChannel?.invokeMethod(
					VirtusizeFlutterMethod.recChange,
					arguments: [
						VirtusizeFlutterKey.externalProductID: storeProduct!.externalId,
						VirtusizeFlutterKey.recText: nil,
						VirtusizeFlutterKey.showUserProductImage: false
					]
				)
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
		var storeProduct = storeProduct
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
					flutterChannel?.invokeMethod(
						VirtusizeFlutterMethod.recChange,
						arguments: [
							VirtusizeFlutterKey.externalProductID: storeProduct!.externalId,
							VirtusizeFlutterKey.recText: nil,
							VirtusizeFlutterKey.showUserProductImage: false
						]
					)
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

		flutterChannel?.invokeMethod(
			VirtusizeFlutterMethod.product,
			arguments:  [
				VirtusizeFlutterKey.productID: storeProduct!.id,
				VirtusizeFlutterKey.imageType: "user",
				VirtusizeFlutterKey.imageUrl : userProductRecommendedSize?.bestUserProduct?.cloudinaryImageUrlString,
				VirtusizeFlutterKey.productType: userProductRecommendedSize?.bestUserProduct?.productType,
				VirtusizeFlutterKey.productStyle: userProductRecommendedSize?.bestUserProduct?.productStyle
			]
		)
		
		let recText = repository.getRecommendationText(
			selectedRecType: selectedRecommendedType,
			storeProduct: storeProduct!,
			userProductRecommendedSize: userProductRecommendedSize,
			bodyProfileRecommendedSize: bodyProfileRecommendedSize,
			i18nLocalization: i18nLocalization!
		)
		
		let arguments: [String : Any] = [
			VirtusizeFlutterKey.externalProductID: storeProduct!.externalId,
			VirtusizeFlutterKey.recText: recText,
			VirtusizeFlutterKey.showUserProductImage: userProductRecommendedSize?.bestUserProduct != nil
		]

		if let result = result {
			result(arguments)
		} else {
			flutterChannel?.invokeMethod(
				VirtusizeFlutterMethod.recChange,
				arguments: arguments
			)
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
			self?.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.vsError, arguments: error.debugDescription)
		}
		DispatchQueue.global().async(execute: currentWorkItem!)
	}
	
	public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveEvent event: VirtusizeEvent) {
		let eventsWorkItem = DispatchWorkItem { [weak self] in
			if let eventData = event.data as? [String: Any],
			   let eventName = eventData[VirtusizeEventKey.shortEventName] ?? eventData[VirtusizeEventKey.eventName] {
				self?.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.vsEvent, arguments: eventName)
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
				let shouldUpdateBodyProfileRecommendedSize = bodyProfileRecommendedSize?.product?.externalId != storeProduct?.externalId

				recommendationWorkItem = DispatchWorkItem { [weak self] in
					self?.getRecommendation(
						self?.currentWorkItem,
						shouldUpdateUserProducts: false,
						shouldUpdateUserBodyProfile: false,
						shouldUpdateBodyProfileRecommendedSize: shouldUpdateBodyProfileRecommendedSize
					)
				}
			case .userAuthData:
				if let data = event.data as? [String: Any] {
					repository.updateUserAuthData(bid: data["x-vs-bid"] as? String, auth: data["x-vs-auth"] as? String)
				}
			case .userSelectedProduct:
				if let userProductId = (event.data as? [String: Any])?[VirtusizeEventKey.userProductID] as? Int {
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
				if let userProductId = (event.data as? [String: Any])?[VirtusizeEventKey.userProductID] as? Int {
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
				let recommendationType = (event.data as? [String: Any])?[VirtusizeEventKey.recType] as? String
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
				if let sizeRecName = (event.data as? [String: Any])?[VirtusizeEventKey.sizeRecName] as? String {
					bodyProfileRecommendedSize = BodyProfileRecommendedSize(sizeName: sizeRecName, product: storeProduct)
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
