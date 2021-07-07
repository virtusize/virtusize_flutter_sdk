import 'package:flutter/material.dart';
import 'package:virtusize_flutter_plugin/src/ui/colors.dart';

class ProductImageView extends StatelessWidget {
  final String src;

  ProductImageView({this.src});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            border: Border.all(
              color: VSColor.vsGray800,
              width: 0.5,
            ),
          )),
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            image: src != null
                ? DecorationImage(image: NetworkImage(src), fit: BoxFit.cover)
                : null,
            borderRadius: BorderRadius.all(Radius.circular(18.0)),
          )),
    ]);
  }
}
