import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_server_product.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_colors.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_images.dart';

enum ProductImageViewType { store, user }

class ProductImageView extends StatelessWidget {
  final VirtusizeServerProduct? product;
  final ProductImageViewType type;

  const ProductImageView({
    super.key,
    this.product,
    this.type = ProductImageViewType.store,
  });

  @override
  Widget build(BuildContext context) {
    final imageContainer = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        image:
            product?.networkProductImage != null
                ? DecorationImage(
                  image: product!.networkProductImage!.image,
                  fit: BoxFit.contain,
                )
                : DecorationImage(
                  image:
                      product != null && type == ProductImageViewType.user
                          ? VSImages.getProductTypeImage(
                            productType: product!.productType,
                            style: product?.productStyle,
                          ).image
                          : VSImages.body.image,
                  colorFilter: ColorFilter.mode(
                    type == ProductImageViewType.store
                        ? VSColors.vsGray800
                        : VSColors.vsTeal,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
        borderRadius: BorderRadius.all(Radius.circular(18.0)),
      ),
    );

    if (type == ProductImageViewType.user) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: Radius.circular(18.0),
            dashPattern: [3, 2],
            color: VSColors.vsTeal,
            strokeWidth: 0.5,
            child: imageContainer,
          ),
        ),
      );
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18.0)),
          border: Border.all(color: VSColors.vsGray800, width: 0.5),
        ),
        child: imageContainer,
      ),
    );
  }
}
