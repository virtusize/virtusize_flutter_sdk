import '../utils/virtusize_constants.dart';
import 'virtusize_model.dart';

class Recommendation extends VirtusizeModel {
  Recommendation(super.data);

  /// A string to represent an external product ID in the client's system
  String get externalProductID =>
      decodedData[FlutterVirtusizeKey.externalProductId];

  /// A recommendation text to be displayed on the [VirtusizeInPageStandard] or [VirtusizeInPageMini] widget
  String get text => decodedData[FlutterVirtusizeKey.recText];

  /// A boolean to determine whether to show the `user product` image on the [VirtusizeInPageStandard] widget
  bool get showUserProductImage =>
      decodedData[FlutterVirtusizeKey.showUserProductImage] ?? false;
}
