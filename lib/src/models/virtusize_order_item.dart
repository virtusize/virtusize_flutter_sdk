import 'package:flutter/foundation.dart';

class VirtusizeOrderItem {
  /// The external product ID provided by the client. It must be unique for a product.
  final String externalProductId;
  /// The name of the size, e.g. "S", "M", etc.
  final String size;
  /// The alias of the size is added if the size name is not identical from the product page
  final String sizeAlias;
  /// The variant ID that is set on the product SKU, color, or size if there are several options
  final String variantId;
  /// The image URL of the item
  final String imageUrl;
  /// The color of the item, e.g. "Red", etc.
  final String color;
  /// An identifier for the gender, e.g. "W", "Women", etc.
  final String gender;
  /// The product price that is a floating number with a maximum of 12 digits and 2 decimals (12, 2)
  final double unitPrice;
  /// The currency code, e.g. "JPY", etc.
  final String currency;
  /// The number of the item purchased. If it's not passed, It will be set to 1
  final int quantity;
  /// The URL of the product page. Please make sure this is a URL that users can access.
  final String url;

  VirtusizeOrderItem(
      {@required this.externalProductId,
      @required this.size,
      this.sizeAlias,
      this.variantId,
      @required this.imageUrl,
      this.color,
      this.gender,
      @required this.unitPrice,
      @required this.currency,
      this.quantity = 1,
      this.url}) {
    assert(externalProductId != null);
    assert(size != null);
    assert(imageUrl != null);
    assert(unitPrice != null);
    assert(currency != null);
  }

  /// A function to convert the [VirtusizeOrderItem] class to a Map of String to dynamic in order to pass it to Native
  Map<String, dynamic> toJson() {
    Map<String, dynamic> orderItemJson = {
      'externalProductId': externalProductId,
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
