import 'dart:async';

import 'package:flutter/material.dart';

import '../../virtusize_flutter_sdk.dart';
import '../main.dart';
import '../models/product_data_check.dart';
import '../models/recommendation.dart';

class VirtusizeWidgetBuilder extends StatefulWidget {
  final VirtusizeClientProduct product;

  final Widget Function(BuildContext context, VirtusizeWidgetState) builder;

  VirtusizeWidgetBuilder({required this.product, required this.builder})
    : super(key: ValueKey('button_${product.externalProductId}'));

  @override
  State<StatefulWidget> createState() => _VirtusizeWidgetBuilderState();
}

class _VirtusizeWidgetBuilderState extends State<VirtusizeWidgetBuilder> {
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;
  late final StreamSubscription<String> _errorSubscription;
  late final StreamSubscription<Recommendation> _recSubscription;

  bool _isValidProduct = false;
  bool _isAllowedForStore = false;
  Timer? _productDataCheckTimeout;

  VirtusizeWidgetState _eventState = VirtusizeWidgetLoading();

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

      setState(() {
        _eventState = VirtusizeWidgetLoading();

        _isValidProduct = productDataCheck.isValidProduct;
        _isAllowedForStore = productDataCheck.isAllowedForStore();

        if (!_isValidProduct) {
          _eventState = VirtusizeWidgetError(
            error: 'Invalid product: ${productDataCheck.externalProductId}',
          );
        }
      });
    });

    _recSubscription = IVirtusizeSDK.instance.recStream.listen((
      recommendation,
    ) {
      if (widget.product.externalProductId !=
          recommendation.externalProductID) {
        return;
      }
      onVirtusizeWidgetCompleted(recommendation.text);
    });

    _errorSubscription = IVirtusizeSDK.instance.productErrorStream.listen((
      externalProductId,
    ) {
      if (widget.product.externalProductId != externalProductId) {
        return;
      }

      setState(() {
        _eventState = VirtusizeWidgetError(
          error: 'Product error: $externalProductId',
        );
      });
    });

    // Start timeout timer for product data check
    _startProductDataCheckTimeout();
  }

  void _startProductDataCheckTimeout() {
    _productDataCheckTimeout?.cancel();

    _productDataCheckTimeout = Timer(Duration(seconds: 10), () {
      if (!mounted) return;
      if (_eventState is VirtusizeWidgetLoading) {
        setState(() {
          _eventState = VirtusizeWidgetError(
            error: 'Product data check timed out',
          );
        });
      }
    });
  }

  @override
  void didUpdateWidget(VirtusizeWidgetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.externalProductId !=
        widget.product.externalProductId) {
      setState(() {
        _isValidProduct = false;
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
    switch (_eventState) {
      case VirtusizeWidgetCompleted():
        {
          //Return empty container if store is not allowed to use this widget class
          if (!_isAllowedForStore) {
            return Container();
          }

          return GestureDetector(
            onTap: _openVirtusizeWebview,
            child: widget.builder(context, _eventState),
          );
        }
      default:
        return widget.builder(context, _eventState);
    }
  }

  void onVirtusizeWidgetCompleted(String recText) {
    List<String> recTextArray = recText.split("<br>");
    setState(() {
      if (recTextArray.length == 2) {
        _eventState = VirtusizeWidgetCompleted(
          recommendedText: recTextArray.first,
          recommendedSize: recTextArray.last,
        );
      } else {
        _eventState = VirtusizeWidgetCompleted(
          recommendedText: recText,
          recommendedSize: '',
        );
      }
    });
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView(widget.product);
  }
}
