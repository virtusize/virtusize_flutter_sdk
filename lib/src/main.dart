import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/product_data_check.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_product.dart';

class VirtusizePlugin {
  static final VirtusizePlugin instance = VirtusizePlugin._();

  ClientProduct product;
  StreamController _pdcController;
  StreamController _recTextController;

  StreamSink<ProductDataCheck> get _pdcSink =>
      _pdcController.sink;

  Stream<ProductDataCheck> get pdcStream =>
      _pdcController.stream;

  StreamSink<String> get _recTextSink =>
      _recTextController.sink;

  Stream<String> get recTextStream =>
      _recTextController.stream;

  VirtusizePlugin._() {
    _pdcController = StreamController<ProductDataCheck>.broadcast();
    _recTextController = StreamController<String>.broadcast();
    _channel.setMethodCallHandler((call) {
      print(call);
      if(call.method == "onRecTextChange") {
        _recTextSink.add(call.arguments);
      }
      return null;
    });
  }

  static const MethodChannel _channel =
      const MethodChannel('com.virtusize/virtusize_flutter_plugin');

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

  Future<void> setProduct({@required String externalId, String imageUrl}) async {
    product = ClientProduct(externalId: externalId, imageUrl: imageUrl);
    ProductDataCheck productDataCheck = await currentProductDataCheck;
    _pdcSink.add(productDataCheck);
    if(productDataCheck.isValidProduct) {
      getRecommendationText();
    }
  }

  Future<ProductDataCheck> get currentProductDataCheck async {
    try {
      return await _channel.invokeMethod('getProductDataCheck', {
        'externalId': product.externalId,
        'imageUrl': product.imageUrl
      }).then((value) =>
          ProductDataCheck(value));
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeProduct: $error');
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

  Future<void> setVirtusizeView(String viewType, int id) async {
    try {
      await _channel.invokeMethod(
          'setVirtusizeView', {'viewType': viewType.toString(), 'viewId': id});
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeView: $error');
    }
  }

  Future<void> getRecommendationText() async {
    try {
      _recTextSink.add(await _channel.invokeMethod('getRecommendationText'));
    } on PlatformException catch (error) {
      print('Failed to get RecommendationText: $error');
      _recTextSink.add(null);
    }
  }
}