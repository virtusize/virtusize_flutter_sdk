import 'package:flutter/foundation.dart';

import 'virtusize_order_item.dart';

class VirtusizeOrder {

  /// The order ID provided by the client
  final String externalOrderId;

  /// A list of the order items.
  final List<VirtusizeOrderItem> items;

  VirtusizeOrder({@required this.externalOrderId, this.items}) {
    assert(externalOrderId != null);
  }

  /// A function to convert the [VirtusizeOrder] class to a Map
  Map<String, dynamic> toJson() {
    Map<String, dynamic> orderJson = {
      'externalOrderId': externalOrderId,
    };
    orderJson['items'] = items.map((item) => item.toJson()).toList();
    return orderJson;
  }
}