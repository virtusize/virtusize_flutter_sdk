struct VirtusizeFlutterMethod {
	/// Flutter to iOS
	static let setVirtusizeParams = "setVirtusizeParams"
	static let setUserId = "setUserId"
	static let getProductDataCheck = "getProductDataCheck"
	static let openVirtusizeWebView = "openVirtusizeWebView"
	static let getRecommendationText = "getRecommendationText"
	static let getPrivacyPolicyLink = "getPrivacyPolicyLink"
	static let sendOrder = "sendOrder"
	static let addProduct = "addProduct"
	static let removeProduct = "removeProduct"
	
	/// iOS to Flutter
	static let onVSEvent = "onVSEvent"
	static let onVSError = "onVSError"
	static let onProduct = "onProduct"
	static let onRecChange = "onRecChange"
}

struct VirtusizeFlutterKey {
	static let apiKey = "apiKey"
	static let externalUserId = "externalUserId"
	static let environment = "env"
	static let language = "language"
	static let showSGI = "showSGI"
	static let allowedLanguages = "allowedLanguages"
	static let detailsPanelCards = "detailsPanelCards"
	static let externalProductId = "externalProductId"
	static let imageURL = "imageURL"
	static let storeProductId = "storeProductId"
	static let virtusizeParams = "virtusizeParams"
	static let displayLanguage = "displayLanguage"
	static let imageType = "imageType"
	static let productType = "productType"
	static let productStyle = "productStyle"
	static let recText = "recText"
	static let showUserProductImage = "showUserProductImage"
}

struct VirtusizeEventKey {
	static let shortEventName = "name"
	static let eventName = "eventName"
	static let userProductID = "userProductId"
	static let recType = "recommendationType"
	static let sizeRecName = "sizeRecName"
}
