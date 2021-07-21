import 'virtusize_model.dart';

class ProductDataCheck extends VirtusizeModel {

  final String externalProductId;

  ProductDataCheck(data, this.externalProductId) : super(data);

  Map<String, dynamic> get data => decodedData["data"] ?? {};
  bool get isValidProduct => data["validProduct"] ?? false;
  int get productId  => data["productDataId"];

  @override
  String toString() {
    return '{externalProductId: $externalProductId, data: $data}';
  }
}
