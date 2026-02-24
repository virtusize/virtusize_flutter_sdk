import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtusize_flutter_sdk/src/main.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_client_product.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_enums.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_order.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_order_item.dart';
import 'package:virtusize_flutter_sdk/src/utils/virtusize_constants.dart';

const channelName = 'com.virtusize/flutter_virtusize_sdk';
const channel = MethodChannel(channelName);
const privacyPolicyLink = 'https://www.virtusize.com/privacy-policy';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case FlutterVirtusizeMethod.setVirtusizeParams:
              return {
                FlutterVirtusizeKey.virtusizeParams: 'params',
                FlutterVirtusizeKey.displayLanguage: 'en',
              };
            case FlutterVirtusizeMethod.getPrivacyPolicyLink:
              return privacyPolicyLink;
            case FlutterVirtusizeMethod.sendOrder:
              return methodCall.arguments;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('VirtusizeSDK Tests', () {
    test('setVirtusizeParams sends correct parameters to platform', () async {
      await VirtusizeSDK.instance.setVirtusizeParams(
        apiKey: 'test_api_key',
        env: VSEnvironment.staging,
        language: VSLanguage.en,
      );

      expect(log, hasLength(1));
      expect(log[0].method, FlutterVirtusizeMethod.setVirtusizeParams);
      expect(log[0].arguments[FlutterVirtusizeKey.apiKey], 'test_api_key');
      expect(
        log[0].arguments[FlutterVirtusizeKey.environment],
        VSEnvironment.staging.value,
      );
      expect(
        log[0].arguments[FlutterVirtusizeKey.language],
        VSLanguage.en.value,
      );
    });

    test('loadVirtusize sends correct product data to platform', () async {
      final externalProductId = 'product123';
      final imageURL = 'https://example.com/image.jpg';

      final clientProduct = VirtusizeClientProduct(
        externalProductId: externalProductId,
        imageURL: imageURL,
      );

      await VirtusizeSDK.instance.loadVirtusize(clientProduct);

      expect(log, hasLength(1));
      expect(log[0].method, FlutterVirtusizeMethod.loadVirtusize);
      expect(
        log[0].arguments[FlutterVirtusizeKey.externalProductId],
        externalProductId,
      );
      expect(log[0].arguments[FlutterVirtusizeKey.imageURL], imageURL);
    });

    test('setUserId sends userId to platform', () async {
      final userId = 'user123';
      await VirtusizeSDK.instance.setUserId(userId);

      expect(log, hasLength(1));
      expect(log[0].method, FlutterVirtusizeMethod.setUserId);
      expect(log[0].arguments, userId);
    });

    test('setUserId ignores empty userId', () async {
      await VirtusizeSDK.instance.setUserId('');

      expect(log, isEmpty);
    });

    test('openVirtusizeWebView sends productId to platform', () async {
      final externalProductId = 'product123';
      final imageURL = 'https://example.com/image.jpg';

      final clientProduct = VirtusizeClientProduct(
        externalProductId: externalProductId,
        imageURL: imageURL,
      );

      await VirtusizeSDK.instance.openVirtusizeWebView(clientProduct);

      expect(log, hasLength(1));
      expect(log[0].method, FlutterVirtusizeMethod.openVirtusizeWebView);
      expect(log[0].arguments, externalProductId);
    });

    test('getPrivacyPolicyLink returns privacy policy URL', () async {
      final url = await IVirtusizeSDK.instance.getPrivacyPolicyLink();

      expect(log, hasLength(1));
      expect(log[0].method, FlutterVirtusizeMethod.getPrivacyPolicyLink);
      expect(url, privacyPolicyLink);
    });

    test(
      'sendOrder sends order data to platform and invokes success callback',
      () async {
        bool successCalled = false;
        Map<dynamic, dynamic>? result;

        final orderItem = VirtusizeOrderItem(
          externalProductId: "A001",
          size: "L",
          sizeAlias: "Large",
          variantId: "A001_SIZEL_RED",
          imageURL: "http://images.example.com/products/A001/red/image1xl.jpg",
          color: "Red",
          gender: "W",
          unitPrice: 5100.00,
          currency: "JPY",
          quantity: 1,
          url: "http://example.com/products/A001",
        );

        final order = VirtusizeOrder(
          externalOrderId: 'order123',
          items: [orderItem],
        );

        await VirtusizeSDK.instance.sendOrder(
          order: order,
          onSuccess: (sentOrder) {
            successCalled = true;
            result = sentOrder;
          },
          onError: (e) {
            fail('Should not call error callback');
          },
        );

        expect(log, hasLength(1));
        expect(log[0].method, FlutterVirtusizeMethod.sendOrder);
        expect(log[0].arguments['externalOrderId'], 'order123');
        expect(log[0].arguments['items'], isA<List>());
        expect(log[0].arguments['items'].length, 1);
        expect(log[0].arguments['items'][0]['externalProductId'], 'A001');
        expect(successCalled, isTrue);
        expect(result, isNotNull);
      },
    );
  });

  group('Method call handler tests', () {
    test('_methodCallHandler processes onProductDataCheck correctly', () async {
      final completer = Completer<bool>();

      IVirtusizeSDK.instance.pdcStream.listen((pdc) {
        final matcher = 'product123';
        expect(pdc.externalProductId, matcher);
        expect(pdc.isValidProduct, true);
        expect(pdc.storeName, "");
        completer.complete(true);
      });

      //Simulate platform calling the method
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(FlutterVirtusizeMethod.onProductDataCheck, {
                FlutterVirtusizeKey.externalProductId: 'product123',
                FlutterVirtusizeKey.isValidProduct: true,
                FlutterVirtusizeKey.storeName: "",
              }),
            ),
            (_) {},
          );

      expect(await completer.future, isTrue);
    });

    test('_methodCallHandler processes onRecChange correctly', () async {
      final externalProductId = 'product123';
      final recText = 'Recommended size: L';

      final completer = Completer<bool>();

      IVirtusizeSDK.instance.recStream.listen((recChange) {
        expect(recChange.externalProductID, externalProductId);
        expect(recChange.showUserProductImage, true);
        expect(recChange.text, recText);
        completer.complete(true);
      });

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(FlutterVirtusizeMethod.onRecChange, {
                FlutterVirtusizeKey.externalProductId: externalProductId,
                FlutterVirtusizeKey.showUserProductImage: true,
                FlutterVirtusizeKey.recText: recText,
              }),
            ),
            (_) {},
          );

      expect(await completer.future, isTrue);
    });

    test('_methodCallHandler processes onProductError correctly', () async {
      final externalProductId = 'product123';
      final completer = Completer<bool>();

      IVirtusizeSDK.instance.productErrorStream.listen((productId) {
        expect(productId, externalProductId);
        completer.complete(true);
      });

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(
                FlutterVirtusizeMethod.onProductError,
                externalProductId,
              ),
            ),
            (_) {},
          );

      expect(await completer.future, isTrue);
    });
  });
}
