import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../ui/colors.dart';
import '../ui/images.dart';

class CTAButton extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Function onPressed;

  const CTAButton(
      {Key key,
      this.backgroundColor = Colors.white,
      this.textColor = VSColors.vsGray900,
      this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('サイズチェック',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Container(width: 1.0),
        Container(
          width: 5,
          child: Image(
              image: VSImages.rightArrow.image,
              fit: BoxFit.cover,
              color: textColor),
        )
      ]),
      style: ElevatedButton.styleFrom(
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          //change background color of button
          primary: backgroundColor,
          //change text color of button
          onPrimary: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          )),
      onPressed: onPressed ?? () => {},
    );
  }
}
