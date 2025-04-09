import Flutter
import UIKit
import Virtusize

public class SwiftVirtusizeFlutterPlugin: NSObject, FlutterPlugin {

    /// The FlutterMethodChannel that will create the communication between Flutter and native iOS
    private var flutterChannel: FlutterMethodChannel?

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
                VirtusizeFlutter.initNotificationObserver(flutterHandler: self)
            
                guard let arguments = call.arguments as? [String: Any] else {
                    result(FlutterError.noArguments)
                    return
                }
                if let apiKey = arguments[VirtusizeFlutterKey.apiKey] as? String {
                    VirtusizeFlutter.APIKey = apiKey
                } else {
                    result(FlutterError.argumentNotSet(VirtusizeFlutterKey.apiKey))
                }

                if let userId = arguments[VirtusizeFlutterKey.externalUserId] as? String {
                    VirtusizeFlutter.userID = userId
                }
                
                if let envStr = arguments[VirtusizeFlutterKey.environment] as? String,
                   let env = VirtusizeEnvironment.allCases.first(where: {environment in "\(environment.self)".lowercased() == envStr.lowercased() }) {
                    VirtusizeFlutter.environment = env
                }
                
                var virtusizeBuilder = VirtusizeParamsBuilder()
                
                if let langStr = arguments[VirtusizeFlutterKey.language] as? String,
                   let lang = VirtusizeLanguage.allCases.first(where: { language in language.langStr == langStr })
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
            
                if let showSNSButtons = arguments[VirtusizeFlutterKey.showSNSButtons] as? Bool {
                    virtusizeBuilder = virtusizeBuilder.setShowSNSButtons(showSNSButtons)
                }
            
                if let branch = arguments[VirtusizeFlutterKey.branch] as? String {
                    virtusizeBuilder = virtusizeBuilder.setBranch(branch)
                }
                
                VirtusizeFlutter.params = virtusizeBuilder.build()
                result([
                    VirtusizeFlutterKey.virtusizeParams: arguments,
                    VirtusizeFlutterKey.displayLanguage: VirtusizeFlutter.displayLanguage?.rawValue
                ])
            case VirtusizeFlutterMethod.setUserId:
                guard let userId = call.arguments as? String, !userId.isEmpty else {
                    result(FlutterError.invalidUserID)
                    return
                }
                VirtusizeFlutter.userID = userId
            case VirtusizeFlutterMethod.loadVirtusize:
                guard let arguments = call.arguments as? [String: Any] else {
                    result(FlutterError.noArguments)
                    return
                }
                guard let externalProductId = arguments[VirtusizeFlutterKey.externalProductId] as? String else {
                    result(FlutterError.argumentNotSet(VirtusizeFlutterKey.externalProductId))
                    return
                }

                var imageURL: URL? = nil
                if let imageURLString = arguments[VirtusizeFlutterKey.imageURL] as? String {
                    imageURL = URL(string: imageURLString)
                }
                
                let product = VirtusizeProduct(externalId: externalProductId, imageURL: imageURL)
                VirtusizeFlutter.load(product: product)
            case VirtusizeFlutterMethod.openVirtusizeWebView:
                guard let externalProductId = call.arguments as? String else {
                    result(FlutterError.noArguments)
                    return
                }
            
                VirtusizeFlutter.openVirtusizeWebView(
                    externalId: externalProductId,
                    messageHandler: self)
            case VirtusizeFlutterMethod.getPrivacyPolicyLink:
                result(VirtusizeFlutter.getPrivacyPolicyLink())
            case VirtusizeFlutterMethod.sendOrder:
                guard let orderDict = call.arguments as? [String : Any?] else {
                    result(FlutterError.noArguments)
                    return
                }
            
                VirtusizeFlutter.sendOrder(
                    orderDict,
                    onSuccess: {
                        result(orderDict)
                    },
                    onError: { error in
                        result(FlutterError.sendOrder(error.localizedDescription))
                    })
            default:
                result(FlutterMethodNotImplemented)
        }
    }
}

extension SwiftVirtusizeFlutterPlugin: VirtusizeFlutterProductEventHandler {
    public func onProductCheckData(externalId: String, isValid: Bool) {
        DispatchQueue.main.async {
            self.flutterChannel?.invokeMethod(
                VirtusizeFlutterMethod.onProductDataCheck,
                arguments:  [
                    VirtusizeFlutterKey.externalProductId: externalId,
                    VirtusizeFlutterKey.isValidProduct: isValid
                ]
            )
        }
    }
    
    public func onSizeRecommendationData(
        bestUserProduct: VirtusizeServerProduct?,
        recommendationText: String) {
            DispatchQueue.main.async {
                self.flutterChannel?.invokeMethod(
                    VirtusizeFlutterMethod.onProduct,
                    arguments:  [
                        VirtusizeFlutterKey.externalProductId: bestUserProduct?.externalId,
                        VirtusizeFlutterKey.imageType: "store",
                        VirtusizeFlutterKey.imageURL : bestUserProduct?.cloudinaryImageUrlString,
                        VirtusizeFlutterKey.productType: bestUserProduct?.productType,
                        VirtusizeFlutterKey.productStyle: bestUserProduct?.productStyle
                    ]
                )
                
                self.flutterChannel?.invokeMethod(
                    VirtusizeFlutterMethod.onRecChange,
                    arguments: [
                        VirtusizeFlutterKey.externalProductId: bestUserProduct?.externalId,
                        VirtusizeFlutterKey.recText: recommendationText,
                        VirtusizeFlutterKey.showUserProductImage: bestUserProduct?.cloudinaryImageUrlString != nil
                    ]
                )
            }
    }
    
    public func onInPageError(externalId: String) {
        DispatchQueue.main.async {
            self.flutterChannel?.invokeMethod(
                VirtusizeFlutterMethod.onProductError,
                arguments: externalId
            )
        }
    }
}

extension SwiftVirtusizeFlutterPlugin: VirtusizeMessageHandler {
    public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveError error: VirtusizeError) {
        DispatchQueue.main.async {
            self.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.onVSError, arguments: error.debugDescription)
        }
    }
    
    public func virtusizeController(_ controller: VirtusizeWebViewController?, didReceiveEvent event: VirtusizeEvent) {
        let eventData = event.data as? [String: Any]
        if let eventData = eventData,
           let eventName = eventData[VirtusizeEventKey.shortEventName] ?? eventData[VirtusizeEventKey.eventName] {
            DispatchQueue.main.async {
                self.flutterChannel?.invokeMethod(VirtusizeFlutterMethod.onVSEvent, arguments: eventName)
            }
        }
    }
}
