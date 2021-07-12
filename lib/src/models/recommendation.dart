import 'virtusize_model.dart';

class Recommendation extends VirtusizeModel {
  Recommendation(data) : super(data);

  String get text => decodedData["text"];

  bool get showUserProductImage => decodedData["showUserProductImage"];
}