import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/flutter_virtusize_sdk.dart';
import '../lib/src/utils/virtusize_constants.dart';

void main() {
  const MethodChannel channel = MethodChannel('virtusize_flutter_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test(VirtusizeFlutterMethod.setVirtusizeParams, () async {
    expect(await VirtusizePlugin.instance.setVirtusizeParams, '42');
  });
}
