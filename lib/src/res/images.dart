import 'package:flutter/material.dart';

/// The Virtusize images
class VSImages {
  static Image vsIcon = Image.asset('assets/images/vs_icon.png', package: 'virtusize_flutter_plugin');
  static Image rightArrow = Image.asset('assets/images/right_arrow.png', package: 'virtusize_flutter_plugin');
  static Image errorHanger = Image.asset('assets/images/error_hanger.png', package: 'virtusize_flutter_plugin');
  static Image vsSignature = Image.asset('assets/images/vs_signature.png', package: 'virtusize_flutter_plugin');
  static Image circleDashedBorder = Image.asset('assets/images/circle_dashed_border.png', package: 'virtusize_flutter_plugin');

  /// Gets the product type image based on the product type and style
  static Image getProductTypeImage({@required int productType, String style}) {
    String postFixName;
    if(style != null) {
       postFixName = '${productType}_$style';
    } else {
      postFixName = '$productType';
    }
    return Image.asset('assets/images/product_type_$postFixName.png', package: 'virtusize_flutter_plugin');
  }
}