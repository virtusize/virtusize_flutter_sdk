import 'package:flutter/material.dart';

import '../models/virtusize_enums.dart';
import '../utils/virtusize_constants.dart';
import 'virtusize_model.dart';

class VirtusizeProduct extends VirtusizeModel {
  VirtusizeProduct(data) : super(data);

  /// The image loaded from the [imageURL]
  Image networkProductImage;

  /// The product image type as a String
  String get _imageType => decodedData[VirtusizeFlutterKey.imageType];

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
  int get productId => decodedData[VirtusizeFlutterKey.productId];

  /// The product image URL
  String get imageURL  => decodedData[VirtusizeFlutterKey.imageURL];

  /// The product type
  int get productType => decodedData[VirtusizeFlutterKey.productType];

  /// The product style
  String get productStyle => decodedData[VirtusizeFlutterKey.productStyle];

  @override
  String toString() {
    return decodedData.toString();
  }
}