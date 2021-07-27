import 'package:flutter/material.dart';
import '../models/virtusize_product.dart';
import '../res/vs_colors.dart';
import '../res/vs_images.dart';

class ProductImageView extends StatelessWidget {
  final VirtusizeProduct product;

  ProductImageView({@required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            image: product != null && product.imageType == ProductImageType.user
                ? DecorationImage(
                    image: VSImages.circleDashedBorder.image, fit: BoxFit.cover)
                : null,
            border: product != null && product.imageType == ProductImageType.store
                ? Border.all(
                    color: VSColors.vsGray800,
                    width: 0.5,
                  )
                : null,
          )),
      Container(
          width: product != null && product.networkProductImage != null ? 36 : 24,
          height: product != null && product.networkProductImage != null ? 36 : 24,
          decoration: BoxDecoration(
            color: Colors.white,
            image: product != null ? product.networkProductImage != null
                ? DecorationImage(
                    image: product.networkProductImage.image,
                    fit: BoxFit.contain)
                : DecorationImage(
                    image: VSImages.getProductTypeImage(
                            productType: product.productType,
                            style: product.productStyle)
                        .image,
                    colorFilter: ColorFilter.mode(
                        product.imageType == ProductImageType.store
                            ? VSColors.vsGray800
                            : VSColors.vsTeal,
                        BlendMode.srcIn),
                    fit: BoxFit.contain)
            : null,
            borderRadius: product != null && product.networkProductImage != null
                ? BorderRadius.all(Radius.circular(18.0))
                : null,
          )),
    ]);
  }
}
