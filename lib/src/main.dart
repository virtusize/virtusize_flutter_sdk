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

class VirtusizePlugin {
  static final VirtusizePlugin instance = VirtusizePlugin._();

  VirtusizeMessageListener _virtusizeMessageListener;

  VirtusizePlugin._() {
    IVirtusizePlugin.instance._vsTextController =
        StreamController<VSText>.broadcast();
    IVirtusizePlugin.instance._pdcController =
        StreamController<ProductDataCheck>.broadcast();
    IVirtusizePlugin.instance._productController =
        StreamController<VirtusizeProduct>.broadcast();
    IVirtusizePlugin.instance._recController =
        StreamController<Recommendation>.broadcast();

    IVirtusizePlugin.instance._channel.setMethodCallHandler((call) {
      if (call.method == VirtusizeFlutterMethod.recChange) {
        IVirtusizePlugin.instance._recController
            .add(Recommendation(json.encode(call.arguments)));
      } else if (call.method == VirtusizeFlutterMethod.product) {
        IVirtusizePlugin.instance._productController
            .add(VirtusizeProduct(json.encode(call.arguments)));
      } else if (call.method == VirtusizeFlutterMethod.vsEvent) {
        if (_virtusizeMessageListener != null) {
          _virtusizeMessageListener.vsEvent.call(call.arguments);
        }
      } else if (call.method == VirtusizeFlutterMethod.vsError) {
        if (_virtusizeMessageListener != null) {
          _virtusizeMessageListener.vsError.call(call.arguments);
        }
      }
      return null;
    });
  }

  Future<void> setVirtusizeProps(
      {@required String apiKey,
      String externalUserId,
      Env env = Env.global,
      Language language,
      bool showSGI = false,
      List<Language> allowedLanguages = Language.values,
      List<InfoCategory> detailsPanelCards = InfoCategory.values}) async {
    if (apiKey == null) {
      throw FlutterError("The API key is required");
    }
    try {
      Map<dynamic, dynamic> result = await IVirtusizePlugin.instance._channel
          .invokeMethod('setVirtusizeProps', {
        VirtusizeFlutterKey.apiKey: apiKey,
        VirtusizeFlutterKey.externalUserID: externalUserId,
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
      VSText.load(result[VirtusizeFlutterKey.displayLanguage], language)
          .then((value) {
        IVirtusizePlugin.instance._vsTextController.add(value);
        IVirtusizePlugin.instance.vsText = value;
      });
    } on PlatformException catch (error) {
      print('Failed to set the Virtusize props: $error');
    }
  }

  Future<void> setUserID(String userId) async {
    if (userId == null || userId.isEmpty) {
      print('Failed to set the external user ID: userId is null or empty');
      return;
    }
    try {
      await IVirtusizePlugin.instance._channel
          .invokeMethod('setUserID', userId);
    } on PlatformException catch (error) {
      print('Failed to set the external user ID: $error');
    }
  }

  Future<void> setProduct(
      {@required String externalId, String imageUrl}) async {
    ProductDataCheck productDataCheck =
        await getProductDataCheck(externalId, imageUrl);
    IVirtusizePlugin.instance._pdcController.add(productDataCheck);
    if (productDataCheck.isValidProduct) {
      _getRecommendationText(productDataCheck: productDataCheck);
    }
  }

  Future<ProductDataCheck> getProductDataCheck(
      String externalId, String imageUrl) async {
    try {
      ProductDataCheck productDataCheck = await IVirtusizePlugin
          .instance._channel
          .invokeMethod('getProductDataCheck', {
        VirtusizeFlutterKey.externalProductID: externalId,
        VirtusizeFlutterKey.imageUrl: imageUrl
      }).then((value) => ProductDataCheck(value, externalId));
      if (_virtusizeMessageListener != null) {
        _virtusizeMessageListener.productDataCheckData.call(productDataCheck);
      }
      return productDataCheck;
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeProduct: $error');
      if (_virtusizeMessageListener != null) {
        _virtusizeMessageListener.productDataCheckError.call(error);
      }
    }
    return null;
  }

  Future<void> _getRecommendationText(
      {@required ProductDataCheck productDataCheck}) async {
    try {
      IVirtusizePlugin.instance._recController.add(Recommendation(json.encode(
          await IVirtusizePlugin.instance._channel.invokeMethod(
              'getRecommendationText', productDataCheck.productId))));
    } on PlatformException catch (error) {
      print('Failed to get RecommendationText: $error');
      IVirtusizePlugin.instance._recController.add(Recommendation(
          "{\"${VirtusizeFlutterKey.externalProductID}\": \"${productDataCheck.externalProductId}\"}"));
    }
  }

  Future<void> openVirtusizeWebView() async {
    try {
      await IVirtusizePlugin.instance._channel
          .invokeMethod('openVirtusizeWebView');
    } on PlatformException catch (error) {
      print('Failed to open the VirtusizeWebView: $error');
    }
  }

  void setVirtusizeMessageListener(VirtusizeMessageListener listener) {
    _virtusizeMessageListener = listener;
  }

  Future<void> sendOrder(
      {@required VirtusizeOrder order,
      Function(Map<dynamic, dynamic> sentOrder) onSuccess,
      Function(Exception e) onError}) async {
    try {
      Map<dynamic, dynamic> sentOrder = await IVirtusizePlugin.instance._channel
          .invokeMethod('sendOrder', order.toJson());
      onSuccess(sentOrder);
    } on PlatformException catch (error) {
      print('Failed to send the order: $error');
      onError(error);
    }
  }
}

class IVirtusizePlugin {
  static final IVirtusizePlugin instance = IVirtusizePlugin._();

  MethodChannel _channel =
      const MethodChannel('com.virtusize/virtusize_flutter_plugin');

  VSText vsText;

  StreamController _vsTextController;

  Stream<VSText> get vsTextStream => _vsTextController.stream;

  StreamController _pdcController;

  Stream<ProductDataCheck> get pdcStream => _pdcController.stream;

  StreamController _productController;

  Stream<VirtusizeProduct> get productStream => _productController.stream;

  StreamController _recController;

  Stream<Recommendation> get recStream => _recController.stream;

  IVirtusizePlugin._();

  Future<String> getPrivacyPolicyLink() async {
    try {
      return await _channel.invokeMethod('getPrivacyPolicyLink');
    } on PlatformException catch (error) {
      print('Failed to get the privacy policy link: $error');
      return null;
    }
  }

  Future<void> addProduct({@required String externalProductId}) async {
    if (externalProductId == null) {
      return;
    }
    try {
      await _channel.invokeMethod('addProduct', externalProductId);
    } on PlatformException catch (error) {
      print('Failed to add the product $externalProductId: $error');
    }
  }

  Future<void> removeProduct() async {
    try {
      await _channel.invokeMethod('removeProduct');
    } on PlatformException catch (error) {
      print('Failed to remove a product $error');
    }
  }
}
