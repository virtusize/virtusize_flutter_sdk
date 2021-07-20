import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/recommendation.dart';
import '../models/product_data_check.dart';
import '../res/colors.dart';
import '../res/font.dart';
import '../res/images.dart';
import '../res/text.dart';
import '../../virtusize_plugin.dart';
import 'cta_button.dart';
import 'animated_dots.dart';

class VirtusizeInPageMini extends StatefulWidget {
  VirtusizeStyle style = VirtusizeStyle.None;
  Color backgroundColor;
  final double horizontalMargin;

  VirtusizeInPageMini(
      {this.backgroundColor = VSColors.vsGray900, this.horizontalMargin = 16});

  VirtusizeInPageMini.vsStyle(
      {this.style = VirtusizeStyle.Black, this.horizontalMargin = 16});

  @override
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
  StreamSubscription<VSText> _vsTextSubscription;
  StreamSubscription<ProductDataCheck> _pdcSubscription;
  StreamSubscription<Recommendation> _recSubscription;

  VSText _vsText = IVirtusizePlugin.instance.vsText;
  bool _isValidProduct;
  String _externalProductID;
  bool _isLoading;
  bool _hasError;
  String _recText;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription =
        IVirtusizePlugin.instance.vsTextStream.listen((vsLocalization) {
      _vsText = vsLocalization;
      _recText = _vsText.localization.vsLoadingText;
    });

    _pdcSubscription = IVirtusizePlugin.instance.pdcStream.listen((pdc) {
      if(_isValidProduct != null) {
        return;
      }
      IVirtusizePlugin.instance.addProduct(externalProductId: pdc.externalProductId);
      _externalProductID = pdc.externalProductId;
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isValidProduct = pdc.isValidProduct;
      });
    });

    _recSubscription =
        IVirtusizePlugin.instance.recStream.listen((recommendation) {
          if(_externalProductID != recommendation.externalProductID) {
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
    IVirtusizePlugin.instance.removeProduct(externalProductId: _externalProductID);
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    _recSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct == true) {
      return GestureDetector(
        child: _createVSInPageMini(),
        onTap: !_hasError ? _openVirtusizeWebview : () => {},
      );
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.instance.openVirtusizeWebView();
  }

  Widget _createVSInPageMini() {
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
            ? _createVSInPageMiniOnError()
            : _isLoading
                ? _createVSInPageMiniOnLoading()
                : _createVSInPageMiniOnFinishedLoading(themeColor: color));
  }

  Widget _createVSInPageMiniOnLoading() {
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

  Widget _createVSInPageMiniOnFinishedLoading({Color themeColor}) {
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
              textStyle: _vsText.vsFont.getTextStyle(fontSize: VSFontSize.xsmall, fontWeight: FontWeight.bold),
              textColor: themeColor,
              onPressed: _openVirtusizeWebview))
    ]);
  }

  Widget _createVSInPageMiniOnError() {
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
