import 'dart:convert';

/// A parent class with an inheritable function which decodes a JSON string.
class VirtusizeModel {
  final dynamic _data;
  late final Map<String, dynamic> decodedData;

  VirtusizeModel(this._data) {
    decodedData = _decodeJson(_data);
  }

  Map<String, dynamic> _decodeJson(String? jsonString) {
    return jsonString != null ? json.decode(jsonString) : {};
  }
}
