import 'dart:async';

import 'package:flutter/material.dart';

import '../models/recommendation.dart';
import '../models/product_data_check.dart';
import '../resources/colors.dart';
import '../resources/images.dart';
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
  StreamSubscription<ProductDataCheck> _pdcSubscription;
  StreamSubscription<Recommendation> _recSubscription;
  bool _isValidProduct = false;
  bool _isLoading;
  bool _hasError;
  String _recText = "サイズを分析中";

  @override
  void initState() {
    super.initState();

    _pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((pdc) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isValidProduct = pdc.isValidProduct;
      });
    });

    _recSubscription =
        VirtusizePlugin.instance.recStream.listen((recommendation) {
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
    _pdcSubscription.cancel();
    _recSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct) {
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
        child: Text(_recText,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
        child:
            Text(_recText, style: TextStyle(fontSize: 12, color: Colors.white)),
      )),
      Container(
          margin: EdgeInsets.only(top: 5, bottom: 5, left: 4, right: 8),
          child: CTAButton(
              textColor: themeColor, onPressed: _openVirtusizeWebview))
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
        child: Text("現在バーチャサイズは使えません。",
            style: TextStyle(fontSize: 12, color: VSColors.vsGray700)),
      )
    ]);
  }
}
