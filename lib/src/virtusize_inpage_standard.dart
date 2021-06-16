import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'virtusize_view.dart';

class VirtusizeInPageStandard extends StatefulWidget implements VirtusizeView {
  int _id;

  @override
  _VirtusizeInPageStandardState createState() => _VirtusizeInPageStandardState();

  int getId() {
    return _id;
  }
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    final String viewType = 'com.virtusize/virtusize_inpage_standard';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return Expanded(
            child: PlatformViewLink(
          viewType: viewType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller,
              gestureRecognizers: const <
                  Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            widget._id = params.id;
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        ));
      case TargetPlatform.iOS:
        throw UnsupportedError("Unsupported platform view");
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }
}
