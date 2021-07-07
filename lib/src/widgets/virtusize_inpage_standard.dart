import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../virtusize_plugin.dart';

class VirtusizeInPageStandard extends StatefulWidget {
  const VirtusizeInPageStandard(
      {Key key,
      this.virtusizeStyle,
      this.buttonBackgroundColor,
      this.horizontalMargin = 16.0})
      : super(key: key);

  final VirtusizeStyle virtusizeStyle;
  final Color buttonBackgroundColor;
  final double horizontalMargin;

  @override
  _VirtusizeInPageStandardState createState() =>
      _VirtusizeInPageStandardState();
}

class _VirtusizeInPageStandardState extends State<VirtusizeInPageStandard> {
  static const defaultScaleForZeroMargin = 1.08;
  static const defaultHeightForZeroMargin = 133;
  double _height;
  double _calculatedScale;

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

    double screenWidth = MediaQuery.of(context).size.width;

    if (_calculatedScale == null) {
      double expectedInPageWidth =
          MediaQuery.of(context).size.width - widget.horizontalMargin * 2;
      _calculatedScale =
          defaultScaleForZeroMargin * (expectedInPageWidth / screenWidth);
    }
    if (_height == null) {
      _height = defaultHeightForZeroMargin * _calculatedScale;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return Transform.scale(
            scale: _calculatedScale,
            child: SizedBox(
                width: screenWidth,
                height: _height,
                child: PlatformViewLink(
                    viewType: viewType,
                    surfaceFactory: (BuildContext context,
                        PlatformViewController controller) {
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
                        ..addOnPlatformViewCreatedListener(
                            params.onPlatformViewCreated)
                        ..addOnPlatformViewCreatedListener((int id) {
                          VirtusizePlugin.instance.setVirtusizeView(
                              widget.toString(), id);
                          MethodChannel _channel = MethodChannel(
                              'com.virtusize/virtusize_inpage_standard_$id');
                          _channel.setMethodCallHandler((call) {
                            if (call.method == 'onInPageCardViewSizeChanged') {
                              print(
                                  'onInPageCardViewSizeChanged ${call.arguments}');
                              setState(() {
                                _height = call.arguments['height'] + 40;
                              });
                            } else if (call.method == 'onFinishLoading') {
                              print('onFinishLoading');
                            }
                            return null;
                          });
                        })
                        ..create();
                    })));
      case TargetPlatform.iOS:
        throw UnsupportedError("Unsupported platform view");
      default:
        throw UnsupportedError("Unsupported platform view");
    }
  }
}
