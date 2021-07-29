import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/virtusize_sdk.dart';
import '../lib/src/utils/virtusize_constants.dart';

void main() {
  const MethodChannel channel = MethodChannel('com.virtusize/flutter_virtusize_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test(FlutterVirtusizeMethod.setVirtusizeParams, () async {
    expect(await VirtusizeSDK.instance.setVirtusizeParams, '42');
  });
}
