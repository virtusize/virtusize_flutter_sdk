import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/main.dart';
import 'package:virtusize_flutter_sdk/src/models/product_data_check.dart';
import 'package:virtusize_flutter_sdk/src/models/recommendation.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_colors.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_font.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_images.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_text.dart';
import 'package:virtusize_flutter_sdk/src/widgets/animated_dots.dart';
import 'package:virtusize_flutter_sdk/src/widgets/cta_button.dart';
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

class VirtusizeInPageMini extends StatefulWidget {
  final VirtusizeClientProduct product;
  final VirtusizeStyle style;
  final Color backgroundColor;
  final double horizontalMargin;

  VirtusizeInPageMini({
    required this.product,
    this.backgroundColor = VSColors.vsGray900,
    this.horizontalMargin = 16,
  }) : style = VirtusizeStyle.none,
       super(key: ValueKey('mini_${product.externalProductId}'));

  VirtusizeInPageMini.vsStyle({
    required this.product,
    this.style = VirtusizeStyle.black,
    this.horizontalMargin = 16,
  }) : backgroundColor = VSColors.vsGray900,
       super(key: ValueKey('vs_mini_${product.externalProductId}'));

  @override
  // ignore: library_private_types_in_public_api
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
  late final StreamSubscription<VSText> _vsTextSubscription;
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;
  late final StreamSubscription<Recommendation> _recSubscription;
  late final StreamSubscription<String> _errorSubscription;

  VSText _vsText = IVirtusizeSDK.instance.vsText;
  ProductDataCheck? _productDataCheck;
  bool _isLoading = true;
  bool _hasError = false;
  late String _recText;
  Timer? _productDataCheckTimeout;
  bool _productDataCheckTimedOut = false;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription = IVirtusizeSDK.instance.vsTextStream.listen((
      vsLocalization,
    ) {
      _vsText = vsLocalization;
      _recText = _vsText.localization.vsLoadingText;
    });

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((pdc) {
      if (widget.product.externalProductId != pdc.externalProductId) {
        return;
      }
      _productDataCheckTimeout?.cancel();
      setState(() {
        _isLoading = true;
        _hasError = false;
        _productDataCheck = pdc;
        _productDataCheckTimedOut = false;
      });
    });

    _recSubscription = IVirtusizeSDK.instance.recStream.listen((
      recommendation,
    ) {
      if (_productDataCheck?.externalProductId !=
          recommendation.externalProductID) {
        return;
      }
      setState(() {
        try {
          _recText = recommendation.text.replaceAll("<br>", "");
        } catch (e) {
          _hasError = true;
        }
        _isLoading = false;
      });
    });

    _errorSubscription = IVirtusizeSDK.instance.productErrorStream.listen((
      externalProductId,
    ) {
      if (_productDataCheck?.externalProductId != externalProductId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });

    // Start timeout timer for product data check
    _startProductDataCheckTimeout();
  }

  void _startProductDataCheckTimeout() {
    _productDataCheckTimeout?.cancel();
    _productDataCheckTimedOut = false;

    _productDataCheckTimeout = Timer(Duration(seconds: 10), () {
      if (!mounted) return;
      if (_productDataCheck == null) {
        setState(() {
          _productDataCheckTimedOut = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(VirtusizeInPageMini oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.externalProductId != widget.product.externalProductId) {
      setState(() {
        _productDataCheck = null;
        _isLoading = true;
        _hasError = false;
      });
      _startProductDataCheckTimeout();
    }
  }

  @override
  void dispose() {
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    _recSubscription.cancel();
    _errorSubscription.cancel();
    _productDataCheckTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide if product data check timed out
    if (_productDataCheckTimedOut && _productDataCheck == null) {
      return Container();
    }

    // Show the widget while loading or if the product is valid
    // Hide only if PDC confirms the product is invalid
    if (_productDataCheck == null || _productDataCheck!.isValidProduct) {
      return GestureDetector(
        onTap: !_hasError ? _openVirtusizeWebview : () => {},
        child: _buildVSInPageMini(),
      );
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView(widget.product);
  }

  Widget _buildVSInPageMini() {
    Color color =
        widget.style == VirtusizeStyle.teal
            ? VSColors.vsTeal
            : widget.backgroundColor;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
      color: _isLoading || _hasError ? Colors.white : color,
      width: double.infinity,
      child:
          _hasError
              ? _buildVSInPageMiniOnError()
              : _isLoading
              ? _buildVSInPageMiniOnLoading()
              : _buildVSInPageMiniOnFinishedLoading(color),
    );
  }

  Widget _buildVSInPageMiniOnLoading() {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 16,
            child: Image(
              image: VSImages.vsIcon.image,
              fit: BoxFit.cover,
              color: VSColors.vsGray900,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
          child: Text(
            _vsText.localization.vsLoadingText,
            style: _vsText.vsFont.getTextStyle(
              fontSize: VSFontSize.small,
              fontWeight: FontWeight.bold,
              color: _isLoading ? VSColors.vsGray900 : Colors.white,
            ),
          ),
        ),
        Container(width: 1.0),
        AnimatedDots(),
      ],
    );
  }

  Widget _buildVSInPageMiniOnFinishedLoading(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            margin: EdgeInsets.only(top: 6, bottom: 6, left: 8),
            child: Text(
              _recText,
              style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.small,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 5, bottom: 5, left: 4, right: 8),
          child: CTAButton(
            text: _vsText.localization.vsButtonText,
            textStyle: _vsText.vsFont.getTextStyle(
              fontSize: VSFontSize.xsmall,
              fontWeight: FontWeight.bold,
            ),
            textColor: themeColor,
            onPressed: _openVirtusizeWebview,
          ),
        ),
      ],
    );
  }

  Widget _buildVSInPageMiniOnError() {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 20,
            child: Image(
              image: VSImages.errorHanger.image,
              fit: BoxFit.cover,
              color: VSColors.vsGray700,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
          child: Text(
            _vsText.localization.vsShortErrorText,
            style: _vsText.vsFont.getTextStyle(
              fontSize: VSFontSize.small,
              color: VSColors.vsGray700,
            ),
          ),
        ),
      ],
    );
  }
}
