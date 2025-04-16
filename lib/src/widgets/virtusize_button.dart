import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/main.dart';
import 'package:virtusize_flutter_sdk/src/models/product_data_check.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_colors.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_font.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_images.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_text.dart';
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

class VirtusizeButton extends StatefulWidget {
  final VirtusizeClientProduct product;
  final Widget? child;
  final VirtusizeStyle style;

  const VirtusizeButton({
    super.key,
    required this.product,
    required Widget this.child,
  }) : style = VirtusizeStyle.none;

  const VirtusizeButton.vsStyle({
    super.key,
    required this.product,
    this.style = VirtusizeStyle.black,
    this.child,
  });

  @override
  // ignore: library_private_types_in_public_api
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  late final StreamSubscription<VSText> _vsTextSubscription;
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;

  VSText _vsText = IVirtusizeSDK.instance.vsText;
  bool _isValidProduct = false;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription = IVirtusizeSDK.instance.vsTextStream.listen((vsText) {
      _vsText = vsText;
    });

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((
      productDataCheck,
    ) {
      if (widget.product.externalProductId !=
          productDataCheck.externalProductId) {
        return;
      }
      setState(() {
        _isValidProduct = productDataCheck.isValidProduct;
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
    if (_isValidProduct == true) {
      switch (widget.style) {
        case VirtusizeStyle.none:
          return widget.child!;
        case VirtusizeStyle.black:
          Color color = VSColors.vsGray900;
          return _buildVSButton(color, widget.child);
        case VirtusizeStyle.teal:
          Color color = VSColors.vsTeal;
          return _buildVSButton(color, widget.child);
      }
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView(widget.product);
  }

  ElevatedButton _buildVSButton(Color color, Widget? child) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0)),
        ),
      ),
      onPressed: _openVirtusizeWebview,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Image(image: VSImages.vsIcon.image, fit: BoxFit.cover),
          ),
          Container(width: 4),
          child ??
              Text(
                _vsText.localization.vsButtonText,
                style: _vsText.vsFont.getTextStyle(fontSize: VSFontSize.small),
              ),
        ],
      ),
    );
  }
}
