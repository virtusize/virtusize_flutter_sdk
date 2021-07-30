import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_client_product.dart';

import 'models/recommendation.dart';
import 'models/virtusize_server_product.dart';
import 'models/product_data_check.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_order.dart';
import 'res/vs_text.dart';
import 'utils/virtusize_constants.dart';
import 'utils/virtusize_message_listener.dart';

/// The main class for flutter apps to access
class VirtusizeSDK {
  /// The singleton instance of this class
  static final VirtusizeSDK instance = VirtusizeSDK._();

  /// A listener to receive Virtusize-specific messages from Native
  VirtusizeMessageListener _virtusizeMessageListener;

  /// Initialize the [VirtusizeSDK] instance
  VirtusizeSDK._() {
    // The broadcast stream controllers
    IVirtusizeSDK.instance._vsTextController =
    StreamController<VSText>.broadcast();
    IVirtusizeSDK.instance._pdcController =
    StreamController<ProductDataCheck>.broadcast();
    IVirtusizeSDK.instance._productController =
    StreamController<VirtusizeServerProduct>.broadcast();
    IVirtusizeSDK.instance._recController =
    StreamController<Recommendation>.broadcast();

    // Sets the method call handler
    IVirtusizeSDK.instance._channel.setMethodCallHandler(_methodCallHandler);
  }

  /// Returns the method call handler that receives data from Native
  Future<dynamic> _methodCallHandler(MethodCall call) {
    // A map to match each method call from Native with its corresponding exectuion
    Map<String, Function> methodCallExecutionMap = {
      FlutterVirtusizeMethod.onRecChange: (call) => {
        IVirtusizeSDK.instance._recController
            .add(Recommendation(json.encode(call.arguments)))
      },
      FlutterVirtusizeMethod.onProduct: (call) => {
        IVirtusizeSDK.instance._productController
            .add(VirtusizeServerProduct(json.encode(call.arguments)))
      },
      FlutterVirtusizeMethod.onVSEvent: (call) => {
        if (_virtusizeMessageListener.vsEvent != null)
          {_virtusizeMessageListener.vsEvent.call(call.arguments)
          }
      },
      FlutterVirtusizeMethod.onVSError: (call) => {
        if (_virtusizeMessageListener.vsError != null)
          {_virtusizeMessageListener.vsError.call(call.arguments)}
      }
    };
    return methodCallExecutionMap[call.method](call);
  }

