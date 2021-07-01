import 'dart:async';

import 'package:flutter/material.dart';
import 'package:virtusize_flutter_plugin/src/ui/colors.dart';
import 'package:virtusize_flutter_plugin/src/ui/images.dart';

import '../../virtusize_plugin.dart';
import 'fading_dots.dart';

class VirtusizeInPageMini extends StatefulWidget {
  final VirtusizeStyle style;

  VirtusizeInPageMini({this.style = VirtusizeStyle.None});

  @override
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
  StreamSubscription<ProductDataCheck> pdcSubscription;
  StreamSubscription<String> recTextSubscription;
  bool _isValidProduct = false;
  bool _isLoading = true;
  String _recText = "読み込み中";

  @override
  void initState() {
    super.initState();

    pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((pdc) {
      setState(() {
        _isValidProduct = pdc.isValidProduct;
      });
    });

    recTextSubscription =
        VirtusizePlugin.instance.recTextStream.listen((recText) {
      setState(() {
        _isLoading = false;
        _recText =
            recText.replaceAll("%{boldStart}", "").replaceAll("%{boldEnd}", "");
      });
    });
  }

  @override
  void dispose() {
    pdcSubscription.cancel();
    recTextSubscription.cancel();
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
        color: _isLoading ? Colors.white : VSColor.vsGray900,
        width: double.infinity,
        child: _isLoading
            ? Row(children: [
                Container(
                    margin: EdgeInsets.only(left: 6),
                    child: ImageIcon(VSImages.vsIcon.image, size: 16)),
                Container(
                  margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
                  child: Text(_recText,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color:
                              _isLoading ? VSColor.vsGray900 : Colors.white)),
                ),
                Container(width: 1.0),
                AnimatedDots()
              ])
            : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Container(
                  margin: EdgeInsets.only(top: 6, bottom: 6, left: 8),
                  child: Text(_recText,
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                )),
                Container(
                    margin:
                        EdgeInsets.only(top: 5, bottom: 5, left: 4, right: 8),
                    child: _createVSSizeCheckButton())
              ]));
  }

  Widget _createVSSizeCheckButton() {
    return ElevatedButton(
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('サイズチェック',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Container(width: 1.0),
        ImageIcon(VSImages.rightArrow.image, size: 9)
      ]),
      style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
