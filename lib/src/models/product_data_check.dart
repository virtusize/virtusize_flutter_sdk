import 'virtusize_model.dart';

class ProductDataCheck extends VirtusizeModel {

  ProductDataCheck(data) : super(data);

  Map<String, dynamic> get data => decodedData["data"] ?? {};

  bool get isValidProduct => data["validProduct"] ?? false;

  String get productId  => data["productId"];
}
