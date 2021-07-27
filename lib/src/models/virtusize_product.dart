import 'package:flutter/material.dart';

import '../utils/virtusize_constants.dart';
import 'virtusize_model.dart';

/// This enum contains the two possible product image types
enum ProductImageType { store, user }

class VirtusizeProduct extends VirtusizeModel {
  VirtusizeProduct(data) : super(data);

  /// The image loaded from the [imageURL]
  Image networkProductImage;

  /// The product image type as a String
  String get _imageType => decodedData[FlutterVirtusizeKey.imageType];

  /// The product image type as a [ProductImageType]
  ProductImageType get imageType {
    if (_imageType == "store") {
      return ProductImageType.store;
    } else if (_imageType == "user") {
      return ProductImageType.user;
    }
    return null;
  }

  /// An integer to represent the internal product ID in the Virtusize server
  int get productId => decodedData[FlutterVirtusizeKey.productId];

  /// The product image URL
  String get imageURL  => decodedData[FlutterVirtusizeKey.imageURL];

  /// The product type
  int get productType => decodedData[FlutterVirtusizeKey.productType];

  /// The product style
  String get productStyle => decodedData[FlutterVirtusizeKey.productStyle];

  @override
  String toString() {
    return decodedData.toString();
  }
}