import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/widgets/virtusize_widget_event.dart';

import '../../virtusize_flutter_sdk.dart';
import '../main.dart';
import '../models/product_data_check.dart';
import '../models/recommendation.dart';

class VirtusizeWidget extends StatefulWidget {
  final VirtusizeClientProduct product;
  final Container child;
  final ValueChanged<VirtusizeWidgetEvent> onVirtusizeEventChanged;
  VirtusizeWidget({
    required this.product,
    required this.child,
    required this.onVirtusizeEventChanged,
  }) : super(key: ValueKey('button_${product.externalProductId}'));

  @override
  State<StatefulWidget> createState() => _VirtusizeWidgetState();
}

class _VirtusizeWidgetState extends State<VirtusizeWidget> {
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;
  late final StreamSubscription<String> _errorSubscription;
  late final StreamSubscription<Recommendation> _recSubscription;

  bool _isValidProduct = false;
  bool _isAllowedForStore = false;
  Timer? _productDataCheckTimeout;

  @override
  void initState() {
    super.initState();

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((
        productDataCheck,
        ) {
      if (widget.product.externalProductId != productDataCheck.externalProductId) {
        return;
      }
      _productDataCheckTimeout?.cancel();

      setState(() {
        _isValidProduct = productDataCheck.isValidProduct;
        _isAllowedForStore = productDataCheck.isAllowedForStore();
      });

      widget.onVirtusizeEventChanged(LoadingChanged(true));
    });

    _recSubscription = IVirtusizeSDK.instance.recStream.listen((
        recommendation,
        ) {
      if (widget.product.externalProductId !=
          recommendation.externalProductID) {
        return;
      }
      widget.onVirtusizeEventChanged(LoadingChanged(false));
      getRecommendedSize(recommendation.text);
    });

    _errorSubscription = IVirtusizeSDK.instance.productErrorStream.listen((
        externalProductId,
        ) {
      if (widget.product.externalProductId != externalProductId) {
        return;
      }
      widget.onVirtusizeEventChanged(LoadingChanged(false));
      widget.onVirtusizeEventChanged(ErrorOccurred());

    });

    // Start timeout timer for product data check
    _startProductDataCheckTimeout();
  }

  void _startProductDataCheckTimeout() {
    _productDataCheckTimeout?.cancel();

    _productDataCheckTimeout = Timer(Duration(seconds: 10), () {
      if (!mounted) return;
      if (!_isValidProduct) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(VirtusizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.externalProductId != widget.product.externalProductId) {
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
    // Show the view only when the product is confirmed valid
    if (_isValidProduct && _isAllowedForStore) {
      return GestureDetector(
        onTap: _openVirtusizeWebview,
        child: widget.child,
      );
    }
    return Container();
  }

  void getRecommendedSize(String recText) {
    List<String> recTextArray = recText.split("<br>");
    if (recTextArray.length == 2) {
      widget.onVirtusizeEventChanged(RecommendedSizeChanged(recTextArray.first, recTextArray.last));
    } else {
      widget.onVirtusizeEventChanged(RecommendedSizeChanged(recText, ""));
    }
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView(widget.product);
  }
}
