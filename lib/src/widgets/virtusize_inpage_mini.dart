import 'dart:async';

import 'package:flutter/material.dart';

import '../ui/colors.dart';
import '../ui/images.dart';
import '../../virtusize_plugin.dart';
import 'fading_dots.dart';

class VirtusizeInPageMini extends StatefulWidget {
  VirtusizeStyle style = VirtusizeStyle.None;
  Color backgroundColor;
  final double horizontalMargin;

  VirtusizeInPageMini(
      {this.backgroundColor = VSColor.vsGray900, this.horizontalMargin = 16});

  VirtusizeInPageMini.vsStyle(
      {this.style = VirtusizeStyle.Black, this.horizontalMargin = 16});

  @override
  _VirtusizeInPageMiniState createState() => _VirtusizeInPageMiniState();
}

class _VirtusizeInPageMiniState extends State<VirtusizeInPageMini> {
  StreamSubscription<ProductDataCheck> pdcSubscription;
  StreamSubscription<String> recTextSubscription;
  bool _isValidProduct = false;
  bool _isLoading = true;
  bool _hasError = false;
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
        try {
          _recText = recText
              .replaceAll("%{boldStart}", "")
              .replaceAll("%{boldEnd}", "");
          _hasError = false;
        } catch (e) {
          _hasError = true;
        }
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
        color = VSColor.vsGray900;
        break;
      case VirtusizeStyle.None:
        color = widget.backgroundColor;
        break;
      case VirtusizeStyle.Teal:
        color = VSColor.vsTeal;
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
          child: ImageIcon(VSImages.vsIcon.image, size: 16)),
      Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
        child: Text(_recText,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _isLoading ? VSColor.vsGray900 : Colors.white)),
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
          child: _createVSSizeCheckButton(themeColor: themeColor))
    ]);
  }

  Widget _createVSSizeCheckButton({Color themeColor}) {
    return ElevatedButton(
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('サイズチェック',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Container(width: 1.0),
        ImageIcon(VSImages.rightArrow.image, size: 9, color: themeColor)
      ]),
      style: ElevatedButton.styleFrom(
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          //change background color of button
          primary: Colors.white,
          //change text color of button
          onPrimary: themeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          )),
      onPressed: _openVirtusizeWebview,
    );
  }

  Widget _createVSInPageMiniOnError() {
    return Row(children: [
      Container(
          margin: EdgeInsets.only(left: 6),
          child: ImageIcon(VSImages.errorHanger.image,
              size: 20, color: VSColor.vsGray700)),
      Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: 5),
        child: Text("現在バーチャサイズは使えません。",
            style: TextStyle(fontSize: 12, color: VSColor.vsGray700)),
      )
    ]);
  }
}