  /// A function for clients to set the Virtusize parameters
  Future<void> setVirtusizeParams(

      /// The unique API key provided for Virtusize clients
      {@required String apiKey,

        /// The user ID from the client's system (should be unique)
        String userId,

        /// The Virtusize environment (defaults to the `global` domain)
        VSEnvironment env = VSEnvironment.global,

        /// The [VSLanguage] that sets the initial language the Virtusize webview will load in
        VSLanguage language,

        /// The boolean value to determine if the Virtusize webview should use the SGI flow for users to add user-generated items to their wardrobe
        bool showSGI = false,

        /// The languages that the user can switch between using the Language Selector
        List<VSLanguage> allowedLanguages = VSLanguage.values,

        /// The info categories that will be displayed in the Product Details tab
        List<VSInfoCategory> detailsPanelCards = VSInfoCategory.values}) async {
    if (apiKey == null) {
      throw FlutterError("The API key is required");
    }
    try {

      // [paramsData] is a map with two key-value pairs to return the Virtusize parameters and the display language from Native
      Map<dynamic, dynamic> paramsData = await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.setVirtusizeParams, {
        FlutterVirtusizeKey.apiKey: apiKey,
        FlutterVirtusizeKey.externalUserId: userId,
        FlutterVirtusizeKey.environment: env.value,
        FlutterVirtusizeKey.language: language != null ? language.value : null,
        FlutterVirtusizeKey.showSGI: showSGI,
        FlutterVirtusizeKey.allowedLanguages: allowedLanguages.map((language) {
          return language.value;
        }).toList(),
        FlutterVirtusizeKey.detailsPanelCards:
        detailsPanelCards.map((infoCategory) {
          return infoCategory.value;
        }).toList()
      });

      // Loads the i18n localization data and the custom font information
      VSText.load(paramsData[FlutterVirtusizeKey.displayLanguage], language)
          .then((value) {
        IVirtusizeSDK.instance._vsTextController.add(value);
        IVirtusizeSDK.instance.vsText = value;
      });
    } on PlatformException catch (error) {
      print('Failed to set the Virtusize parameters: $error');
    }
  }

  /// A function for clients to set the user ID
  Future<void> setUserId(String userId) async {
    if (userId == null || userId.isEmpty) {
      print('Failed to set the external user ID: userId is null or empty');
      return;
    }
    try {
      await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.setUserId, userId);
    } on PlatformException catch (error) {
      print('Failed to set the external user ID: $error');
    }
  }

  /// A function for clients to load the Product Info
  Future<void> loadProduct(VirtusizeClientProduct clientProduct) async {
    assert(clientProduct.externalProductId != null);
    ProductDataCheck productDataCheck =
    await _getProductDataCheck(clientProduct.externalProductId, clientProduct.imageURL);
    IVirtusizeSDK.instance._pdcController.add(productDataCheck);
    if (productDataCheck != null && productDataCheck.isValidProduct) {
      _getRecommendationText(productDataCheck: productDataCheck);
    }
  }

  /// A private function to get the [ProductDataCheck] result from Native
  Future<ProductDataCheck> _getProductDataCheck(
      String externalId, String imageURL) async {
    try {
      ProductDataCheck productDataCheck = await IVirtusizeSDK
          .instance._channel
          .invokeMethod(FlutterVirtusizeMethod.getProductDataCheck, {
        FlutterVirtusizeKey.externalProductId: externalId,
        FlutterVirtusizeKey.imageURL: imageURL
      }).then((value) => ProductDataCheck(externalId, value));

      if (_virtusizeMessageListener.productDataCheckSuccess != null) {
        _virtusizeMessageListener.productDataCheckSuccess
            .call(productDataCheck);
      }

      return productDataCheck;
    } on PlatformException catch (error) {
      print('Failed to get product data check: $error');

      if (_virtusizeMessageListener.productDataCheckError != null) {
        _virtusizeMessageListener.productDataCheckError.call(error);
      }
    }
    return null;
  }

  /// A private function to get the recommendation text from Native
  Future<void> _getRecommendationText(
      {@required ProductDataCheck productDataCheck}) async {
    try {
      IVirtusizeSDK.instance._recController.add(Recommendation(json.encode(
          await IVirtusizeSDK.instance._channel.invokeMethod(
              FlutterVirtusizeMethod.getRecommendationText,
              productDataCheck.productId))));
    } on PlatformException catch (error) {
      print('Failed to get the recommendation text: $error');
      IVirtusizeSDK.instance._recController.add(Recommendation(
          "{\"${FlutterVirtusizeKey.externalProductId}\": \"${productDataCheck.externalProductId}\"}"));
    }
  }

  /// A function for clients to open the Virtusize webview (only when they customize their own button using the [VirtusizeButton] widget)
  Future<void> openVirtusizeWebView() async {
    try {
      await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.openVirtusizeWebView);
    } on PlatformException catch (error) {
      print('Failed to open the VirtusizeWebView: $error');
    }
  }

  /// A function for clients to set a listener for Virtusize-specific messages
  void setVirtusizeMessageListener(VirtusizeMessageListener listener) {
    assert(listener != null);
    _virtusizeMessageListener = listener;
  }

  /// A function for clients to send an order to the Virtusize server
  Future<void> sendOrder(
      /// A [VirtusizeOrder] to be sent to the server
      {@required VirtusizeOrder order,
        /// [onSuccess] callback to get a map of the order data back when `sendOrder` is successful
        Function(Map<dynamic, dynamic> sentOrder) onSuccess,
        /// [onError] callback to get an error exception back when `sendOrder` is unsuccessful
        Function(Exception e) onError}) async {
    assert(order != null);
    try {
      Map<dynamic, dynamic> sentOrder = await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.sendOrder, order.toJson());
      onSuccess(sentOrder);
    } on PlatformException catch (error) {
      print('Failed to send an order: $error');
      onError(error);
    }
  }
}

/// The main internal class
class IVirtusizeSDK {
  /// The singleton instance of this class
  static final IVirtusizeSDK instance = IVirtusizeSDK._();

  /// The method channel which creates a bridge to communicate between Flutter and Native
  MethodChannel _channel =
  const MethodChannel('com.virtusize/flutter_virtusize_sdk');

  /// For caching the i18n localization data and the custom font info
  VSText vsText;

  /// A stream controller to send the [VSText] data to multiple Virtusize widgets
  StreamController _vsTextController;
  Stream<VSText> get vsTextStream => _vsTextController.stream;

  /// A stream controller to send the [ProductDataCheck] data to multiple Virtusize widgets
  StreamController _pdcController;
  Stream<ProductDataCheck> get pdcStream => _pdcController.stream;

  /// A stream controller to send the [VirtusizeServerProduct] data to multiple Virtusize widgets
  StreamController _productController;
  Stream<VirtusizeServerProduct> get productStream => _productController.stream;

  /// A stream controller to send the [Recommendation] data to multiple Virtusize widgets
  StreamController _recController;
  Stream<Recommendation> get recStream => _recController.stream;

  IVirtusizeSDK._();

  /// A function to get the privacy policy link from Native
  Future<String> getPrivacyPolicyLink() async {
    try {
      return await _channel.invokeMethod(FlutterVirtusizeMethod.getPrivacyPolicyLink);
    } on PlatformException catch (error) {
      print('Failed to get the privacy policy link: $error');
      return null;
    }
  }

  /// A function to add a product ID to the (external) Product ID stack in Native.
  /// The most recently visited product will be at the top of the stack.
  Future<void> addProduct({@required String externalProductId}) async {
    if (externalProductId == null) {
      return;
    }
    try {
      await _channel.invokeMethod(
          FlutterVirtusizeMethod.addProduct, externalProductId);
    } on PlatformException catch (error) {
      print('Failed to add the product $externalProductId: $error');
    }
  }

  /// A function to remove the most recent visited external product ID from the stack in Native
  Future<void> removeProduct() async {
    try {
      await _channel.invokeMethod(FlutterVirtusizeMethod.removeProduct);
    } on PlatformException catch (error) {
      print('Failed to remove a product $error');
    }
  }
}
