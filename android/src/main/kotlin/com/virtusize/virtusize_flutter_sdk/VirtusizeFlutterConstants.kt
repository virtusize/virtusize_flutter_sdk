internal object VirtusizeFlutterMethod {
    // Flutter to Android
    const val SET_VIRTUSIZE_PARAMS = "setVirtusizeParams"
    const val SET_USER_ID = "setUserId"
    const val OPEN_VIRTUSIZE_WEB_VIEW = "openVirtusizeWebView"
    const val GET_PRIVACY_POLICY_LINK = "getPrivacyPolicyLink"
    const val SEND_ORDER = "sendOrder"
    const val LOAD_VIRTUSIZE = "loadVirtusize"
    const val SHOW_PRIVACY_POLICY = "showPrivacyPolicy"

    // Android to Flutter
    const val ON_VS_EVENT = "onVSEvent"
    const val ON_VS_ERROR = "onVSError"
    const val ON_PRODUCT = "onProduct"
    const val ON_PRODUCT_DATA_CHECK = "onProductDataCheck"
    const val ON_REC_CHANGE = "onRecChange"
    const val ON_LANGUAGE_CLICK = "onLanguageClick"
    const val ON_PRODUCT_ERROR = "onProductError"
}

internal object VirtusizeFlutterKey {
    const val API_KEY = "apiKey"
    const val EXTERNAL_USER_ID = "externalUserId"
    const val ENVIRONMENT = "env"
    const val LANGUAGE = "language"
    const val SHOW_SGI = "showSGI"
    const val ALLOW_LANGUAGES = "allowedLanguages"
    const val DETAILS_PANEL_CARDS = "detailsPanelCards"
    const val SHOW_SNS_BUTTONS = "showSNSButtons"
    const val BRANCH = "branch"
    const val SERVICE_ENVIRONMENT = "serviceEnvironment"
    const val EXTERNAL_PRODUCT_ID = "externalProductId"
    const val IMAGE_URL = "imageURL"
    const val CLOUDINARY_IMAGE_URL = "cloudinaryImageURL"
    const val STORE_PRODUCT_ID = "storeProductId"
    const val VIRTUSIZE_PARAMS = "virtusizeParams"
    const val DISPLAY_LANGUAGE = "displayLanguage"
    const val IMAGE_TYPE = "imageType"
    const val PRODUCT_TYPE = "productType"
    const val PRODUCT_STYLE = "productStyle"
    const val REC_TEXT = "recText"
    const val SHOW_USER_PRODUCT_IMAGE = "showUserProductImage"
    const val IS_VALID_PRODUCT = "isValidProduct"
    const val SHOW_PRIVACY_POLICY = "showPrivacyPolicy"
    const val STORE_NAME = "storeName"
}

internal object VirtusizeEventKey {
    const val SHORT_EVENT_NAME = "name"
    const val EVENT_NAME = "eventName"
    const val USER_PRODUCT_ID = "userProductId"
    const val REC_TYPE = "recommendationType"
    const val SIZE_REC_NAME = "sizeRecName"
}