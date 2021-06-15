import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:virtusize_flutter_plugin/src/models.dart';

class VirtusizeButton extends StatefulWidget {
  const VirtusizeButton(
      {Key key,
      this.virtusizeStyle = VirtusizeStyle.None,
      this.text})
      : super(key: key);

  final VirtusizeStyle virtusizeStyle;
  final String text;
  static _VirtusizeButtonState state = _VirtusizeButtonState();

  @override
  _VirtusizeButtonState createState() => state;

  int getId() {
    return state._id;
  }
}

class _VirtusizeButtonState extends State<VirtusizeButton> {
  int _id;

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    final String viewType = 'com.virtusize/virtusize_button';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "style": widget.virtusizeStyle.value
    };

    if (widget.text != null) {
      creationParams["text"] = widget.text;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SizedBox(
            width: 135,
            height: 36,
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
                _id = params.id;
                return PlatformViewsService.initSurfaceAndroidView(
                  id: params.id,
                  viewType: viewType,
                  layoutDirection: TextDirection.ltr,
                  creationParams: creationParams,
                  creationParamsCodec: StandardMessageCodec(),
                )
                  ..addOnPlatformViewCreatedListener(
                      params.onPlatformViewCreated
                  )
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
