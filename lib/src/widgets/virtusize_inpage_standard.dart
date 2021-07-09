import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product.dart';
import '../models/product_data_check.dart';
import '../../virtusize_plugin.dart';
import '../ui/colors.dart';
import '../ui/images.dart';
import 'animated_dots.dart';
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
  Product _storeProduct;
  Product _userProduct;
  String _topRecText;
  String _bottomRecText;

  @override
  void initState() {
    super.initState();

    pdcSubscription = VirtusizePlugin.instance.pdcStream.listen((pdc) {
      setState(() {
        _productDataCheck = pdc;
      });
    });

    productSubscription =
        VirtusizePlugin.instance.productStream.listen((product) {
      String imageUrl = product.imageUrl ?? "";
      Image networkImage = Image.network(imageUrl);
      final ImageStream stream =
          networkImage.image.resolve(ImageConfiguration.empty);
      stream.addListener(
          ImageStreamListener((ImageInfo image, bool synchronousCall) {
        setState(() {
          if (product.imageType == ProductImageType.store) {
            product.networkProductImage = networkImage;
            _storeProduct = product;
          } else if (product.imageType == ProductImageType.user) {
            product.networkProductImage = networkImage;
            _userProduct = product;
          }
        });
      }, onError: (dynamic exception, StackTrace stackTrace) {
        setState(() {
          if (product.imageType == ProductImageType.store) {
            _storeProduct = product;
          } else if (product.imageType == ProductImageType.user) {
            _userProduct = product;
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
              : _createVSInPageCardView(),
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

  Widget _createVSInPageCardView() {
    return GestureDetector(
      child: Container(
          child: Card(
            shape: RoundedRectangleBorder(),
            color: Colors.white,
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Container(
                padding: EdgeInsets.fromLTRB(_isLoading ? 13 : 8,
                    _isLoading ? 22 : 14, 8, _isLoading ? 22 : 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isLoading
                        ? Image(
                            image: VSImages.vsIcon.image,
                            fit: BoxFit.cover,
                            width: 29,
                            height: 20,
                            color: VSColors.vsGray900)
                        : Stack(
                            children: [
                              Container(width: 78),
                              Positioned(
                                  child:
                                      ProductImageView(product: _userProduct)),
                              Positioned(
                                  left: 38,
                                  child:
                                      ProductImageView(product: _storeProduct)),
                            ],
                          ),
                    Expanded(
                        child: Container(
                            margin: EdgeInsets.only(
                                left: _isLoading ? 9 : 4, right: 8),
                            child: _isLoading
                                ? _buildLoadingText()
                                : _buildRecommendationText())),
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
    );
  }

  Widget _buildLoadingText() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("サイズを分析中",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      AnimatedDots()
    ]);
  }

  Widget _buildRecommendationText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topRecText != null
            ? Text(_topRecText, style: TextStyle(fontSize: 12))
            : Container(),
        Text(_bottomRecText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _createVSInPageStandardOnError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(image: VSImages.errorHanger.image, width: 40, height: 32),
        Container(height: 10),
        Text("現在バーチャサイズは使えませんが、\nそのままでお買い物をお楽しみください。",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: VSColors.vsGray700))
      ],
    );
  }
}
