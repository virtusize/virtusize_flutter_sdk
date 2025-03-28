import 'package:flutter/material.dart';

import 'product_image_view.dart';

class AnimatedProductImages extends StatefulWidget {
  final ProductImageView? userProductImageView;
  final ProductImageView? storeProductImageView;

  const AnimatedProductImages({
    super.key,
    this.userProductImageView,
    this.storeProductImageView,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AnimatedProductImagesState createState() => _AnimatedProductImagesState();
}

class _AnimatedProductImagesState extends State<AnimatedProductImages>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  bool _storeProductImageVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3250),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _storeProductImageVisible = !_storeProductImageVisible;
        });
        _controller.forward(from: 0);
      }
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _storeProductImageVisible ? 0.0 : 1.0,
          duration: Duration(milliseconds: 750),
          child: widget.userProductImageView,
        ),
        AnimatedOpacity(
          opacity: _storeProductImageVisible ? 1.0 : 0.0,
          duration: Duration(milliseconds: 750),
          child: widget.storeProductImageView,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
