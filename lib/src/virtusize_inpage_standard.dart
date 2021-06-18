import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../virtusize_plugin.dart';

class VirtusizeInPageStandard extends StatefulWidget {
  const VirtusizeInPageStandard(
      {Key key,
      this.virtusizeStyle,
      this.buttonBackgroundColor,
      this.horizontalMargin,
      this.messageTextSize,
      this.buttonTextSize})
      : super(key: key);

  final VirtusizeStyle virtusizeStyle;
  final Color buttonBackgroundColor;
  final double horizontalMargin;
  final double messageTextSize;
  final double buttonTextSize;

  @override
  _VirtusizeInPageStandardState createState() =>
      _VirtusizeInPageStandardState();
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    final String viewType = 'com.virtusize/virtusize_inpage_standard';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    if (widget.virtusizeStyle != null) {
      creationParams['virtusizeStyle'] = widget.virtusizeStyle.value;
    }
    if (widget.buttonBackgroundColor != null) {
      creationParams['buttonBackgroundColor'] =
          '#${widget.buttonBackgroundColor.value.toRadixString(16)}';
    }
    if (widget.horizontalMargin != null) {
      creationParams['horizontalMargin'] = widget.horizontalMargin;
    }
    if (widget.messageTextSize != null) {
      creationParams['messageTextSize'] = widget.messageTextSize;
    }
    if (widget.buttonTextSize != null) {
      creationParams['buttonTextSize'] = widget.buttonTextSize;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
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
              return PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: creationParams,
                creationParamsCodec: StandardMessageCodec(),
              )
                ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
                ..addOnPlatformViewCreatedListener((int id) {
                  VirtusizePlugin.setVirtusizeView(widget.toString(), id);
                  MethodChannel _channel = MethodChannel(
                      'com.virtusize/virtusize_inpage_standard_$id');
                  _channel.setMethodCallHandler((call) {
                    if (call.method == 'onSizeChanged') {
                      print('onSizeChanged ${call.arguments}');
                    } else if (call.method == 'onFinishLoading') {
                      print('onFinishLoading');
                    }
                    return null;
                  });
                })
                ..create();
            });
      case TargetPlatform.iOS:
        throw UnsupportedError("Unsupported platform view");
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }
}
