import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_plugin/src/main.dart';
import 'package:virtusize_flutter_plugin/src/ui/images.dart';

import '../../virtusize_plugin.dart';
import 'colors.dart';

class VirtusizeButton extends StatefulWidget {
  final Widget child;
  VirtusizeStyle style = VirtusizeStyle.None;

  VirtusizeButton({@required this.child});

  VirtusizeButton.vsStyle({this.style = VirtusizeStyle.Black, this.child});

  @override
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  bool _isValidProduct = false;

  Future<void> _startLoading() async {
    bool isValidProduct = await VirtusizePlugin.getProductDataCheck();
    setState(() {
      _isValidProduct = isValidProduct;
    });
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.openVirtusizeWebView();
  }

  ElevatedButton _createVSButton(Color color, Widget child) {
    return ElevatedButton.icon(
      label: child != null ? child : Text('サイズチェック'),
      icon: VSImages.vsIcon,
      style: ElevatedButton.styleFrom(
          primary: color,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0)))),
      onPressed: _openVirtusizeWebview,
    );
  }

  @override
  void initState() {
    super.initState();

    _startLoading();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct) {
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
    } else {
      return SizedBox();
    }
  }
}
