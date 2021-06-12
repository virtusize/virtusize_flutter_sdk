import 'dart:async';
import 'package:flutter/services.dart';

class VirtusizePlugin {
  static const MethodChannel _channel =
      const MethodChannel('com.virtusize/virtusize_flutter_plugin');

  static Future<String> setVirtusizeProps(
      String apiKey,
      String externalUserId,
      Env env,
      Language language,
      bool showSGI,
      List<Language> allowedLanguages,
      List<InfoCategory> detailsPanelCards
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

  static Future<void> setVirtusizeProduct(
      String externalId,
      String imageUrl
      ) async {
    await _channel.invokeMethod(
        'setVirtusizeProduct',
        {
          'externalId': externalId,
          'imageUrl': imageUrl
        }
    );
  }

  static Future<void> setVirtusizeView(int viewId) async {
    await _channel.invokeMethod(
        'setVirtusizeView',
        {'viewId': viewId}
    );
  }
}

enum Env {
  staging,
  global,
  japan,
  korea
}

extension EnvExtension on Env {
  String get value {
    return ["STAGING", "GLOBAL", "JAPAN", "KOREA"][this.index];
  }
}

enum Language {
  en,
  jp,
  kr
}

extension LanguageExtension on Language {
  String get value {
    return ["EN", "JP", "KR"][this.index];
  }
}

enum InfoCategory {
  modelInfo,
  generalFit,
  brandSizing,
  material
}

extension InfoCategoryExtension on InfoCategory {
  String get value {
    return ["MODEL_INFO", "GENERAL_FIT", "BRAND_SIZING", "MATERIAL"][this.index];
  }
}