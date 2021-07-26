import '../utils/virtusize_constants.dart';
import 'virtusize_model.dart';

class Recommendation extends VirtusizeModel {
  Recommendation(data) : super(data);

  String get externalProductID => decodedData[VirtusizeFlutterKey.externalProductID];

  String get text => decodedData[VirtusizeFlutterKey.recText];

  bool get showUserProductImage => decodedData[VirtusizeFlutterKey.showUserProductImage];
}