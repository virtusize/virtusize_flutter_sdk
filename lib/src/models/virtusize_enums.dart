enum VirtusizeStyle { None, Black, Teal }

extension VirtusizeStyleExtension on VirtusizeStyle {
  String get value {
    return ["NONE", "BLACK", "TEAL"][this.index];
  }
}

enum Env { staging, global, japan, korea }

extension EnvExtension on Env {
  String get value {
    return ["STAGING", "GLOBAL", "JAPAN", "KOREA"][this.index];
  }
}

enum Language { en, jp, kr }

extension LanguageExtension on Language {
  String get value {
    return ["EN", "JP", "KR"][this.index];
  }

  String get langCode {
    return ["en", "ja", "kr"][this.index];
  }
}

enum InfoCategory { modelInfo, generalFit, brandSizing, material }

extension InfoCategoryExtension on InfoCategory {
  String get value {
    return [
      "MODEL_INFO",
      "GENERAL_FIT",
      "BRAND_SIZING",
      "MATERIAL"
    ][this.index];
  }
}

enum ProductImageType { store, user }
