import 'dart:async';

import 'package:flutter/material.dart';

import '../../virtusize_flutter_sdk.dart';
import '../main.dart';
import '../models/product_data_check.dart';
import '../models/recommendation.dart';

typedef VirtusizeWidgetBuilder = Widget Function(
  BuildContext context,
  VirtusizeWidgetStatus status,
);

class VirtusizeBuilder extends StatefulWidget {
  final VirtusizeClientProduct product;
  final VirtusizeWidgetBuilder builder;

  VirtusizeBuilder({
    required this.product,
    required this.builder,
  }) : super(key: ValueKey('builder_${product.externalProductId}'));

  @override
  State<StatefulWidget> createState() => _VirtusizeBuilderState();
}

class _VirtusizeBuilderState extends State<VirtusizeBuilder> {
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;
  late final StreamSubscription<String> _errorSubscription;
  late final StreamSubscription<Recommendation> _recSubscription;

  VirtusizeWidgetStatus _status = VirtusizeWidgetWaiting();
  Timer? _productDataCheckTimeout;

  @override
  void initState() {
    super.initState();

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((
      productDataCheck,
    ) {
      if (widget.product.externalProductId !=
          productDataCheck.externalProductId) {
        return;
      }
      _productDataCheckTimeout?.cancel();

      if (!productDataCheck.isValidProduct) {
        setState(() {
          _status = VirtusizeWidgetError(error: 'Invalid product: ${productDataCheck.externalProductId}');
        });
        return;
      }
      if (!productDataCheck.isAllowedForStore()) {
        setState(() {
          _status = VirtusizeWidgetError(error: 'Store not allowed: ${productDataCheck.storeName}');
        });
        return;
      }

      setState(() {
        _status = VirtusizeWidgetLoading();
      });
    });

    _recSubscription = IVirtusizeSDK.instance.recStream.listen((
      recommendation,
    ) {
      if (widget.product.externalProductId !=
          recommendation.externalProductID) {
        return;
      }
      _setDone(recommendation.text);
    });

    _errorSubscription = IVirtusizeSDK.instance.productErrorStream.listen((
      externalProductId,
    ) {
      if (widget.product.externalProductId != externalProductId) {
        return;
      }
      setState(() {
        _status = VirtusizeWidgetError(error: 'Product error: $externalProductId');
      });
    });

    _startProductDataCheckTimeout();
  }

  void _startProductDataCheckTimeout() {
    _productDataCheckTimeout?.cancel();

    _productDataCheckTimeout = Timer(Duration(seconds: 10), () {
      if (!mounted) return;
      if (_status is VirtusizeWidgetWaiting) {
        setState(() {
          _status = VirtusizeWidgetError(error: 'Product data check timed out');
        });
      }
    });
  }

  @override
  void didUpdateWidget(VirtusizeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.externalProductId !=
        widget.product.externalProductId) {
      setState(() {
        _status = VirtusizeWidgetWaiting();
      });
      _startProductDataCheckTimeout();
    }
  }

  @override
  void dispose() {
    _pdcSubscription.cancel();
    _recSubscription.cancel();
    _errorSubscription.cancel();
    _productDataCheckTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _status);
  }

  void _setDone(String recText) {
    final parts = recText.split("<br>");
    setState(() {
      _status = VirtusizeWidgetDone(
        recommendedText: parts.length == 2 ? parts.first : recText,
        recommendedSize: parts.length == 2 ? parts.last : "",
      );
    });
  }
}
