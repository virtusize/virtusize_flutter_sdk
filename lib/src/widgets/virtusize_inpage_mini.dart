import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:virtusize_flutter_plugin/src/ui/colors.dart';
import 'package:virtusize_flutter_plugin/src/ui/images.dart';

import '../../virtusize_plugin.dart';

class VirtusizeInPageMini extends StatefulWidget {
  VirtusizeStyle style = VirtusizeStyle.None;

  VirtusizeInPageMini({this.style});

  @override
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
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
    if (_isValidProduct) {
      return GestureDetector(
        child: _createVSInPageMini(),
        onTap: _openVirtusizeWebview,
      );
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.instance.openVirtusizeWebView();
  }

  Widget _createVSInPageMini() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0),
        color: Colors.black,
        width: double.infinity,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Container(
                margin: EdgeInsets.only(top: 8, bottom: 8, left: 12),
                child: Text("こちらにメッセージがはいります",
                    style: TextStyle(fontSize: 12, color: Colors.white))),
          ),
          Container(
              margin: EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 10.0),
              child: _createVSSizeCheckButton())
        ]));
  }

  Widget _createVSSizeCheckButton() {
    return ElevatedButton(
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        Text('サイズチェック', style: TextStyle(fontSize: 12)),
        Container(width: 3.0),
        ImageIcon(VSImages.rightArrow.image, size: 12)
      ]),
      style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8.0),
          //change background color of button
          primary: Colors.white,
          //change text color of button
          onPrimary: VSColor.vsGray900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          )),
      onPressed: _openVirtusizeWebview,
    );
  }
}
