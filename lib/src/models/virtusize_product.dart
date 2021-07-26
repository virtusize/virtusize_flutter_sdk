import 'package:flutter/material.dart';

import '../models/virtusize_enums.dart';
import '../utils/virtusize_constants.dart';
import 'virtusize_model.dart';

class VirtusizeProduct extends VirtusizeModel {
  VirtusizeProduct(data) : super(data);

  Image networkProductImage;

  String get _imageType => decodedData[VirtusizeFlutterKey.imageType];

  ProductImageType get imageType {
    if (_imageType == "store") {
      return ProductImageType.store;
    } else if (_imageType == "user") {
      return ProductImageType.user;
    }
    return null;
  }

  int get storeProductID => decodedData[VirtusizeFlutterKey.productID];

  String get imageUrl  => decodedData[VirtusizeFlutterKey.imageUrl];

  int get productType => decodedData[VirtusizeFlutterKey.productType];

  String get productStyle => decodedData[VirtusizeFlutterKey.productStyle];

  @override
  String toString() {
    return decodedData.toString();
  }
}