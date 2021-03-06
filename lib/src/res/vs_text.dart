import 'package:flutter/services.dart' show rootBundle;

import '../../src/models/virtusize_enums.dart';
import '../../src/res/vs_font.dart';
import '../../src/models/virtusize_localization.dart';

/// A class to cache the i18n localization data and the custom font info based on the designated language
class VSText {
  VSText._(this.localization, this.vsFont);

  final VirtusizeLocalization localization;
  final VSFont vsFont;

  /// Loads the localization from the local i18n json files and the custom font info
  static Future<VSText> load(String localeName, VSLanguage language) async {
    VirtusizeLocalization localization = VirtusizeLocalization(
        await rootBundle.loadString('packages/virtusize_flutter_sdk/assets/i18n/$localeName.json'));
    try {
      language = VSLanguage.values.firstWhere((lang) => lang.langCode == localeName);
    } catch(e) {
      print('Could not get the language by the locale name $localeName, $e');
    }
    return VSText._(localization, VSFont(language));
  }
}
