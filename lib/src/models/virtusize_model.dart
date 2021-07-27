import 'dart:convert';

/// A parent class with a function to decode a JSON string to a Map of String to dynamic.
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