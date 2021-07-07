import 'package:flutter/material.dart';

import '../models/virtusize_enums.dart';
import '../ui/colors.dart';
import '../ui/images.dart';

class ProductImageView extends StatelessWidget {
  final ProductImageType productImageType;
  final Image networkProductImage;

  ProductImageView({@required this.productImageType, @required this.networkProductImage});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            image: productImageType == ProductImageType.user
                ? DecorationImage(
                    image: VSImages.circleDashedBorder.image, fit: BoxFit.cover)
                : null,
            border: productImageType == ProductImageType.store
                ? Border.all(
                    color: VSColors.vsGray800,
                    width: 0.5,
                  )
                : null,
          )),
      Container(
          width: networkProductImage != null ? 36 : 24,
          height: networkProductImage != null ? 36 : 24,
          decoration: BoxDecoration(
            color: Colors.white,
            image: networkProductImage != null
                ? DecorationImage(image: networkProductImage.image, fit: BoxFit.contain)
                : DecorationImage(
                    image: VSImages.getProuctTypeImage(productType: 1).image,
                    colorFilter: ColorFilter.mode(
                        productImageType == ProductImageType.store
                            ? VSColors.vsGray800
                            : VSColors.vsTeal,
                        BlendMode.srcIn),
                    fit: BoxFit.contain),
            borderRadius: networkProductImage != null
                ? BorderRadius.all(Radius.circular(18.0))
                : null,
          )),
    ]);
  }
}
