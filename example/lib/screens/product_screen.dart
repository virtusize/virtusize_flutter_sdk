import 'package:flutter/material.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

class ProductScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  void initState() {
    super.initState();

    VirtusizePlugin.instance.setProduct(
        // Set the product's external ID
        externalId: 'vs_pants',
        // Set the product image URL
        imageUrl: 'http://www.image.com/goods/12345.jpg');

    VirtusizePlugin.instance.setVirtusizeMessageListener(
        VirtusizeMessageListener(vsEvent: (eventName) {
      print("ProductScreen Virtusize event: $eventName");
    }, vsError: (error) {
      print("ProductScreen Virtusize error: $error");
    }, productDataCheckData: (productDataCheck) {
      print('ProductScreen ProductDataCheck: $productDataCheck');
    }, productDataCheckError: (error) {
      print('ProductScreen ProductDataCheck error: $error');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Virtusize Plugin Example App'),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          VirtusizeInPageStandard.vsStyle(style: VirtusizeStyle.Black)
        ])));
  }
}
