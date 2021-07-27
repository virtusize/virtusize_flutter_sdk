import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/recommendation.dart';
import 'models/virtusize_product.dart';
import 'models/product_data_check.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_order.dart';
import 'res/text.dart';
import 'utils/virtusize_constants.dart';
import 'utils/virtusize_message_listener.dart';

/// The main class for flutter apps to access
class VirtusizePlugin {
  /// The singleton instance
  static final VirtusizePlugin instance = VirtusizePlugin._();

  /// A message listener to receive Virtusize specific messages from Native
  VirtusizeMessageListener _virtusizeMessageListener;

  /// Initialize the [VirtusizePlugin] instance
  VirtusizePlugin._() {
    // The broadcast stream controllers
    IVirtusizePlugin.instance._vsTextController =
    StreamController<VSText>.broadcast();
    IVirtusizePlugin.instance._pdcController =
    StreamController<ProductDataCheck>.broadcast();
    IVirtusizePlugin.instance._productController =
    StreamController<VirtusizeProduct>.broadcast();
    IVirtusizePlugin.instance._recController =
    StreamController<Recommendation>.broadcast();

    // Set the method call handler to receive data from Native
    IVirtusizePlugin.instance._channel.setMethodCallHandler((call) {
      if (call.method == VirtusizeFlutterMethod.onRecChange) {
        IVirtusizePlugin.instance._recController
            .add(Recommendation(json.encode(call.arguments)));
      } else if (call.method == VirtusizeFlutterMethod.onProduct) {
        IVirtusizePlugin.instance._productController
            .add(VirtusizeProduct(json.encode(call.arguments)));
      } else if (call.method == VirtusizeFlutterMethod.onVSEvent) {
        if (_virtusizeMessageListener != null) {
          _virtusizeMessageListener.vsEvent.call(call.arguments);
        }
      } else if (call.method == VirtusizeFlutterMethod.onVSError) {
        if (_virtusizeMessageListener != null) {
          _virtusizeMessageListener.vsError.call(call.arguments);
        }
      }
      return null;
    });
  }

