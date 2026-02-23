class ProductDataCheck {
  /// A string to represent a external product ID from a client's system
  final String externalProductId;

  /// A boolean to tell whether it's a valid product in the Virtusize server
  final bool isValidProduct;

  /// A string to represent the store name
  final String storeName;

  ProductDataCheck(this.externalProductId, this.isValidProduct, this.storeName);

  @override
  String toString() {
    return '{externalProductId: $externalProductId, isValidProduct: $isValidProduct, storeName: $storeName}';
  }

  bool canBuildVirtusizeWidget() => _Stores.values.any((store) => store.name == storeName);
}

enum _Stores{
  snkrdunk
}
