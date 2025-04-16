import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_server_product.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_colors.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_images.dart';

class ProductImageView extends StatelessWidget {
  final VirtusizeServerProduct product;

  const ProductImageView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            image:
                product.imageType == ProductImageType.user
                    ? DecorationImage(
                      image: VSImages.circleDashedBorder.image,
                      fit: BoxFit.cover,
                    )
                    : null,
            border:
                product.imageType == ProductImageType.store
                    ? Border.all(color: VSColors.vsGray800, width: 0.5)
                    : null,
          ),
        ),
        Container(
          width: product.networkProductImage != null ? 36 : 24,
          height: product.networkProductImage != null ? 36 : 24,
          decoration: BoxDecoration(
            color: Colors.white,
            image:
                product.networkProductImage != null
                    ? DecorationImage(
                      image: product.networkProductImage!.image,
                      fit: BoxFit.contain,
                    )
                    : DecorationImage(
                      image:
                          VSImages.getProductTypeImage(
                            productType: product.productType,
                            style: product.productStyle,
                          ).image,
                      colorFilter: ColorFilter.mode(
                        product.imageType == ProductImageType.store
                            ? VSColors.vsGray800
                            : VSColors.vsTeal,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.contain,
                    ),
            borderRadius:
                product.networkProductImage != null
                    ? BorderRadius.all(Radius.circular(18.0))
                    : null,
          ),
        ),
      ],
    );
  }
}
