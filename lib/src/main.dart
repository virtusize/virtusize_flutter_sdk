import 'dart:async';
import 'package:flutter/services.dart';
import 'package:virtusize_flutter_plugin/src/models.dart';
import 'package:virtusize_flutter_plugin/src/virtusize_view.dart';

class VirtusizePlugin {
  static const MethodChannel _channel =
  const MethodChannel('com.virtusize/virtusize_flutter_plugin');

  static Future<String> setVirtusizeProps(
      String apiKey,
      [String externalUserId,
      Env env,
      Language language,
      bool showSGI,
      List<Language> allowedLanguages,
      List<InfoCategory> detailsPanelCards]
      ) async {
    final String virtusize = await _channel.invokeMethod(
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
    return virtusize;
  }

  static Future<void> setProduct(
      String externalId,
      String imageUrl
      ) async {
    await _channel.invokeMethod(
        'setProduct',
        {
          'externalId': externalId,
          'imageUrl': imageUrl
        }
    );
  }

  static Future<void> setVirtusizeView(VirtusizeView virtusizeView) async {
    await _channel.invokeMethod(
        'setVirtusizeView',
        { 'viewType': virtusizeView.toString(),
          'viewId': virtusizeView.getId()
        }
    );
  }
}