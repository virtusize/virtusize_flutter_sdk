import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/main.dart';
import '../lib/src/utils/virtusize_constants.dart';

void main() {
  const MethodChannel channel = MethodChannel('com.virtusize/flutter_virtusize_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case FlutterVirtusizeMethod.setVirtusizeParams:
          return {
            "virtusizeParams": {
              "showSGI": false,
              "apiKey": "apiKey",
              "allowedLanguages": ["EN", "JP", "KR"],
              "externalUserId": null,
              "detailsPanelCards": ["MODEL_INFO", "GENERAL_FIT", "BRAND_SIZING", "MATERIAL"],
              "language": null,
              "env": "GLOBAL"
            },
            "displayLanguage": "en"
          };
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test("Set the Virtusize parameters", () async {
    await VirtusizeSDK.instance.setVirtusizeParams(
      apiKey: "apiKey"
    );
  });

}
