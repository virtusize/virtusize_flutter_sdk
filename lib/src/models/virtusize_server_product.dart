import 'package:flutter/material.dart';

import 'package:virtusize_flutter_sdk/src/utils/virtusize_constants.dart';
import 'virtusize_model.dart';

/// This enum contains the two possible product image types
enum ProductImageType { store, user }

class VirtusizeServerProduct extends VirtusizeModel {
  VirtusizeServerProduct(super.data);

  /// The image loaded from the [imageURL]
  Image? networkProductImage;

  /// The product image type as a String
  String get _imageType => decodedData[FlutterVirtusizeKey.imageType];

  /// The product image type as a [ProductImageType]
  ProductImageType? get imageType {
    if (_imageType == "store") {
      return ProductImageType.store;
    } else if (_imageType == "user") {
      return ProductImageType.user;
    }
    return null;
  }

  /// A string to represent a external product ID from a client's system
  String get externalProductId =>
      decodedData[FlutterVirtusizeKey.externalProductId] ?? '';

  /// The product image URL
  String? get imageURL => decodedData[FlutterVirtusizeKey.imageURL];

  String? get cloudinaryImageURL =>
      decodedData[FlutterVirtusizeKey.cloudinaryImageURL];

  /// The product type
  int get productType => decodedData[FlutterVirtusizeKey.productType];

  /// The product style
  String? get productStyle => decodedData[FlutterVirtusizeKey.productStyle];

  @override
  String toString() {
    return decodedData.toString();
  }
}
