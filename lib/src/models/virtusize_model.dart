import 'dart:convert';

class VirtusizeModel {
  dynamic decodeJson(String jsonString) {
    if (jsonString != null) {
      return json.decode(jsonString);
    } else {
      return {};
    }
  }
}