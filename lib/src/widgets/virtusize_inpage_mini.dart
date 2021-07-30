import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/recommendation.dart';
import '../models/product_data_check.dart';
import '../res/vs_colors.dart';
import '../res/vs_font.dart';
import '../res/vs_images.dart';
import '../res/vs_text.dart';
import '../../virtusize_sdk.dart';
import 'cta_button.dart';
import 'animated_dots.dart';

class VirtusizeInPageMini extends StatefulWidget {
  final VirtusizeClientProduct clientProduct;
  VirtusizeStyle style = VirtusizeStyle.None;
  Color backgroundColor;
  final double horizontalMargin;

  VirtusizeInPageMini(
      {@required this.clientProduct, this.backgroundColor = VSColors.vsGray900, this.horizontalMargin = 16});

  VirtusizeInPageMini.vsStyle(
      {@required this.clientProduct, this.style = VirtusizeStyle.Black, this.horizontalMargin = 16});

  @override
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
  StreamSubscription<VSText> _vsTextSubscription;
  StreamSubscription<ProductDataCheck> _pdcSubscription;
  StreamSubscription<Recommendation> _recSubscription;

  VSText _vsText = IVirtusizeSDK.instance.vsText;
  ProductDataCheck _productDataCheck;
  bool _isLoading;
  bool _hasError;
  String _recText;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription =
        IVirtusizeSDK.instance.vsTextStream.listen((vsLocalization) {
      _vsText = vsLocalization;
      _recText = _vsText.localization.vsLoadingText;
    });

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((pdc) {
      if (widget.clientProduct.externalProductId != pdc.externalProductId) {
        return;
      }
      IVirtusizeSDK.instance
          .addProduct(externalProductId: pdc.externalProductId);
      setState(() {
        _isLoading = true;
        _hasError = false;
        _productDataCheck = pdc;
      });
    });

    _recSubscription =
        IVirtusizeSDK.instance.recStream.listen((recommendation) {
      if (_productDataCheck.externalProductId !=
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
  }

  @override
  void dispose() {
    IVirtusizeSDK.instance.removeProduct();
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    _recSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_productDataCheck != null && _productDataCheck.isValidProduct) {
      return GestureDetector(
        child: _buildVSInPageMini(),
        onTap: !_hasError ? _openVirtusizeWebview : () => {},
      );
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView();
  }

  Widget _buildVSInPageMini() {
    Color color;
    switch (widget.style) {
      case VirtusizeStyle.Black:
        color = VSColors.vsGray900;
        break;
      case VirtusizeStyle.None:
        color = widget.backgroundColor;
        break;
      case VirtusizeStyle.Teal:
        color = VSColors.vsTeal;
        break;
    }
    return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
        color: _isLoading || _hasError ? Colors.white : color,
        width: double.infinity,
        child: _hasError
            ? _buildVSInPageMiniOnError()
            : _isLoading
                ? _buildVSInPageMiniOnLoading()
                : _buildVSInPageMiniOnFinishedLoading(themeColor: color));
  }

  Widget _buildVSInPageMiniOnLoading() {
    return Row(children: [
      Container(
          margin: EdgeInsets.only(left: 6),
          child: Container(
            width: 16,
            child: Image(
                image: VSImages.vsIcon.image,
                fit: BoxFit.cover,
                color: VSColors.vsGray900),
          )),
      Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
        child: Text(_vsText.localization.vsLoadingText,
            style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.small,
                fontWeight: FontWeight.bold,
                color: _isLoading ? VSColors.vsGray900 : Colors.white)),
      ),
      Container(width: 1.0),
      AnimatedDots()
    ]);
  }

  Widget _buildVSInPageMiniOnFinishedLoading({Color themeColor}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
          child: Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: 8),
        child: Text(_recText,
            style: _vsText.vsFont
                .getTextStyle(fontSize: VSFontSize.small, color: Colors.white)),
      )),
      Container(
          margin: EdgeInsets.only(top: 5, bottom: 5, left: 4, right: 8),
          child: CTAButton(
              text: _vsText.localization.vsButtonText,
              textStyle: _vsText.vsFont.getTextStyle(
                  fontSize: VSFontSize.xsmall, fontWeight: FontWeight.bold),
              textColor: themeColor,
              onPressed: _openVirtusizeWebview))
    ]);
  }

  Widget _buildVSInPageMiniOnError() {
    return Row(children: [
      Container(
          margin: EdgeInsets.only(left: 6),
          child: Container(
            width: 20,
            child: Image(
                image: VSImages.errorHanger.image,
                fit: BoxFit.cover,
                color: VSColors.vsGray700),
          )),
      Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
        child: Text(_vsText.localization.vsShortErrorText,
            style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.small, color: VSColors.vsGray700)),
      )
    ]);
  }
}
