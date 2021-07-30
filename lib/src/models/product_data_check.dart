import 'virtusize_model.dart';

class ProductDataCheck extends VirtusizeModel {

  /// A string to represent a external product ID from a client's system
  final String externalProductId;

  ProductDataCheck(this.externalProductId, data) : super(data);

  /// The data of the product data check result from Native
  Map<String, dynamic> get data => decodedData["data"] ?? {};

  /// A boolean to tell whether it's a valid product in the Virtusize server
  bool get isValidProduct => data["validProduct"] ?? false;

  /// An integer to represent the internal product ID in the Virtusize server
  int get productId  => data["productDataId"];

  @override
  String toString() {
    return '{externalProductId: $externalProductId, data: $data}';
  }
}
