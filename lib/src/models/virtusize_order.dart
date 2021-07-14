import 'package:flutter/foundation.dart';

import 'virtusize_order_item.dart';

class VirtusizeOrder {
  final String externalOrderId;
  final List<VirtusizeOrderItem> items;

  VirtusizeOrder({@required this.externalOrderId, this.items});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> orderJson = {
      'externalOrderId': externalOrderId,
    };
    orderJson['items'] = items.map((item) => item.toJson()).toList();
    return orderJson;
  }
}