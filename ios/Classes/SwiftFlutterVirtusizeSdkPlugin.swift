import Flutter
import UIKit
import Virtusize

public class SwiftFlutterVirtusizeSdkPlugin: NSObject, FlutterPlugin {
  
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
		let channel = FlutterMethodChannel(name: "com.virtusize/flutter_virtusize_sdk", binaryMessenger: registrar.messenger())
		let instance = SwiftFlutterVirtusizeSdkPlugin(channel: channel)
		registrar.addMethodCallDelegate(instance, channel: channel)
	}
	
	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		switch call.method {
			case FlutterVirtusizeMethod.setVirtusizeParams:
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				if let apiKey = arguments[FlutterVirtusizeKey.apiKey] as? String {
					Virtusize.APIKey = apiKey
				} else {
					result(FlutterError.argumentNotSet(FlutterVirtusizeKey.apiKey))
				}

				if let userId = arguments[FlutterVirtusizeKey.externalUserId] as? String {
					Virtusize.userID = userId
				}
				
				if let envStr = arguments[FlutterVirtusizeKey.environment] as? String,
				   let env = VirtusizeEnvironment.allCases.first(where: { "\($0.self)" == envStr.lowercased() }) {
					Virtusize.environment = env
				}
				
				var virtusizeBuilder = VirtusizeParamsBuilder()
				
				if let langStr = arguments[FlutterVirtusizeKey.language] as? String,
				   let lang = VirtusizeLanguage.allCases.first(where: { $0.langStr == langStr })
				{
					virtusizeBuilder = virtusizeBuilder.setLanguage(lang)
				}
				
				if let showSGI = arguments[FlutterVirtusizeKey.showSGI] as? Bool {
					virtusizeBuilder = virtusizeBuilder.setShowSGI(showSGI)
				}
				
				if let allowedLangStrArray = arguments[FlutterVirtusizeKey.allowedLanguages] as? [String] {
					let allowedLangs = VirtusizeLanguage.allCases
						.filter{ allowedLangStrArray.contains($0.langStr) }
					virtusizeBuilder = virtusizeBuilder.setAllowedLanguages(allowedLangs)
				}
				
				if let detailsPanelCardsStrArray = arguments[FlutterVirtusizeKey.detailsPanelCards] as? [String] {
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
					FlutterVirtusizeKey.virtusizeParams: arguments,
					FlutterVirtusizeKey.displayLanguage: Virtusize.displayLanguage?.rawValue
				])
			case FlutterVirtusizeMethod.setUserId:
				guard let userId = call.arguments as? String, !userId.isEmpty else {
					result(FlutterError.invalidUserID)
					return
				}
				Virtusize.userID = userId
			case FlutterVirtusizeMethod.getProductDataCheck:
				guard let arguments = call.arguments as? [String: Any] else {
					result(FlutterError.noArguments)
					return
				}
				guard let productId = arguments[FlutterVirtusizeKey.externalProductId] as? String   else {
					result(FlutterError.argumentNotSet(FlutterVirtusizeKey.externalProductId))
					return
				}
				
				var imageURL: URL? = nil
				if let imageURLString = arguments[FlutterVirtusizeKey.imageURL] as? String {
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
			case FlutterVirtusizeMethod.openVirtusizeWebView:
				let product = storeProductSet.first { $0.externalId == externalProductIDStack.last }
				if let viewController = VirtusizeWebViewController(
					product: product,
					userSessionResponse: userSessionResponse,
					messageHandler: self,
					processPool: Virtusize.processPool) {
					let flutterRootViewController = UIApplication.shared.windows.first?.rootViewController
					flutterRootViewController?.present(viewController, animated: true)
				}
			case FlutterVirtusizeMethod.getRecommendationText:
				guard let storeProductId = call.arguments as? Int else {
					result(FlutterError.argumentNotSet(FlutterVirtusizeKey.storeProductId))
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
			case FlutterVirtusizeMethod.getPrivacyPolicyLink:
				result(repository.getPrivacyPolicyLink())
			case FlutterVirtusizeMethod.sendOrder:
				guard let orderDict = call.arguments as? [String : Any?] else {
					result(FlutterError.noArguments)
					return
				}
				repository.sendOrder(orderDict, onSuccess: {
					result(orderDict)
				},onError: { error in
					result(FlutterError.sendOrder(error.localizedDescription))
				})
			case FlutterVirtusizeMethod.addProduct:
				guard let externalProductId = call.arguments as? String else {
					result(FlutterError.argumentNotSet(FlutterVirtusizeKey.externalProductId))
					return
				}
				
				externalProductIDStack.append(externalProductId)
			case FlutterVirtusizeMethod.removeProduct:
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
			FlutterVirtusizeMethod.onProduct,
			arguments: [
				FlutterVirtusizeKey.storeProductId: storeProduct!.id,
				FlutterVirtusizeKey.imageType: "store",
				FlutterVirtusizeKey.imageURL: storeProduct!.cloudinaryImageUrlString,
				FlutterVirtusizeKey.productType: storeProduct!.productType,
				FlutterVirtusizeKey.productStyle: storeProduct!.productStyle
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
					FlutterVirtusizeMethod.onRecChange,
					arguments: [
						FlutterVirtusizeKey.externalProductId: storeProduct!.externalId,
						FlutterVirtusizeKey.recText: nil,
						FlutterVirtusizeKey.showUserProductImage: false
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
						FlutterVirtusizeMethod.onRecChange,
						arguments: [
							FlutterVirtusizeKey.externalProductId: storeProduct!.externalId,
							FlutterVirtusizeKey.recText: nil,
							FlutterVirtusizeKey.showUserProductImage: false
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
			FlutterVirtusizeMethod.onProduct,
			arguments:  [
				FlutterVirtusizeKey.storeProductId: storeProduct!.id,
				FlutterVirtusizeKey.imageType: "user",
				FlutterVirtusizeKey.imageURL : userProductRecommendedSize?.bestUserProduct?.cloudinaryImageUrlString,
				FlutterVirtusizeKey.productType: userProductRecommendedSize?.bestUserProduct?.productType,
				FlutterVirtusizeKey.productStyle: userProductRecommendedSize?.bestUserProduct?.productStyle
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
			FlutterVirtusizeKey.externalProductId: storeProduct!.externalId,
			FlutterVirtusizeKey.recText: recText,
			FlutterVirtusizeKey.showUserProductImage: userProductRecommendedSize?.bestUserProduct != nil
		]

		if let result = result {
			result(arguments)
		} else {
			flutterChannel?.invokeMethod(
				FlutterVirtusizeMethod.onRecChange,
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

extension SwiftFlutterVirtusizeSdkPlugin: VirtusizeMessageHandler {
	public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveError error: VirtusizeError) {
		currentWorkItem = DispatchWorkItem { [weak self] in
			self?.flutterChannel?.invokeMethod(FlutterVirtusizeMethod.onVSError, arguments: error.debugDescription)
		}
		DispatchQueue.global().async(execute: currentWorkItem!)
	}
	
	public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveEvent event: VirtusizeEvent) {
		let eventsWorkItem = DispatchWorkItem { [weak self] in
			if let eventData = event.data as? [String: Any],
			   let eventName = eventData[VirtusizeEventKey.shortEventName] ?? eventData[VirtusizeEventKey.eventName] {
				self?.flutterChannel?.invokeMethod(FlutterVirtusizeMethod.onVSEvent, arguments: eventName)
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
