import 'package:flutter/material.dart';

import '../models/virtusize_enums.dart';
import 'virtusize_model.dart';

class Product extends VirtusizeModel {
  Product(data) : super(data);

  Image networkProductImage;

  String get _imageType => decodedData["imageType"];

  ProductImageType get imageType {
    if (_imageType == "store") {
      return ProductImageType.store;
    } else if (_imageType == "user") {
      return ProductImageType.user;
    }
    return null;
  }

  String get imageUrl  => decodedData["imageUrl"];

  int get productType => decodedData["productType"];

  int get productID => decodedData["productID"];

  String get productStyle => decodedData["productStyle"];
}