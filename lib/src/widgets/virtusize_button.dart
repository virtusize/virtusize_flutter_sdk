import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_plugin/src/main.dart';
import 'package:virtusize_flutter_plugin/src/models/product_data_check.dart';
import 'package:virtusize_flutter_plugin/src/ui/images.dart';

import '../../virtusize_plugin.dart';
import '../ui/colors.dart';

class VirtusizeButton extends StatefulWidget {
  final Widget child;
  VirtusizeStyle style = VirtusizeStyle.None;

  VirtusizeButton({@required this.child});

  VirtusizeButton.vsStyle({this.style = VirtusizeStyle.Black, this.child});

  @override
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  StreamSubscription<ProductDataCheck> pdcSubscription;
  bool _isValidProduct = false;

  @override
  void initState() {
    super.initState();

    pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((value) {
      setState(() {
        _isValidProduct = value.isValidProduct;
      });
    });
  }

  @override
  void dispose() {
    pdcSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_isValidProduct) {
      switch (widget.style) {
        case VirtusizeStyle.None:
          return widget.child;
          break;
        case VirtusizeStyle.Black:
          Color color = VSColor.vsGray900;
          return _createVSButton(color, widget.child);
          break;
        case VirtusizeStyle.Teal:
          Color color = VSColor.vsTeal;
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
          ImageIcon(VSImages.vsIcon.image, size: 20),
          Container(width: 4),
          child != null ? child : Text('サイズチェック', style: TextStyle(fontSize: 12))
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
