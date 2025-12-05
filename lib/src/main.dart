import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_client_product.dart';

import 'models/recommendation.dart';
import 'models/virtusize_server_product.dart';
import 'models/product_data_check.dart';
import 'models/virtusize_enums.dart';
import 'models/virtusize_order.dart';
import 'res/vs_text.dart';
import 'utils/virtusize_constants.dart';
import 'utils/virtusize_message_listener.dart';

/// The main class for flutter apps to access
class VirtusizeSDK {
  /// The singleton instance of this class
  static final VirtusizeSDK instance = VirtusizeSDK._();

  /// A listener to receive Virtusize-specific messages from Native
  VirtusizeMessageListener _virtusizeMessageListener =
      VirtusizeMessageListener();

  /// Initialize the [VirtusizeSDK] instance
  VirtusizeSDK._() {
    // The broadcast stream controllers
    IVirtusizeSDK.instance._vsTextController =
        StreamController<VSText>.broadcast();
    IVirtusizeSDK.instance._pdcController =
        StreamController<ProductDataCheck>.broadcast();
    IVirtusizeSDK.instance._productController =
        StreamController<VirtusizeServerProduct>.broadcast();
    IVirtusizeSDK.instance._recController =
        StreamController<Recommendation>.broadcast();
    IVirtusizeSDK.instance._productErrorController =
        StreamController<String>.broadcast();

    // Sets the method call handler
    IVirtusizeSDK.instance._channel.setMethodCallHandler(_methodCallHandler);
  }

  /// Returns the method call handler that receives data from Native
  Future<dynamic> _methodCallHandler(MethodCall call) {
    // A map to match each method call from Native with its corresponding exectuion
    Map<String, Function> methodCallExecutionMap = {
      FlutterVirtusizeMethod.onRecChange:
          (call) => {
            IVirtusizeSDK.instance._recController.add(
              Recommendation(json.encode(call.arguments)),
            ),
          },
      FlutterVirtusizeMethod.onProduct:
          (call) => {
            IVirtusizeSDK.instance._productController.add(
              VirtusizeServerProduct(json.encode(call.arguments)),
            ),
          },
      FlutterVirtusizeMethod.onProductDataCheck: (call) {
        final externalId =
            call.arguments[FlutterVirtusizeKey.externalProductId];
        final isValidProduct =
            call.arguments[FlutterVirtusizeKey.isValidProduct];
        IVirtusizeSDK.instance._pdcController.add(
          ProductDataCheck(externalId, isValidProduct),
        );
      },
      FlutterVirtusizeMethod.onProductError: (call) {
        final externalProductId = call.arguments;
        IVirtusizeSDK.instance._productErrorController.add(externalProductId);
      },
      FlutterVirtusizeMethod.onVSEvent:
          (call) => {_virtusizeMessageListener.vsEvent?.call(call.arguments)},
      FlutterVirtusizeMethod.onVSError: (call) {
        _virtusizeMessageListener.vsError?.call(call.arguments);
      },
      FlutterVirtusizeMethod.onLanguageClick: (call) {
        final displayLanguage = call.arguments['language'];
        var language = VSLanguage.en;
        _loadVSText(displayLanguage, language);
      },
    };

    final method = methodCallExecutionMap[call.method];
    if (method == null) {
      throw FlutterError('Method not implemented: ${call.method}');
    }

    return method.call(call);
  }

