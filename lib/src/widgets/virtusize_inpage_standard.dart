import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_plugin/src/ui/colors.dart';
import 'package:virtusize_flutter_plugin/src/ui/images.dart';
import 'package:virtusize_flutter_plugin/src/widgets/cta_button.dart';

import '../models/product.dart';
import '../../virtusize_plugin.dart';
import 'product_image_view.dart';

class VirtusizeInPageStandard extends StatefulWidget {
  final VirtusizeStyle virtusizeStyle;
  final Color buttonBackgroundColor;
  final double horizontalMargin;

  VirtusizeInPageStandard(
      {Key key,
      this.virtusizeStyle,
      this.buttonBackgroundColor,
      this.horizontalMargin = 16.0})
      : super(key: key);

  @override
  _VirtusizeInPageStandardState createState() =>
      _VirtusizeInPageStandardState();
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  StreamSubscription<ProductDataCheck> pdcSubscription;
  StreamSubscription<String> recTextSubscription;
  StreamSubscription<Product> productSubscription;
  ProductDataCheck _productDataCheck;
  bool _hasError = false;
  bool _isLoading = true;
  String _storeImageUrl;
  String _userImageUrl;
  String _recText = "読み込み中";

  @override
  void initState() {
    super.initState();

    pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((pdc) {
      setState(() {
        _productDataCheck = pdc;
      });
    });

    productSubscription =
        VirtusizePlugin.instance.productImageUrlStream.listen((product) {
      String productType = product.imageType;
      String imageUrl = product.imageUrl;
      setState(() {
        if (productType == "store") {
          _storeImageUrl = imageUrl;
        } else if (productType == "user") {
          _userImageUrl = imageUrl;
        }
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
    productSubscription.cancel();
    recTextSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_productDataCheck != null && _productDataCheck.isValidProduct) {
      return _createVSInPageStandard();
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.instance.openVirtusizeWebView();
  }

  Widget _createVSInPageStandard() {
    return _hasError
        ? _createVSInPageStandardOnError()
        : _isLoading
            ? _createVSInPageStandardOnLoading()
            : _createVSInPageStandardOnFinishedLoading();
  }

  Widget _createVSInPageStandardOnLoading() {
    return Container();
  }

  Widget _createVSInPageStandardOnError() {
    return Container();
  }

  Widget _createVSInPageStandardOnFinishedLoading() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
        width: double.infinity,
        child: Column(
          children: [
            GestureDetector(
              child: Container(
                  child: Card(
                    shape: RoundedRectangleBorder(),
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    elevation: 4,
                    child: Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Stack(
                              children: [
                                Container(width: 78),
                                Positioned(
                                    child: ProductImageView(src: _userImageUrl)),
                                Positioned(
                                    left: 38,
                                    child: ProductImageView(src: _storeImageUrl)),
                              ],
                            ),
                            Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(left: 4, right: 8),
                                    child: Text(_recText,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)))),
                            CTAButton(
                                backgroundColor: VSColor.vsGray900,
                                textColor: Colors.white,
                                onPressed: _openVirtusizeWebview)
                          ],
                        )),
                  ),
                  decoration: new BoxDecoration(
                    boxShadow: [
                      new BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  )),
              onTap: _openVirtusizeWebview,
            ),
            Container(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                  height: 11,
                  child: Image(
                      image: VSImages.vsSignature.image, fit: BoxFit.cover)),
              Text(
                "プライバシーポリシー",
                style: TextStyle(fontSize: 10),
              )
            ])
          ],
        ));
  }
}
