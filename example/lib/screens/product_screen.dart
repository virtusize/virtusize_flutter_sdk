import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

class ProductScreen extends StatefulWidget {
  final String externalID;

  ProductScreen({this.externalID});

  @override
  State<StatefulWidget> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const List<String> _externalIDList = [
    "vs_dress",
    "vs_top",
    "vs_shirt",
    "vs_coat",
    "vs_jacket",
    "vs_sweater",
    "vs_skirt",
    "vs_pants"
  ];


  String _externalID;

  @override
  void initState() {
    super.initState();

    _externalID = widget.externalID ?? _externalIDList[Random().nextInt(_externalIDList.length)];

    VirtusizePlugin.instance.setProduct(
        externalId: _externalID,
        imageURL: 'http://www.image.com/goods/12345.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Virtusize Product $_externalID'),
        ),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          VirtusizeInPageStandard.vsStyle(style: VirtusizeStyle.Black),
          Container(height: 16),
          VirtusizeInPageMini.vsStyle(style: VirtusizeStyle.Teal),
          Container(height: 16),
          VirtusizeButton.vsStyle(),
          Container(height: 16),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context, CupertinoPageRoute(builder: (_) {
                  return ProductScreen();
                }));
              },
              child: Text("Go to next product page"))
        ])));
  }
}
