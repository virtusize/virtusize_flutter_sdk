import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:virtusize_flutter_plugin/src/main.dart';

import '../models/recommendation.dart';
import '../models/virtusize_product.dart';
import '../models/product_data_check.dart';
import '../res/colors.dart';
import '../res/font.dart';
import '../res/images.dart';
import '../res/text.dart';
import '../../virtusize_plugin.dart';
import 'animated_dots.dart';
import 'animated_product_images.dart';
import 'cta_button.dart';
import 'product_image_view.dart';

class VirtusizeInPageStandard extends StatefulWidget {
  VirtusizeStyle style = VirtusizeStyle.None;
  Color buttonBackgroundColor;
  final double horizontalMargin;

  VirtusizeInPageStandard(
      {this.buttonBackgroundColor = VSColors.vsGray900,
      this.horizontalMargin = 16});

  VirtusizeInPageStandard.vsStyle(
      {this.style = VirtusizeStyle.Black, this.horizontalMargin = 16});

  @override
  _VirtusizeInPageStandardState createState() =>
      _VirtusizeInPageStandardState();
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  StreamSubscription<VSText> _vsTextSubscription;
  StreamSubscription<ProductDataCheck> _pdcSubscription;
  StreamSubscription<Recommendation> _recSubscription;
  StreamSubscription<VirtusizeProduct> _productSubscription;

  VSText _vsText = IVirtusizePlugin.instance.vsText;
  ProductDataCheck _productDataCheck;
  bool _hasError;
  bool _isLoading;
  bool _showUserProductImage = false;
  VirtusizeProduct _storeProduct;
  VirtusizeProduct _userProduct;
  String _topRecText;
  String _bottomRecText;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription =
        IVirtusizePlugin.instance.vsTextStream.listen((vsText) {
      _vsText = vsText;
    });

    _pdcSubscription = IVirtusizePlugin.instance.pdcStream.listen((pdc) {
      if (_productDataCheck != null) {
        return;
      }
      IVirtusizePlugin.instance
          .addProduct(externalProductId: pdc.externalProductId);
      setState(() {
        _isLoading = true;
        _hasError = false;
        _productDataCheck = pdc;
      });
    });

    _productSubscription =
        IVirtusizePlugin.instance.productStream.listen((product) {
      if (_productDataCheck.productId != product.storeProductID || (
          !isTheSameProduct(_storeProduct, product) &&
          !isTheSameProduct(_userProduct, product))) {
        return;
      }
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

    _recSubscription =
        IVirtusizePlugin.instance.recStream.listen((recommendation) {
      if (_productDataCheck.externalProductId !=
          recommendation.externalProductID) {
        return;
      }
      setState(() {
        _showUserProductImage = recommendation.showUserProductImage;
        try {
          _splitRecTexts(recommendation.text);
        } catch (e) {
          _hasError = true;
        }
        _isLoading = false;
      });
    });
  }

  bool isTheSameProduct(VirtusizeProduct productA, VirtusizeProduct productB) {
    return productA == null ||
        (productA != null && productA.imageType == productB.imageType);
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
    IVirtusizePlugin.instance
        .removeProduct(externalProductId: _productDataCheck.externalProductId);
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    _productSubscription.cancel();
    _recSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_productDataCheck != null && _productDataCheck.isValidProduct) {
      return _createVSInPageStandard(context);
    }
    return Container();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizePlugin.instance.openVirtusizeWebView();
  }

  Future<void> _openPrivacyPolicyLink() async {
    String _url = await IVirtusizePlugin.instance.getPrivacyPolicyLink();
    await canLaunch(_url)
        ? await launch(_url, forceSafariVC: false)
        : throw 'Could not launch $_url';
  }

  Widget _createVSInPageStandard(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
        width: double.infinity,
        child: Column(children: [
          _hasError
              ? _createVSInPageStandardOnError()
              : _createVSInPageCardView(context),
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
                            _vsText.localization.vsPrivacyPolicy,
                            style: _vsText.vsFont
                                .getTextStyle(fontSize: VSFontSize.xsmall),
                          ),
                          onTap: _openPrivacyPolicyLink)
                    ])
              : Container()
        ]));
  }

  Widget _createVSInPageCardView(BuildContext context) {
    double _inpageCardWidth =
        MediaQuery.of(context).size.width - widget.horizontalMargin * 2;
    bool overlayImages = _inpageCardWidth <= 411;

    Color color;
    switch (widget.style) {
      case VirtusizeStyle.Black:
        color = VSColors.vsGray900;
        break;
      case VirtusizeStyle.None:
        color = widget.buttonBackgroundColor;
        break;
      case VirtusizeStyle.Teal:
        color = VSColors.vsTeal;
        break;
    }

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
                        : _showUserProductImage
                            ? overlayImages
                                ? AnimatedProductImages(
                                    userProductImageView:
                                        ProductImageView(product: _userProduct),
                                    storeProductImageView: ProductImageView(
                                        product: _storeProduct))
                                : Stack(
                                    children: [
                                      Container(width: 78),
                                      Positioned(
                                          child: ProductImageView(
                                              product: _userProduct)),
                                      Positioned(
                                          left: 38,
                                          child: ProductImageView(
                                              product: _storeProduct)),
                                    ],
                                  )
                            : ProductImageView(product: _storeProduct),
                    Expanded(
                        child: Container(
                            margin: EdgeInsets.only(
                                left: _isLoading ? 9 : 4, right: 8),
                            child: _isLoading
                                ? _buildLoadingText()
                                : _buildRecommendationText())),
                    CTAButton(
                        text: _vsText.localization.vsButtonText,
                        textStyle: _vsText.vsFont.getTextStyle(
                            fontSize: VSFontSize.xsmall,
                            fontWeight: FontWeight.bold),
                        backgroundColor: color,
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
    return Wrap(children: [
      Text(_vsText.localization.vsLoadingText,
          style: _vsText.vsFont.getTextStyle(
              fontSize: VSFontSize.large, fontWeight: FontWeight.bold)),
      AnimatedDots()
    ]);
  }

  Widget _buildRecommendationText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topRecText != null
            ? Text(_topRecText,
                style: _vsText.vsFont.getTextStyle(fontSize: VSFontSize.small))
            : Container(),
        Text(_bottomRecText,
            style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.large, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _createVSInPageStandardOnError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(image: VSImages.errorHanger.image, width: 40, height: 32),
        Container(height: 10),
        Text(_vsText.localization.vsLongErrorText,
            textAlign: TextAlign.center,
            style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.small, color: VSColors.vsGray700))
      ],
    );
  }
}
