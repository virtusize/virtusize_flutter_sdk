import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

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

  test('setVirtusizeProps', () async {
    expect(await VirtusizePlugin.setVirtusizeProps, '42');
  });
}
