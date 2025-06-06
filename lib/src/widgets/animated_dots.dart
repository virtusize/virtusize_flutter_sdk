import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/src/res/vs_colors.dart';

class AnimatedDots extends StatefulWidget {
  final int dotNumbers;

  const AnimatedDots({super.key, this.dotNumbers = 3});

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with TickerProviderStateMixin {
  final _characters = <Animation, String>{};
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500 * widget.dotNumbers),
    );

    var start = 0.0;
    final duration = 1.0 / widget.dotNumbers;
    for (int i = 0; i < widget.dotNumbers; i++) {
      final animation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          curve: Interval(start, start + duration, curve: Curves.easeInOut),
          parent: _controller,
        ),
      );
      _characters[animation] = '.';
      start += duration;
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward(from: duration - 0.5);
      }
    });
    _controller.forward(from: duration - 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          _characters.entries
              .map(
                (entry) => FadeTransition(
                  opacity: entry.key as Animation<double>,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: VSColors.vsGray900,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