  /// A function for clients to set the Virtusize parameters
  Future<void> setVirtusizeParams(
  /// The unique API key provided for Virtusize clients
  {
    required String apiKey,

    /// The user ID from the client's system (should be unique)
    String? userId,

    /// The Virtusize environment (defaults to the `global` domain)
    VSEnvironment env = VSEnvironment.global,

    /// The [VSLanguage] that sets the initial language the Virtusize webview will load in
    VSLanguage language = VSLanguage.en,

    /// The boolean value to determine if the Virtusize webview should use the SGI flow for users to add user-generated items to their wardrobe
    bool showSGI = false,

    /// The languages that the user can switch between using the Language Selector
    List<VSLanguage> allowedLanguages = VSLanguage.values,

    /// The info categories that will be displayed in the Product Details tab
    List<VSInfoCategory> detailsPanelCards = VSInfoCategory.values,

    // By default, Virtusize enables the SNS buttons
    bool showSNSButtons = true,

    /// Target the specific environment branch by its name
    String? branch,

    // By default, Virtusize shows the Privacy Policy
    bool? showShowPrivacyPolicy = true,

    /// The boolean value to determine whether to use or not services.virtusize.com url
    bool serviceEnvironment = true,
  }) async {
    try {
      // [paramsData] is a map with two key-value pairs to return the Virtusize parameters and the display language from Native
      Map<dynamic, dynamic> paramsData = await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.setVirtusizeParams, {
            FlutterVirtusizeKey.apiKey: apiKey,
            FlutterVirtusizeKey.externalUserId: userId,
            FlutterVirtusizeKey.environment: env.value,
            FlutterVirtusizeKey.language: language.value,
            FlutterVirtusizeKey.showSGI: showSGI,
            FlutterVirtusizeKey.allowedLanguages:
                allowedLanguages.map((language) {
                  return language.value;
                }).toList(),
            FlutterVirtusizeKey.detailsPanelCards:
                detailsPanelCards.map((infoCategory) {
                  return infoCategory.value;
                }).toList(),
            FlutterVirtusizeKey.showSNSButtons: showSNSButtons,
            FlutterVirtusizeKey.branch: branch,
            FlutterVirtusizeKey.showPrivacyPolicy: showShowPrivacyPolicy,
            FlutterVirtusizeKey.serviceEnvironment: serviceEnvironment,
      });

      IVirtusizeSDK.instance._showPrivacyPolicy = showShowPrivacyPolicy;

      await _loadVSText(
        paramsData[FlutterVirtusizeKey.displayLanguage],
        language,
      );
    } on PlatformException catch (error) {
      log(
        'Failed to set the Virtusize parameters: $error',
        name: virtusizeLogLabel,
      );
    }
  }

  Future<void> _loadVSText(String displayLanguage, VSLanguage language) async {
    try {
      final vsText = await VSText.load(displayLanguage, language);
      IVirtusizeSDK.instance._vsTextController.add(vsText);
      IVirtusizeSDK.instance.vsText = vsText;
    } catch (e) {
      log(
        'Failed to load the i18n localization data and the custom font information',
        name: virtusizeLogLabel,
      );
    }
  }

  /// A function for clients to populate the Virtusize widgets by passing the product info
  Future<void> loadVirtusize(VirtusizeClientProduct clientProduct) async {
    await IVirtusizeSDK.instance._channel.invokeMethod(
      FlutterVirtusizeMethod.loadVirtusize,
      {
        FlutterVirtusizeKey.externalProductId: clientProduct.externalProductId,
        FlutterVirtusizeKey.imageURL: clientProduct.imageURL,
      },
    );
  }

  /// A function for clients to set the user ID
  Future<void> setUserId(String userId) async {
    if (userId.isEmpty) {
      log(
        'Failed to set the external user ID: userId is empty',
        name: virtusizeLogLabel,
      );
      return;
    }
    try {
      await IVirtusizeSDK.instance._channel.invokeMethod(
        FlutterVirtusizeMethod.setUserId,
        userId,
      );
    } on PlatformException catch (error) {
      log(
        'Failed to set the external user ID: $error',
        name: virtusizeLogLabel,
      );
    }
  }

  /// A function for clients to open the Virtusize webview (only when they customize their own button using the [VirtusizeButton] widget)
  Future<void> openVirtusizeWebView(VirtusizeClientProduct product) async {
    try {
      await IVirtusizeSDK.instance._channel.invokeMethod(
        FlutterVirtusizeMethod.openVirtusizeWebView,
        product.externalProductId,
      );
    } on PlatformException catch (error) {
      log(
        'Failed to open the VirtusizeWebView: $error',
        name: virtusizeLogLabel,
      );
    }
  }

  /// A function for clients to set a listener for Virtusize-specific messages
  void setVirtusizeMessageListener(VirtusizeMessageListener listener) {
    _virtusizeMessageListener = listener;
  }

  /// A function for clients to send an order to the Virtusize server
  Future<void> sendOrder(
  /// A [VirtusizeOrder] to be sent to the server
  {
    required VirtusizeOrder order,

    /// [onSuccess] callback to get a map of the order data back when `sendOrder` is successful
    Function(Map<dynamic, dynamic> sentOrder)? onSuccess,

    /// [onError] callback to get an error exception back when `sendOrder` is unsuccessful
    Function(Exception e)? onError,
  }) async {
    try {
      Map<dynamic, dynamic> sentOrder = await IVirtusizeSDK.instance._channel
          .invokeMethod(FlutterVirtusizeMethod.sendOrder, order.toJson());
      onSuccess?.call(sentOrder);
    } on PlatformException catch (error) {
      log('Failed to send an order: $error', name: virtusizeLogLabel);
      onError?.call(error);
    }
  }
}

/// The main internal class
class IVirtusizeSDK {
  /// The singleton instance of this class
  static final IVirtusizeSDK instance = IVirtusizeSDK._();

  /// The method channel which creates a bridge to communicate between Flutter and Native
  final MethodChannel _channel = const MethodChannel(
    'com.virtusize/flutter_virtusize_sdk',
  );

  /// For caching the i18n localization data and the custom font info
  late VSText vsText;

  /// A stream controller to send the [VSText] data to multiple Virtusize widgets
  late StreamController<VSText> _vsTextController;
  Stream<VSText> get vsTextStream => _vsTextController.stream;

  /// A stream controller to send the [ProductDataCheck] data to multiple Virtusize widgets
  late StreamController<ProductDataCheck> _pdcController;
  Stream<ProductDataCheck> get pdcStream => _pdcController.stream;

  /// A stream controller to send the [VirtusizeServerProduct] data to multiple Virtusize widgets
  late StreamController<VirtusizeServerProduct> _productController;
  Stream<VirtusizeServerProduct> get productStream => _productController.stream;

  /// A stream controller to send the [Recommendation] data to multiple Virtusize widgets
  late StreamController<Recommendation> _recController;
  Stream<Recommendation> get recStream => _recController.stream;

  /// A stream controller to send the [String] data to multiple Virtusize widgets
  late StreamController<String> _productErrorController;
  Stream<String> get productErrorStream => _productErrorController.stream;

  bool? _showPrivacyPolicy = true;
  bool get showPrivacyPolicy => _showPrivacyPolicy ?? true;

  IVirtusizeSDK._();

  /// A function to get the privacy policy link from Native
  Future<String?> getPrivacyPolicyLink() async {
    try {
      return await _channel.invokeMethod(
        FlutterVirtusizeMethod.getPrivacyPolicyLink,
      );
    } on PlatformException catch (error) {
      log(
        'Failed to get the privacy policy link: $error',
        name: virtusizeLogLabel,
      );
      return null;
    }
  }
}
