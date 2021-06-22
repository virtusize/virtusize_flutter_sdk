import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_plugin/src/main.dart';

import '../../virtusize_plugin.dart';

class VirtusizeButton extends StatefulWidget  {
  final Widget child;

  VirtusizeButton({this.child});

  @override
  _VirtusizeButtonState createState() => _VirtusizeButtonState();
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  bool _isValidProduct = false;

  Future<void> _startLoading() async {
    print('_startLoading');
    bool isValidProduct = await VirtusizePlugin.getProductDataCheck();
    setState(() {
      _isValidProduct = isValidProduct;
    });
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.openVirtusizeWebView();
  }

  @override
  void initState() {
    super.initState();

    _startLoading();
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidProduct) {
      return GestureDetector(
          child: widget.child,
          onTap: _openVirtusizeWebview
      );
    } else {
      return SizedBox();
    }
  }
}