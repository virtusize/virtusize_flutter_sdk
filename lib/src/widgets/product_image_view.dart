import 'package:flutter/material.dart';

import '../models/virtusize_enums.dart';
import '../ui/colors.dart';
import '../ui/images.dart';

class ProductImageView extends StatelessWidget {
  final ProductImageType productImageType;
  final String src;

  ProductImageView({@required this.productImageType, @required this.src});

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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            image: src != null
                ? DecorationImage(image: NetworkImage(src), fit: BoxFit.cover)
                : null,
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          )),
    ]);
  }
}
