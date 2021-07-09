import 'dart:convert';

class VirtusizeModel {
  Map<String, dynamic> decodeJson(String jsonString) {
    if (jsonString != null) {
      return json.decode(jsonString);
    } else {
      return {};
    }
  }
}