import 'package:flutter/foundation.dart';

class VirtusizeOrderItem {
  final String productId;
  final String size;
  final String sizeAlias;
  final String variantId;
  final String imageUrl;
  final String color;
  final String gender;
  final double unitPrice;
  final String currency;
  final int quantity;
  final String url;

  VirtusizeOrderItem(
      {@required this.productId,
      @required this.size,
      this.sizeAlias,
      this.variantId,
      @required this.imageUrl,
      this.color,
      this.gender,
      @required this.unitPrice,
      @required this.currency,
      this.quantity = 1,
      this.url});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> orderItemJson = {
      'externalProductId': productId,
      'size': size,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'currency': currency,
      'quantity': quantity
    };
    if(sizeAlias != null) {
      orderItemJson['sizeAlias'] = sizeAlias;
    }
    if(variantId != null) {
      orderItemJson['variantId'] = variantId;
    }
    if(color != null) {
      orderItemJson['color'] = color;
    }
    if(gender != null) {
      orderItemJson['gender'] = gender;
    }
    if(url != null) {
      orderItemJson['url'] = url;
    }
    return orderItemJson;
  }
}
