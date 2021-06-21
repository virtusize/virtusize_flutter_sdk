import 'dart:async';
import 'package:flutter/services.dart';
import 'models.dart';

class VirtusizePlugin {
  static const MethodChannel _channel =
  const MethodChannel('com.virtusize/virtusize_flutter_plugin');

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

  static Future<void> setProduct(
      String externalId,
      [String imageUrl]
      ) async {
    try {
      await _channel.invokeMethod(
          'setProduct',
          {
            'externalId': externalId,
            'imageUrl': imageUrl
          }
      );
    } on PlatformException catch (error) {
      print('Failed to set VirtusizeProduct: $error');
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