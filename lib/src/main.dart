import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/virtusize_message_listener.dart';
import 'models/recommendation.dart';
import 'models/product.dart';
import 'models/product_data_check.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_order.dart';
import 'models/virtusize_product.dart';


class VirtusizePlugin {
  static final VirtusizePlugin instance = VirtusizePlugin._();

  static const MethodChannel _channel =
  const MethodChannel('com.virtusize/virtusize_flutter_plugin');

  ClientProduct product;
  StreamController _pdcController;
  StreamController _recController;
  StreamController _productController;
  VirtusizeMessageListener _virtusizeEventListener;

  StreamSink<ProductDataCheck> get _pdcSink =>
      _pdcController.sink;
  Stream<ProductDataCheck> get pdcStream =>
      _pdcController.stream;

  StreamSink<Product> get _productSink =>
      _productController.sink;
  Stream<Product> get productStream =>
      _productController.stream;

  StreamSink<Recommendation> get _recSink =>
      _recController.sink;
  Stream<Recommendation> get recStream =>
      _recController.stream;

  VirtusizePlugin._() {
    _pdcController = StreamController<ProductDataCheck>.broadcast();
    _productController = StreamController<Product>.broadcast();
    _recController = StreamController<Recommendation>.broadcast();
    _channel.setMethodCallHandler((call) {
      if(call.method == "onRecChange") {
        _recSink.add(Recommendation(json.encode(call.arguments)));
      } else if(call.method == "onProduct") {
        _productSink.add(Product(json.encode(call.arguments)));
      } else if(call.method == "onVSEvent") {
        if(_virtusizeEventListener != null) {
          _virtusizeEventListener.vsEvent.call(call.arguments);
        }
      } else if(call.method == "onVSError") {
        if(_virtusizeEventListener != null) {
          _virtusizeEventListener.vsError.call(call.arguments);
        }
      }
      return null;
    });
  }

  Future<void> setVirtusizeProps({@required String apiKey,
      String externalUserId,
      Env env = Env.global,
      Language language = Language.jp,
      bool showSGI = false,
      List<Language> allowedLanguages = Language.values,
      List<InfoCategory> detailsPanelCards = InfoCategory.values
  }) async {
    if(apiKey == null) {
      throw FlutterError("The API key is required");
    }
    try {
      await _channel.invokeMethod('setVirtusizeProps', {
        'apiKey': apiKey,
        'externalUserId': externalUserId,
        'env': env.value,
        'language': language.value,
        'showSGI': showSGI,
        'allowedLanguages': allowedLanguages.map((language) {
          return language.value;
        }).toList(),
        'detailsPanelCards': detailsPanelCards.map((infoCategory) {
          return infoCategory.value;
        }).toList()
      });
    } on PlatformException catch (error) {
      print('Failed to set the Virtusize props: $error');
    }
  }

  Future<void> setUserID(String userId) async {
    if(userId == null || userId.isEmpty) {
      print('Failed to set the external user ID: userId is null or empty');
      return;
    }
    try {
      await _channel.invokeMethod('setUserID', userId);
    } on PlatformException catch (error) {
      print('Failed to set the external user ID: $error');
    }
  }

  Future<void> setProduct({@required String externalId, String imageUrl}) async {
    product = ClientProduct(externalId: externalId, imageUrl: imageUrl);
    ProductDataCheck productDataCheck = await _currentProductDataCheck;
    _pdcSink.add(productDataCheck);
    if(productDataCheck.isValidProduct) {
      getRecommendationText();
    }
  }

  Future<ProductDataCheck> get _currentProductDataCheck async {
    try {
      ProductDataCheck productDataCheck = await _channel.invokeMethod('getProductDataCheck', {
        'externalId': product.externalId,
        'imageUrl': product.imageUrl
      }).then((value) => ProductDataCheck(value, product.externalId));
      if(_virtusizeEventListener != null) {
        _virtusizeEventListener.productDataCheckData.call(productDataCheck);
      }
      return productDataCheck;
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeProduct: $error');
      if(_virtusizeEventListener != null) {
        _virtusizeEventListener.productDataCheckError.call(error);
      }
    }
    return null;
  }

  Future<void> openVirtusizeWebView() async {
    try {
      await _channel.invokeMethod('openVirtusizeWebView');
    } on PlatformException catch (error) {
      print('Failed to open the VirtusizeWebView: $error');
    }
  }

  Future<void> getRecommendationText() async {
    try {
      _recSink.add(Recommendation(
          json.encode(await _channel.invokeMethod('getRecommendationText'))));
    } on PlatformException catch (error) {
      print('Failed to get RecommendationText: $error');
      _recSink.add(Recommendation(null));
    }
  }

  Future<String> getPrivacyPolicyLink() async {
    try {
      return await _channel.invokeMethod('getPrivacyPolicyLink');
    } on PlatformException catch (error) {
      print('Failed to get the privacy policy link: $error');
      return null;
    }
  }

  void setVirtusizeMessageListener(VirtusizeMessageListener listener) {
    _virtusizeEventListener = listener;
  }

  Future<void> sendOrder({@required VirtusizeOrder order, Function(Map<String, dynamic> orderData) onSuccess, Function(Exception e) onError}) async {
    try {
      await _channel.invokeMethod('sendOrder', order.toJson());
      onSuccess(order.toJson());
    } on PlatformException catch (error) {
      print('Failed to send the order: $error');
      onError(error);
    }
  }
}