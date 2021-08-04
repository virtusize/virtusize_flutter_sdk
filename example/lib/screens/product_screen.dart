import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

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

  VirtusizeClientProduct _product;
  String _externalID;

  @override
  void initState() {
    super.initState();

    _externalID = widget.externalID ??
        _externalIDList[Random().nextInt(_externalIDList.length)];

    _product = VirtusizeClientProduct(
        externalProductId: _externalID,
        imageURL: 'https://www.image.com/goods/12345.jpg');

    VirtusizeSDK.instance.loadVirtusize(_product);
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
          VirtusizeInPageStandard.vsStyle(
              product: _product, style: VirtusizeStyle.Black),
          Container(height: 16),
          VirtusizeInPageMini.vsStyle(
              product: _product, style: VirtusizeStyle.Teal),
          Container(height: 16),
          VirtusizeButton.vsStyle(product: _product),
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
