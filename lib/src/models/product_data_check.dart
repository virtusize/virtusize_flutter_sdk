class ProductDataCheck {
  /// A string to represent a external product ID from a client's system
  final String externalProductId;

  /// A boolean to tell whether it's a valid product in the Virtusize server
  final bool isValidProduct;

  ProductDataCheck(this.externalProductId, this.isValidProduct);

  @override
  String toString() {
    return '{externalProductId: $externalProductId, isValidProduct: $isValidProduct}';
  }
}
