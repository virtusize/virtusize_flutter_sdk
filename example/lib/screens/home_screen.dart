import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/virtusize_sdk.dart';
// import '../screens/product_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    /// Set up the product information in order to populate the Virtusize view
    VirtusizeSDK.instance.setProduct(
        // Set the product's external ID
        externalId: 'vs_dress',
        // Set the product image URL
        imageURL: 'http://www.image.com/goods/12345.jpg');

    /// Optional: Set a [VirtusizeMessageListener] to listen for events or the [ProductDataCheck] result from Virtusize
    VirtusizeSDK.instance.setVirtusizeMessageListener(
        VirtusizeMessageListener(vsEvent: (eventName) {
      print("Virtusize event: $eventName");
    }, vsError: (error) {
      print("Virtusize error: $error");
    }, productDataCheckSuccess: (productDataCheck) {
      print('ProductDataCheck: $productDataCheck');
    }, productDataCheckError: (error) {
      print('ProductDataCheck error: $error');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Virtusize Example App'),
        ),
        body: Padding(
            padding: EdgeInsets.only(top: 16),
            child: ListView(shrinkWrap: true, children: [
              Center(
                  child:

                      /// A [VirtusizeButton] widget with the default VirtusizeStyle
                      VirtusizeButton.vsStyle()),
              Container(height: 16),
              Center(
                  child:

                      /// A [VirtusizeButton] widget with `Teal` style and a custom text
                      VirtusizeButton.vsStyle(
                          style: VirtusizeStyle.Teal,
                          child: Text("Custom Text"))),
              Container(height: 16),
              Center(
                  child:

                      /// A [VirtusizeButton] widget with a custom style
                      VirtusizeButton(
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

                    /// Implement the [OnPressed] callback with the [VirtusizePlugin.instance.openVirtusizeWebView] function if you have customized the button
                    onPressed: VirtusizeSDK.instance.openVirtusizeWebView),
              )),
              Container(height: 16),

              /// A [VirtusizeInPageMini] widget with `Teal` style and a default horizontal margin of `16`
              VirtusizeInPageMini.vsStyle(style: VirtusizeStyle.Teal),
              Container(height: 16),

              /// A [VirtusizeInPageMini] widget with a `blue` background color and a horizontal margin of `32`
              VirtusizeInPageMini(
                  backgroundColor: Colors.blue, horizontalMargin: 32),
              Container(height: 16),

              /// A [VirtusizeInPageStandard] widget with `Black` style and a default horizontal margin of `16`
              VirtusizeInPageStandard.vsStyle(style: VirtusizeStyle.Black),
              Container(height: 16),

              /// A [VirtusizeInPageStandard] widget with a `amber` background color and a horizontal margin of `32`
              VirtusizeInPageStandard(
                  buttonBackgroundColor: Colors.amber, horizontalMargin: 32),
              Container(height: 16),

              /// A button to send a test order
              Center(
                  child: ElevatedButton(
                      child: Text("Send a Test Order"), onPressed: _sendOrder)),
              // Center(
              //     child: ElevatedButton(
              //         onPressed: () {
              //           Navigator.push(context,
              //               CupertinoPageRoute(builder: (_) {
              //             return ProductScreen();
              //           }));
              //         },
              //         child: Text("Go to next product page")))
            ])));
  }

  /// Demonstrates how to send an order to the Virtusize server
  /// Note: The [sizeAlias], [variantId], [color], [gender] and [url] arguments for a [VirtusizeOrderItem] are optional
  void _sendOrder() {

    /// You can set the user ID anytime before sending an order
    VirtusizeSDK.instance.setUserId("123456");

    /// Create an order with items
    VirtusizeOrder order =
        VirtusizeOrder(externalOrderId: "20200601586", items: [
      VirtusizeOrderItem(
          externalProductId: "A001",
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

    /// Send the order
    VirtusizeSDK.instance.sendOrder(
        order: order,
        // The onSuccess callback is optional and is called when the app has successfully sent the order
        onSuccess: (sentOrder) {
          print("Successfully sent the order $sentOrder");
        },
        // The onError callback is optional and gets called when an error occurs while the app is sending the order
        onError: (error) {
          print(error);
        });
  }
}