  /// A function for clients to set the virtusize parameters
  Future<void> setVirtusizeParams(
      /// The API key that is unique and provided for Virtusize clients
      {@required String apiKey,
      /// The user id that is the unique user id from the client system
      String userId,
      /// The Virtusize environment that defaults to the `global` domain
      Env env = Env.global,
      /// The [Language] that sets the initial language the Virtusize web app will load in
      Language language,
      /// The Boolean value to determine whether the Virtusize web app will fetch SGI and use SGI flow for users to add user generated items to their wardrobe
      bool showSGI = false,
      /// The languages that the user can switch to using the Language Selector
      List<Language> allowedLanguages = Language.values,
      /// The info categories that will be displayed in the Product Details tab
      List<InfoCategory> detailsPanelCards = InfoCategory.values}) async {
    if (apiKey == null) {
      throw FlutterError("The API key is required");
    }
    try {

      // Gets the data of the set Virtusize parameters and the display language from Native
      Map<dynamic, dynamic> paramsData = await IVirtusizePlugin.instance._channel
          .invokeMethod(VirtusizeFlutterMethod.setVirtusizeParams, {
        VirtusizeFlutterKey.apiKey: apiKey,
        VirtusizeFlutterKey.externalUserId: userId,
        VirtusizeFlutterKey.environment: env.value,
        VirtusizeFlutterKey.language: language != null ? language.value : null,
        VirtusizeFlutterKey.showSGI: showSGI,
        VirtusizeFlutterKey.allowedLanguages: allowedLanguages.map((language) {
          return language.value;
        }).toList(),
        VirtusizeFlutterKey.detailsPanelCards:
        detailsPanelCards.map((infoCategory) {
          return infoCategory.value;
        }).toList()
      });

      // Loads the localization and the custom font
      VSText.load(paramsData[VirtusizeFlutterKey.displayLanguage], language)
          .then((value) {
        IVirtusizePlugin.instance._vsTextController.add(value);
        IVirtusizePlugin.instance.vsText = value;
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
      await IVirtusizePlugin.instance._channel
          .invokeMethod(VirtusizeFlutterMethod.setUserId, userId);
    } on PlatformException catch (error) {
      print('Failed to set the external user ID: $error');
    }
  }

  /// A function for clients to set the product info
  Future<void> setProduct(
      /// A string to represent a external product ID from a client's system
      {@required String externalId,
      /// The URL of the product image that is fully qualified with the domain and the protocol
      String imageURL}) async {
    assert(externalId != null);
    ProductDataCheck productDataCheck =
    await _getProductDataCheck(externalId, imageURL);
    IVirtusizePlugin.instance._pdcController.add(productDataCheck);
    if (productDataCheck != null && productDataCheck.isValidProduct) {
      _getRecommendationText(productDataCheck: productDataCheck);
    }
  }

  /// A private function to get the product data check result from Native
  Future<ProductDataCheck> _getProductDataCheck(
      String externalId, String imageURL) async {
    try {
      ProductDataCheck productDataCheck = await IVirtusizePlugin
          .instance._channel
          .invokeMethod(VirtusizeFlutterMethod.getProductDataCheck, {
        VirtusizeFlutterKey.externalProductId: externalId,
        VirtusizeFlutterKey.imageURL: imageURL
      }).then((value) => ProductDataCheck(value, externalId));

      if (_virtusizeMessageListener != null) {
        _virtusizeMessageListener.productDataCheckSuccess
            .call(productDataCheck);
      }

      return productDataCheck;
    } on PlatformException catch (error) {
      print('Failed to get product data check: $error');

      if (_virtusizeMessageListener != null) {
        _virtusizeMessageListener.productDataCheckError.call(error);
      }
    }
    return null;
  }

  /// A private function to get the recommendation text from Native
  Future<void> _getRecommendationText(
      {@required ProductDataCheck productDataCheck}) async {
    try {
      IVirtusizePlugin.instance._recController.add(Recommendation(json.encode(
          await IVirtusizePlugin.instance._channel.invokeMethod(
              VirtusizeFlutterMethod.getRecommendationText,
              productDataCheck.productId))));
    } on PlatformException catch (error) {
      print('Failed to get the recommendation text: $error');
      IVirtusizePlugin.instance._recController.add(Recommendation(
          "{\"${VirtusizeFlutterKey.externalProductId}\": \"${productDataCheck.externalProductId}\"}"));
    }
  }

  /// A function for clients to open the Virtusize webview if they customize their own button
  Future<void> openVirtusizeWebView() async {
    try {
      await IVirtusizePlugin.instance._channel
          .invokeMethod(VirtusizeFlutterMethod.openVirtusizeWebView);
    } on PlatformException catch (error) {
      print('Failed to open the VirtusizeWebView: $error');
    }
  }

  /// A function for clients to set the Virtusize message listener to listen to callback messages
  void setVirtusizeMessageListener(VirtusizeMessageListener listener) {
    assert(listener != null);
    _virtusizeMessageListener = listener;
  }

  /// A function for clients to send an order to the Virtusize server
  Future<void> sendOrder(
      /// An order to be sent to the server
      {@required VirtusizeOrder order,
      /// A callback to get the order data back when sending an order is successful
      Function(Map<dynamic, dynamic> sentOrder) onSuccess,
      /// A callback to get an error exception back when sending an order is unsuccessful
      Function(Exception e) onError}) async {
    assert(order != null);
    try {
      Map<dynamic, dynamic> sentOrder = await IVirtusizePlugin.instance._channel
          .invokeMethod(VirtusizeFlutterMethod.sendOrder, order.toJson());
      onSuccess(sentOrder);
    } on PlatformException catch (error) {
      print('Failed to send an order: $error');
      onError(error);
    }
  }
}

/// The main internal class
class IVirtusizePlugin {
  /// The singleton instance
  static final IVirtusizePlugin instance = IVirtusizePlugin._();

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

  /// A stream controller to send the [VirtusizeProduct] data to multiple Virtusize widgets
  StreamController _productController;
  Stream<VirtusizeProduct> get productStream => _productController.stream;

  /// A stream controller to send the [Recommendation] data to multiple Virtusize widgets
  StreamController _recController;
  Stream<Recommendation> get recStream => _recController.stream;

  IVirtusizePlugin._();

  /// A function to get the privacy policy link from Native
  Future<String> getPrivacyPolicyLink() async {
    try {
      return await _channel.invokeMethod(VirtusizeFlutterMethod.getPrivacyPolicyLink);
    } on PlatformException catch (error) {
      print('Failed to get the privacy policy link: $error');
      return null;
    }
  }

  /// A function to add an external product ID to the stack in Native
  /// which records the visited order of the external product IDs that are tied with the Virtusize widgets
  Future<void> addProduct({@required String externalProductId}) async {
    if (externalProductId == null) {
      return;
    }
    try {
      await _channel.invokeMethod(
          VirtusizeFlutterMethod.addProduct, externalProductId);
    } on PlatformException catch (error) {
      print('Failed to add the product $externalProductId: $error');
    }
  }

  /// A function to remove the most recent visited external product ID from the stack in Native
  Future<void> removeProduct() async {
    try {
      await _channel.invokeMethod(VirtusizeFlutterMethod.removeProduct);
    } on PlatformException catch (error) {
      print('Failed to remove a product $error');
    }
  }
}
