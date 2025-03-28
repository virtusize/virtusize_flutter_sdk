import 'package:flutter/material.dart';

/// The Virtusize images
class VSImages {
  static Image vsIcon = Image.asset(
    'assets/images/vs_icon.png',
    package: 'virtusize_flutter_sdk',
  );
  static Image rightArrow = Image.asset(
    'assets/images/right_arrow.png',
    package: 'virtusize_flutter_sdk',
  );
  static Image errorHanger = Image.asset(
    'assets/images/error_hanger.png',
    package: 'virtusize_flutter_sdk',
  );
  static Image vsSignature = Image.asset(
    'assets/images/vs_signature.png',
    package: 'virtusize_flutter_sdk',
  );
  static Image circleDashedBorder = Image.asset(
    'assets/images/circle_dashed_border.png',
    package: 'virtusize_flutter_sdk',
  );

  /// Gets the product type image based on the [productType] and [style]
  static Image getProductTypeImage({required int productType, String? style}) {
    final postFixName =
        style != null ? '${productType}_$style' : '$productType';

    return Image.asset(
      'assets/images/product_type_$postFixName.png',
      package: 'virtusize_flutter_sdk',
    );
  }
}
