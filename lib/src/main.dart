import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_product.dart';

class VirtusizePlugin {
  static const MethodChannel _channel =
  const MethodChannel('com.virtusize/virtusize_flutter_plugin');

  static ClientProduct product;
  static bool productDataCheck = false;

  static Future<void> setVirtusizeProps(
      String apiKey,
      [String externalUserId,
      Env env,
      Language language,
      bool showSGI,
      List<Language> allowedLanguages,
      List<InfoCategory> detailsPanelCards]
      ) async {
    try {
      await _channel.invokeMethod(
          'setVirtusizeProps',
          {
            'apiKey': apiKey,
            'externalUserId': externalUserId,
            'env': env.value,
            'language': language.value,
            'showSGI': showSGI,
            'allowedLanguages': allowedLanguages.map((language) { return language.value;}).toList(),
            'detailsPanelCards': detailsPanelCards.map((infoCategory) { return infoCategory.value;}).toList()
          }
      );
    } on PlatformException catch (error) {
      print('Failed to set the Virtusize props: $error');
    }
  }

  static void setProduct({@required String externalId, String imageUrl}) {
    product = ClientProduct(externalId: externalId, imageUrl: imageUrl);
  }

  static Future<bool> getProductDataCheck() async {
    try {
      return await _channel.invokeMethod(
          'getProductDataCheck',
          {
            'externalId': product.externalId,
            'imageUrl': product.imageUrl
          }
      );
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeProduct: $error');
    }
    return false;
  }

  static Future<void> openVirtusizeWebView() async {
    try {
      await _channel.invokeMethod('openVirtusizeWebView');
    } on PlatformException catch (error) {
      print('Failed to open the VirtusizeWebView: $error');
    }
  }

  static Future<void> setVirtusizeView(String viewType, int id) async {
    try {
      await _channel.invokeMethod(
          'setVirtusizeView',
          { 'viewType': viewType.toString(),
            'viewId': id
          }
      );
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeView: $error');
    }
  }
}