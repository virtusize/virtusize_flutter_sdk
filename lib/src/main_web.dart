import 'dart:async';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:virtusize_flutter_plugin/src/models/product_data_check.dart';

/// A web implementation of the VirtusizeFlutterPlugin plugin.
class VirtusizeFlutterPluginWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'com.virtusize/virtusize_flutter_plugin',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = VirtusizeFlutterPluginWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  /// Handles method calls over the MethodChannel of this plugin.
  /// Note: Check the "federated" architecture for a new way of doing this:
  /// https://flutter.dev/go/federated-plugins
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'setVirtusizeProps':
        return true;
        break;
      case 'getProductDataCheck':
        return "{\"data\": {\"productDataId\": 7110384, \"userData\": {\"should_see_ph_tooltip\": false}, \"storeId\": 2, \"storeName\": \"virtusize\", \"validProduct\": true, \"productTypeName\": \"pants\", \"fetchMetaData\": false, \"productTypeId\": 5}, \"name\": \"backend-checked-product\", \"productId\": \"694\"}";
      case 'openVirtusizeWebView':
        // open web iframe
        return true;
        case 'getRecommendationText':
        return 'Web Size Recommendation';
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'virtusize_flutter_plugin for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}
