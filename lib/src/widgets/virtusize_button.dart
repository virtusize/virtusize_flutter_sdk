import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/product_data_check.dart';
import '../res/vs_colors.dart';
import '../res/vs_font.dart';
import '../res/vs_images.dart';
import '../res/vs_text.dart';
import '../../virtusize_sdk.dart';

class VirtusizeButton extends StatefulWidget {
  final VirtusizeClientProduct clientProduct;
  final Widget child;
  VirtusizeStyle style = VirtusizeStyle.None;

  VirtusizeButton({@required this.clientProduct, @required this.child}) {
    assert(clientProduct != null);
  }

  VirtusizeButton.vsStyle({@required this.clientProduct, this.style = VirtusizeStyle.Black, this.child})  {
    assert(clientProduct != null);
  }

  @override
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  StreamSubscription<VSText> _vsTextSubscription;
  StreamSubscription<ProductDataCheck> _pdcSubscription;

  VSText _vsText = IVirtusizeSDK.instance.vsText;
  bool _isValidProduct;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription =
        IVirtusizeSDK.instance.vsTextStream.listen((vsText) {
      _vsText = vsText;
    });

    _pdcSubscription =
        IVirtusizeSDK.instance.pdcStream.listen((productDataCheck) {
      if (widget.clientProduct.externalProductId != productDataCheck.externalProductId) {
        return;
      }
      IVirtusizeSDK.instance
          .addProduct(externalProductId: productDataCheck.externalProductId);
      setState(() {
        _isValidProduct = productDataCheck.isValidProduct;
      });
    });
  }

  @override
  void dispose() {
    IVirtusizeSDK.instance.removeProduct();
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct == true) {
      switch (widget.style) {
        case VirtusizeStyle.None:
          return widget.child;
          break;
        case VirtusizeStyle.Black:
          Color color = VSColors.vsGray900;
          return _buildVSButton(color, widget.child);
          break;
        case VirtusizeStyle.Teal:
          Color color = VSColors.vsTeal;
          return _buildVSButton(color, widget.child);
          break;
      }
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView();
  }

  ElevatedButton _buildVSButton(Color color, Widget child) {
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
              : Text(_vsText.localization.vsButtonText,
                  style:
                      _vsText.vsFont.getTextStyle(fontSize: VSFontSize.small))
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
