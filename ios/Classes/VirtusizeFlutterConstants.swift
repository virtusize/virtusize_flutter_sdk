struct VirtusizeFlutterMethod {
	/// Flutter to iOS
	static let setVirtusizeParams = "setVirtusizeParams"
	static let setUserId = "setUserId"
	static let openVirtusizeWebView = "openVirtusizeWebView"
	static let getPrivacyPolicyLink = "getPrivacyPolicyLink"
	static let sendOrder = "sendOrder"
	static let loadVirtusize = "loadVirtusize"
	
	/// iOS to Flutter
	static let onVSEvent = "onVSEvent"
	static let onVSError = "onVSError"
	static let onProduct = "onProduct"
	static let onProductDataCheck = "onProductDataCheck"
	static let onRecChange = "onRecChange"
	static let onProductError = "onProductError"
}

struct VirtusizeFlutterKey {
	static let apiKey = "apiKey"
	static let externalUserId = "externalUserId"
	static let environment = "env"
	static let language = "language"
	static let showSGI = "showSGI"
	static let allowedLanguages = "allowedLanguages"
	static let detailsPanelCards = "detailsPanelCards"
	static let showSNSButtons = "showSNSButtons"
	static let branch = "branch"
	static let externalProductId = "externalProductId"
	static let imageURL = "imageURL"
	static let cloudinaryImageURL = "cloudinaryImageURL"
	static let storeProductId = "storeProductId"
	static let virtusizeParams = "virtusizeParams"
	static let displayLanguage = "displayLanguage"
	static let imageType = "imageType"
	static let productType = "productType"
	static let productStyle = "productStyle"
	static let recText = "recText"
	static let showUserProductImage = "showUserProductImage"
	static let isValidProduct = "isValidProduct"
}

struct VirtusizeEventKey {
	static let shortEventName = "name"
	static let eventName = "eventName"
	static let userProductID = "userProductId"
	static let recType = "recommendationType"
	static let sizeRecName = "sizeRecName"
}
