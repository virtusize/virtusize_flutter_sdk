import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_server_product.dart';

Future<void> downloadProductImage(VirtusizeServerProduct product) async {
  var image = await _downloadImage(product.imageURL ?? '');
  image ??= await _downloadImage(product.croudinaryImageURL ?? '');

  if (image != null) {
    product.networkProductImage = image;
  }
}

Future<Image?> _downloadImage(String imageUrl) {
  final Image networkImage = Image.network(imageUrl);
  final Completer<Image?> completer = Completer<Image?>();
  final ImageStream stream = networkImage.image.resolve(
    ImageConfiguration.empty,
  );
  stream.addListener(
    ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        completer.complete(networkImage);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        completer.complete(null);
      },
    ),
  );

  return completer.future;
}
