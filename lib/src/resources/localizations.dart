import 'package:flutter/services.dart' show rootBundle;
import '../../src/models/virtusize_localization.dart';

class VSLocalizations {
  VSLocalizations._(this.vsLocalization);

  final VirtusizeLocalization vsLocalization;

  static Future<VSLocalizations> load(String localName) async {
    VirtusizeLocalization localization = VirtusizeLocalization(
        await rootBundle.loadString('packages/virtusize_flutter_plugin/assets/i18n/$localName.json'));
    return VSLocalizations._(localization);
  }
}
