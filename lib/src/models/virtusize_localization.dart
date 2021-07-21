import 'virtusize_model.dart';

class VirtusizeLocalization extends VirtusizeModel {

  VirtusizeLocalization(data) : super(data);

  String get vsButtonText => decodedData["vs_button_text"];
  String get vsPrivacyPolicy => decodedData["vs_privacy_policy"];
  String get vsLoadingText => decodedData["vs_loading_text"];
  String get vsShortErrorText => decodedData["vs_short_error_text"];
  String get vsLongErrorText => decodedData["vs_long_error_text"];
}