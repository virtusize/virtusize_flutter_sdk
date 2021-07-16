import 'package:flutter/services.dart' show rootBundle;

import '../../src/models/virtusize_enums.dart';
import '../../src/resources/font.dart';
import '../../src/models/virtusize_localization.dart';

class VSText {
  VSText._(this.localization, this.vsFont);

  final VirtusizeLocalization localization;
  final VSFont vsFont;

  static Future<VSText> load(String localeName, Language language) async {
    VirtusizeLocalization localization = VirtusizeLocalization(
        await rootBundle.loadString('packages/virtusize_flutter_plugin/assets/i18n/$localeName.json'));
    try {
      language = Language.values.firstWhere((lang) => lang.langCode == localeName);
    } catch(e) {
      print('Could not get the language by the locale name $localeName, $e');
    }
    return VSText._(localization, VSFont(language));
  }
}
