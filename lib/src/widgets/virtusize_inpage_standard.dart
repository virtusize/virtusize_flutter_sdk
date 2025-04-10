import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:virtusize_flutter_sdk/src/utils/virtusize_product_image_loader.dart';

import '../main.dart';
import '../models/recommendation.dart';
import '../models/virtusize_server_product.dart';
import '../models/product_data_check.dart';
import '../res/vs_colors.dart';
import '../res/vs_font.dart';
import '../res/vs_images.dart';
import '../res/vs_text.dart';
import '../../virtusize_flutter_sdk.dart';
import 'animated_dots.dart';
import 'animated_product_images.dart';
import 'cta_button.dart';
import 'product_image_view.dart';

class VirtusizeInPageStandard extends StatefulWidget {
  final VirtusizeClientProduct product;
  final VirtusizeStyle style;
  final Color buttonBackgroundColor;
  final double horizontalMargin;

  const VirtusizeInPageStandard({
    super.key,
    required this.product,
    this.buttonBackgroundColor = VSColors.vsGray900,
    this.horizontalMargin = 16,
  }) : style = VirtusizeStyle.None;

  const VirtusizeInPageStandard.vsStyle({
    super.key,
    required this.product,
    this.style = VirtusizeStyle.Black,
    this.horizontalMargin = 16,
  }) : buttonBackgroundColor = VSColors.vsGray900;

  @override
  // ignore: library_private_types_in_public_api
  _VirtusizeInPageStandardState createState() =>
      _VirtusizeInPageStandardState();
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  late final StreamSubscription<VSText> _vsTextSubscription;
  late final StreamSubscription<ProductDataCheck> _pdcSubscription;
  late final StreamSubscription<Recommendation> _recSubscription;
  late final StreamSubscription<VirtusizeServerProduct> _productSubscription;
  late final StreamSubscription<String> _errorSubscription;

  VSText _vsText = IVirtusizeSDK.instance.vsText;
  ProductDataCheck? _productDataCheck;
  bool _hasError = false;
  bool _isLoading = true;
  bool _showUserProductImage = false;
  VirtusizeServerProduct? _storeProduct;
  VirtusizeServerProduct? _userProduct;
  String? _topRecText;
  String? _bottomRecText;

