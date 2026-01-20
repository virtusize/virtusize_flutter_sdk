import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_sdk/src/models/virtusize_server_product.dart';

const _imageLoadTimeout = Duration(seconds: 10);

Future<void> downloadProductImage(VirtusizeServerProduct product) async {
  final imageURL = product.imageURL;
  final cloudinaryImageURL = product.cloudinaryImageURL;

  // Build list of valid URLs to try in parallel
  final futures = <Future<Image?>>[];
  if (imageURL != null && imageURL.isNotEmpty) {
    futures.add(_downloadImageWithTimeout(imageURL));
  }
  if (cloudinaryImageURL != null && cloudinaryImageURL.isNotEmpty) {
    futures.add(_downloadImageWithTimeout(cloudinaryImageURL));
  }

  if (futures.isEmpty) return;

  // Try all URLs in parallel, use the first successful result
  final image = await _firstSuccessful(futures);

  if (image != null) {
    product.networkProductImage = image;
  }
}

/// Returns the first successful (non-null) result from the futures.
/// If all futures complete with null, returns null.
Future<Image?> _firstSuccessful(List<Future<Image?>> futures) async {
  if (futures.isEmpty) return null;

  final completer = Completer<Image?>();
  var pendingCount = futures.length;
  var completed = false;

  for (final future in futures) {
    future.then((image) {
      if (completed) return;
      if (image != null) {
        completed = true;
        completer.complete(image);
      } else {
        pendingCount--;
        if (pendingCount == 0 && !completed) {
          completed = true;
          completer.complete(null);
        }
      }
    });
  }

  return completer.future;
}

Future<Image?> _downloadImageWithTimeout(String imageUrl) {
  return _downloadImage(
    imageUrl,
  ).timeout(_imageLoadTimeout, onTimeout: () => null);
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
        if (!completer.isCompleted) {
          completer.complete(networkImage);
        }
      },
      onError: (Object exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ),
  );

  return completer.future;
}
