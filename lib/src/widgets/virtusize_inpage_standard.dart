import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../models/product_data_check.dart';
import '../../virtusize_plugin.dart';
import '../ui/colors.dart';
import '../ui/images.dart';
import 'cta_button.dart';
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
  Image _storeNetworkProductImage;
  Image _userNetworkProductImage;
  String _topRecText;
  String _bottomRecText = "サイズを分析中";

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
      String imageUrl = product.imageUrl ?? "";
      Image networkImage = Image.network(imageUrl);
      final ImageStream stream =
          networkImage.image.resolve(ImageConfiguration.empty);
      stream.addListener(
          ImageStreamListener((ImageInfo image, bool synchronousCall) {
        setState(() {
          if (productType == "store") {
            _storeNetworkProductImage = networkImage;
          } else if (productType == "user") {
            _userNetworkProductImage = networkImage;
          }
        });
      }, onError: (dynamic exception, StackTrace stackTrace) {
        setState(() {
          if (productType == "store") {
            _storeNetworkProductImage = null;
          } else if (productType == "user") {
            _userNetworkProductImage = null;
          }
        });
      }));
    });

    recTextSubscription =
        VirtusizePlugin.instance.recTextStream.listen((recText) {
      setState(() {
        _isLoading = false;
        try {
          _splitRecTexts(recText);
          _hasError = false;
        } catch (e) {
          _hasError = true;
        }
      });
    });
  }

  void _splitRecTexts(String recText) {
    List<String> recTextArray = recText.split("<br>");
    if (recTextArray.length == 2) {
      _topRecText = recTextArray.first;
      _bottomRecText = recTextArray.last;
    } else {
      _topRecText = null;
      _bottomRecText = recTextArray.first;
    }
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

  Future<void> _openPrivacyPolicyLink() async {
    String _url = await VirtusizePlugin.instance.getPrivacyPolicyLink();
    await canLaunch(_url)
        ? await launch(_url, forceSafariVC: false)
        : throw 'Could not launch $_url';
  }

  Widget _createVSInPageStandard() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
        width: double.infinity,
        child: Column(children: [
          _hasError
              ? _createVSInPageStandardOnError()
              : _isLoading
                  ? _createVSInPageStandardOnLoading()
                  : _createVSInPageStandardOnFinishedLoading(),
          !_hasError && !_isLoading ? Container(height: 10) : Container(),
          !_hasError && !_isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Container(
                          height: 11,
                          child: Image(
                              image: VSImages.vsSignature.image,
                              fit: BoxFit.cover)),
                      GestureDetector(
                          child: Text(
                            "プライバシーポリシー",
                            style: TextStyle(fontSize: 10),
                          ),
                          onTap: _openPrivacyPolicyLink)
                    ])
              : Container()
        ]));
  }

  Widget _createVSInPageStandardOnLoading() {
    return Container(child: Text("loading"));
  }

  Widget _createVSInPageStandardOnError() {
    return Container(child: Text("has error"));
  }

  Widget _createVSInPageStandardOnFinishedLoading() {
    return Column(
      children: [
        GestureDetector(
          child: Container(
              child: Card(
                shape: RoundedRectangleBorder(),
                color: Colors.white,
                margin: EdgeInsets.zero,
                elevation: 0,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          children: [
                            Container(width: 78),
                            Positioned(
                                child: ProductImageView(
                                    productImageType: ProductImageType.user,
                                    networkProductImage:
                                        _userNetworkProductImage)),
                            Positioned(
                                left: 38,
                                child: ProductImageView(
                                    productImageType: ProductImageType.store,
                                    networkProductImage:
                                        _storeNetworkProductImage)),
                          ],
                        ),
                        Expanded(
                            child: Container(
                                margin: EdgeInsets.only(left: 4, right: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _topRecText != null
                                        ? Text(_topRecText,
                                            style: TextStyle(fontSize: 12))
                                        : Container(),
                                    Text(_bottomRecText,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold))
                                  ],
                                ))),
                        CTAButton(
                            backgroundColor: VSColors.vsGray900,
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
      ],
    );
  }
}
