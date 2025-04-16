/// This enum contains all the styles that can be applied to the Virtusize widgets
enum VirtusizeStyle { none, black, teal }

extension VirtusizeStyleExtension on VirtusizeStyle {
  String get value {
    return ["NONE", "BLACK", "TEAL"][index];
  }
}

/// This enum contains all available Virtusize environments
enum VSEnvironment { staging, global, japan, korea }

extension VSEnvExtension on VSEnvironment {
  String get value {
    return ["STAGING", "GLOBAL", "JAPAN", "KOREA"][index];
  }
}

/// This enum contains all the possible display languages of the Virtusize webview
enum VSLanguage { en, jp, kr }

extension LanguageExtension on VSLanguage {
  String get value {
    return ["EN", "JP", "KR"][index];
  }

  String get langCode {
    return ["en", "ja", "ko"][index];
  }
}

/// This enum contains all the possible info categories that will be displayed in the Product Details tab of the Virtusize webview
enum VSInfoCategory { modelInfo, generalFit, brandSizing, material }

extension InfoCategoryExtension on VSInfoCategory {
  String get value {
    return ["MODEL_INFO", "GENERAL_FIT", "BRAND_SIZING", "MATERIAL"][index];
  }
}
