import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';
import '../screens/product_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    VirtusizePlugin.instance.setProduct(
        // Set the product's external ID
        externalId: 'vs_dress',
        // Set the product image URL
        imageUrl: 'http://www.image.com/goods/12345.jpg');

    VirtusizePlugin.instance.setVirtusizeMessageListener(
        VirtusizeMessageListener(vsEvent: (eventName) {
      print("Virtusize event: $eventName");
    }, vsError: (error) {
      print("Virtusize error: $error");
    }, productDataCheckData: (productDataCheck) {
      print('ProductDataCheck: $productDataCheck');
    }, productDataCheckError: (error) {
      print('ProductDataCheck error: $error');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Virtusize Example App'),
        ),
        body: Padding(
            padding: EdgeInsets.only(top: 16),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(child: VirtusizeButton.vsStyle()),
                Container(height: 16),
                Center(
                    child: VirtusizeButton.vsStyle(
                        style: VirtusizeStyle.Teal,
                        child: Text("Custom Text"))),
                Container(height: 16),
                Center(
                    child: VirtusizeButton(
                  child: ElevatedButton.icon(
                      label:
                          Text('Custom Button', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.account_circle_rounded),
                      style: ElevatedButton.styleFrom(
                          primary: Color(0xFF191919),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(32.0)))),
                      onPressed: VirtusizePlugin.instance.openVirtusizeWebView),
                )),
                Container(height: 16),
                Center(
                    child: VirtusizeButton(
                  child: Text("Custom Text"),
                )),
                Container(height: 16),
                VirtusizeInPageMini.vsStyle(style: VirtusizeStyle.Teal),
                Container(height: 16),
                VirtusizeInPageMini(
                    backgroundColor: Colors.blue, horizontalMargin: 32),
                Container(height: 16),
                VirtusizeInPageStandard.vsStyle(style: VirtusizeStyle.Black),
                Container(height: 16),
                VirtusizeInPageStandard(
                    buttonBackgroundColor: Colors.amber, horizontalMargin: 32),
                Container(height: 16),
                Center(
                    child: ElevatedButton(
                        child: Text("Send a Test Order"),
                        onPressed: _sendOrder)),
                Center(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (_) {
                            return ProductScreen(externalID: "vs_pants");
                          }));
                        },
                        child: Text("Go to next product page")))
              ]
            )));
  }

  void _sendOrder() {
    // VirtusizePlugin.instance.setUserID("123456");
    VirtusizeOrder order =
        VirtusizeOrder(externalOrderId: "20200601586", items: [
      VirtusizeOrderItem(
          productId: "A001",
          size: "L",
          sizeAlias: "Large",
          variantId: "A001_SIZEL_RED",
          imageUrl: "http://images.example.com/products/A001/red/image1xl.jpg",
          color: "Red",
          gender: "W",
          unitPrice: 5100.00,
          currency: "JPY",
          quantity: 1,
          url: "http://example.com/products/A001")
    ]);

    VirtusizePlugin.instance.sendOrder(
        order: order,
        onSuccess: (order) {
          print("Successfully sent the order $order");
        },
        onError: (error) {
          print(error);
        });
  }
}
