import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/product_data_check.dart';
import '../resources/font.dart';
import '../resources/images.dart';
import '../resources/text.dart';
import '../../virtusize_plugin.dart';
import '../resources/colors.dart';

class VirtusizeButton extends StatefulWidget {
  final Widget child;
  VirtusizeStyle style = VirtusizeStyle.None;

  VirtusizeButton({@required this.child});

  VirtusizeButton.vsStyle({this.style = VirtusizeStyle.Black, this.child});

  @override
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  StreamSubscription<VSText> _vsTextSubscription;
  StreamSubscription<ProductDataCheck> _pdcSubscription;

  VSText _vsText;
  bool _isValidProduct = false;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription = VirtusizePlugin.instance.vsTextStream.listen((vsText) {
      _vsText = vsText;
    });

    _pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((value) {
      setState(() {
        _isValidProduct = value.isValidProduct;
      });
    });
  }

  @override
  void dispose() {
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct) {
      switch (widget.style) {
        case VirtusizeStyle.None:
          return widget.child;
          break;
        case VirtusizeStyle.Black:
          Color color = VSColors.vsGray900;
          return _createVSButton(color, widget.child);
          break;
        case VirtusizeStyle.Teal:
          Color color = VSColors.vsTeal;
          return _createVSButton(color, widget.child);
          break;
      }
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.instance.openVirtusizeWebView();
  }

  ElevatedButton _createVSButton(Color color, Widget child) {
    return ElevatedButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            child: Image(image: VSImages.vsIcon.image, fit: BoxFit.cover),
          ),
          Container(width: 4),
          child != null
              ? child
              : Text(_vsText.localization.vsButtonText, style: _vsText.vsFont.getTextStyle(fontSize: VSFontSize.small))
        ],
      ),
      style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          primary: color,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0)))),
      onPressed: _openVirtusizeWebview,
    );
  }
}
