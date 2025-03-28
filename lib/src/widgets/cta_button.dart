import 'package:flutter/material.dart';

import '../res/vs_colors.dart';
import '../res/vs_images.dart';

class CTAButton extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const CTAButton({
    super.key,
    required this.text,
    this.textStyle,
    this.backgroundColor = Colors.white,
    this.textColor = VSColors.vsGray900,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        //change background color of button
        backgroundColor: backgroundColor,
        //change text color of button
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      onPressed: onPressed ?? () => {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(text, style: textStyle),
          Container(width: 1.0),
          SizedBox(
            width: 5,
            child: Image(
              image: VSImages.rightArrow.image,
              fit: BoxFit.cover,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
