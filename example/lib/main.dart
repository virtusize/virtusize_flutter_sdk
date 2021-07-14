import 'package:flutter/material.dart';
import 'dart:async';

import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VirtusizePlugin.instance.setVirtusizeProps(
      // Only the API key is required
      apiKey: '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
      // For using the Order API, a user ID is required
      externalUserId: '123',
      // By default, the Virtusize environment will be set to GLOBAL
      env: Env.staging,
      // By default, the initial language will be set based on the Virtusize environment
      language: Language.jp,
      // By default, ShowSGI is false
      showSGI: true,
      // By default, Virtusize allows all the possible languages
      allowedLanguages: [Language.en, Language.jp],
      // By default, Virtusize displays all the possible info categories in the Product Details tab
      detailsPanelCards: [InfoCategory.generalFit, InfoCategory.brandSizing]);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    VirtusizePlugin.instance.setProduct(
        // Set the product's external ID
        externalId: 'vs_dress',
        // Set the product image URL
        imageUrl: 'http://www.image.com/goods/12345.jpg');

    VirtusizePlugin.instance
        .setVirtusizeMessageListener(VirtusizeMessageListener(vsEvent: (event) {
      print("Virtusize event: $event");
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
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Virtusize Plugin Example App'),
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
                        label: Text('サイズチェック', style: TextStyle(fontSize: 12)),
                        icon: Icon(Icons.account_circle_rounded),
                        style: ElevatedButton.styleFrom(
                            primary: Color(0xFF191919),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(32.0)))),
                        onPressed:
                            VirtusizePlugin.instance.openVirtusizeWebView),
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
                  Center(child: ElevatedButton(child: Text("Send a Test Order"), onPressed: _sendOrder))
                ],
              ))),
    );
  }

  void _sendOrder() {
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
    VirtusizePlugin.instance.sendOrder(order: order, onSuccess: () {
      print("Successfully sent the order");
    }, onError: (error) {
      print(error);
    });
  }
}
