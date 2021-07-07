import 'dart:convert';

class VirtusizeModel {
  final dynamic _data;
  Map<String, dynamic> decodedData;

  VirtusizeModel(this._data) {
    decodedData = _decodeJson(_data);
  }

  Map<String, dynamic> _decodeJson(String jsonString) {
    if (jsonString != null) {
      return json.decode(jsonString);
    } else {
      return {};
    }
  }
}