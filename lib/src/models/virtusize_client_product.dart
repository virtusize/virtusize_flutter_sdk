class VirtusizeClientProduct {
  /// A string to represent an external product ID from the client's system
  final String externalProductId;

  /// The URL of the product image that is fully qualified with a domain name (FQDN) and the HTTPS protocol
  final String imageURL;

  VirtusizeClientProduct({
    required this.externalProductId,
    required this.imageURL,
  });
}
