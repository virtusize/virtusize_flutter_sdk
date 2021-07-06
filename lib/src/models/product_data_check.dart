import 'virtusize_model.dart';

class ProductDataCheck extends VirtusizeModel {
  final dynamic _data;
  Map<String, dynamic> _decodedData;

  ProductDataCheck(this._data) {
    print(this._data);
    _decodedData = decodeJson(_data);
  }

  Map<String, dynamic> get data => _decodedData["data"] ?? {};

  bool get isValidProduct => data["validProduct"] ?? false;

  String get productId  => data["productId"];
}