  @override
  void initState() {
    super.initState();

    _vsTextSubscription = IVirtusizeSDK.instance.vsTextStream.listen((vsText) {
      _vsText = vsText;
    });

    _pdcSubscription = IVirtusizeSDK.instance.pdcStream.listen((pdc) {
      if (widget.product.externalProductId != pdc.externalProductId) {
        return;
      }
      setState(() {
        _isLoading = true;
        _hasError = false;
        _productDataCheck = pdc;
      });
    });

    _productSubscription = IVirtusizeSDK.instance.productStream.listen((
      product,
    ) {
      if (_productDataCheck?.externalProductId != product.externalProductId ||
          (!compareProduct(
                widgetProduct: _storeProduct,
                serverProduct: product,
              ) &&
              !compareProduct(
                widgetProduct: _userProduct,
                serverProduct: product,
              ))) {
        return;
      }

      downloadProductImage(product).then((_) {
        if (!mounted) return;
        setState(() {
          product.imageType == ProductImageType.store
              ? _storeProduct = product
              : _userProduct = product;
        });
      });
    });

    _recSubscription = IVirtusizeSDK.instance.recStream.listen((
      recommendation,
    ) {
      if (_productDataCheck?.externalProductId !=
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

    _errorSubscription = IVirtusizeSDK.instance.productErrorStream.listen((
      externalProductId,
    ) {
      if (_productDataCheck?.externalProductId != externalProductId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    });
  }

  bool compareProduct({
    required VirtusizeServerProduct? widgetProduct,
    required VirtusizeServerProduct serverProduct,
  }) {
    return widgetProduct == null ||
        widgetProduct.imageType == serverProduct.imageType;
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
    _vsTextSubscription.cancel();
    _pdcSubscription.cancel();
    _productSubscription.cancel();
    _recSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _productDataCheck?.isValidProduct == true
        ? _buildVSInPageStandard(context)
        : SizedBox.shrink();
  }

  Future<void> _openVirtusizeWebview() async {
    await VirtusizeSDK.instance.openVirtusizeWebView(widget.product);
  }

  Future<void> _openPrivacyPolicyLink() async {
    final link = await IVirtusizeSDK.instance.getPrivacyPolicyLink() ?? '';
    final url = Uri.tryParse(link);
    if (url == null) throw 'Could not launch, url is null';

    await canLaunchUrl(url)
        ? await launchUrl(url)
        : throw 'Could not launch $url';
  }

  Widget _buildVSInPageStandard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.horizontalMargin),
      width: double.infinity,
      child: Column(
        children: [
          _hasError
              ? _buildVSInPageStandardOnError()
              : _buildVSInPageCardView(context),
          !_hasError && !_isLoading ? Container(height: 10) : Container(),
          !_hasError && !_isLoading
              ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 11,
                    child: Image(
                      image: VSImages.vsSignature.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openPrivacyPolicyLink,
                    child: Text(
                      _vsText.localization.vsPrivacyPolicy,
                      style: _vsText.vsFont.getTextStyle(
                        fontSize: VSFontSize.xsmall,
                      ),
                    ),
                  ),
                ],
              )
              : Container(),
        ],
      ),
    );
  }

  Widget _buildVSInPageCardView(BuildContext context) {
    double _inPageCardWidth =
        MediaQuery.of(context).size.width - widget.horizontalMargin * 2;
    bool overlayImages = _inPageCardWidth <= 411;

    final color =
        widget.style == VirtusizeStyle.Teal
            ? VSColors.vsTeal
            : widget.buttonBackgroundColor;

    return GestureDetector(
      onTap: _openVirtusizeWebview,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 14,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          shape: RoundedRectangleBorder(),
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              _isLoading ? 13 : 8,
              _isLoading ? 22 : 14,
              8,
              _isLoading ? 22 : 14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isLoading
                    ? Image(
                      image: VSImages.vsIcon.image,
                      fit: BoxFit.cover,
                      width: 29,
                      height: 20,
                      color: VSColors.vsGray900,
                    )
                    : _showUserProductImage
                    ? overlayImages
                        ? AnimatedProductImages(
                          userProductImageView:
                              _userProduct != null
                                  ? ProductImageView(product: _userProduct!)
                                  : null,
                          storeProductImageView:
                              _storeProduct != null
                                  ? ProductImageView(product: _storeProduct!)
                                  : null,
                        )
                        : Stack(
                          children: [
                            Container(width: 78),
                            if (_userProduct != null)
                              Positioned(
                                child: ProductImageView(product: _userProduct!),
                              ),
                            if (_storeProduct != null)
                              Positioned(
                                left: 38,
                                child: ProductImageView(
                                  product: _storeProduct!,
                                ),
                              ),
                          ],
                        )
                    : _storeProduct != null
                    ? ProductImageView(product: _storeProduct!)
                    : SizedBox.shrink(),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: _isLoading ? 9 : 4, right: 8),
                    child:
                        _isLoading
                            ? _buildLoadingText()
                            : _buildRecommendationText(),
                  ),
                ),
                CTAButton(
                  text: _vsText.localization.vsButtonText,
                  textStyle: _vsText.vsFont.getTextStyle(
                    fontSize: VSFontSize.xsmall,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: color,
                  textColor: Colors.white,
                  onPressed: _openVirtusizeWebview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingText() {
    return Wrap(
      children: [
        Text(
          _vsText.localization.vsLoadingText,
          style: _vsText.vsFont.getTextStyle(
            fontSize: VSFontSize.large,
            fontWeight: FontWeight.bold,
          ),
        ),
        AnimatedDots(),
      ],
    );
  }

  Widget _buildRecommendationText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topRecText != null
            ? Text(
              _topRecText!,
              style: _vsText.vsFont.getTextStyle(fontSize: VSFontSize.small),
            )
            : SizedBox.shrink(),
        _bottomRecText != null
            ? Text(
              _bottomRecText!,
              style: _vsText.vsFont.getTextStyle(
                fontSize: VSFontSize.large,
                fontWeight: FontWeight.bold,
              ),
            )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _buildVSInPageStandardOnError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image(image: VSImages.errorHanger.image, width: 40, height: 32),
        Container(height: 10),
        Text(
          _vsText.localization.vsLongErrorText,
          textAlign: TextAlign.center,
          style: _vsText.vsFont.getTextStyle(
            fontSize: VSFontSize.small,
            color: VSColors.vsGray700,
          ),
        ),
      ],
    );
  }
}
