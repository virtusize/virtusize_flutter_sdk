import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Declare a global [VirtusizeClientProduct] variable, which will be passed to the `Virtusize` widgets in order to bind the product info
  late VirtusizeClientProduct _product;

  @override
  void initState() {
    super.initState();

    /// Set up the product information
    _product = VirtusizeClientProduct(
      externalProductId: 'vs_dress',
      imageURL: 'https://www.image.com/goods/12345.jpg',
    );

    /// Loads the product in order to populate the Virtusize view
    VirtusizeSDK.instance.loadVirtusize(_product);

    /// If you want to update the product to a different one while the user is on the same screen,
    /// assign a different `VirtusizeClientProduct` object to [_product] and reload the product using [VirtusizeSDK.instance.loadVirtusize] inside of `setState()` to re-build this widget
    setState(() {
      _product = VirtusizeClientProduct(
        externalProductId: 'vs_pants',
        imageURL: 'https://www.image.com/goods/12345.jpg',
      );
      VirtusizeSDK.instance.loadVirtusize(_product);
    });

    /// Optional: Set a [VirtusizeMessageListener] to listen for events or the [ProductDataCheck] result from Virtusize
    VirtusizeSDK.instance.setVirtusizeMessageListener(
      VirtusizeMessageListener(
        vsEvent: (eventName) {
          print("Virtusize event: $eventName");
        },
        vsError: (error) {
          print("Virtusize error: $error");
        },
        productDataCheckSuccess: (productDataCheck) {
          print('ProductDataCheck success: $productDataCheck');
        },
        productDataCheckError: (error) {
          print('ProductDataCheck error: $error');
        },
      ),
    );
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
        child: ListView(
          shrinkWrap: true,
          children: [

            Center(
              child:
              /// A [VirtusizeButton] widget with the default VirtusizeStyle
              VirtusizeButton.vsStyle(product: _product),
            ),
            Container(height: 16),
            Center(
              child:
              /// A [VirtusizeButton] widget with `Teal` style and a custom text
              VirtusizeButton.vsStyle(
                product: _product,
                style: VirtusizeStyle.teal,
                child: Text("Custom Text"),
              ),
            ),
            Container(height: 16),
            Center(
              child:
              /// A [VirtusizeButton] widget with a custom style
              VirtusizeButton(
                product: _product,
                child: ElevatedButton.icon(
                  label: Text('Custom Button', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.account_circle_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF191919),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                  ),

                  /// Implement the [onPressed] callback with the [VirtusizePlugin.instance.openVirtusizeWebView] function if you have customized the button
                  onPressed:
                      () =>
                          VirtusizeSDK.instance.openVirtusizeWebView(_product),
                ),
              ),
            ),
            Container(height: 16),

            /// A [VirtusizeInPageMini] widget with `Teal` style and a default horizontal margin of `16`
            VirtusizeInPageMini.vsStyle(
              product: _product,
              style: VirtusizeStyle.teal,
            ),
            Container(height: 16),

            /// A [VirtusizeInPageMini] widget with a `blue` background color and a horizontal margin of `32`
            VirtusizeInPageMini(
              product: _product,
              backgroundColor: Colors.blue,
            ),
            Container(height: 16),

            /// A [VirtusizeInPageStandard] widget with `Black` style and a default horizontal margin of `16`
            VirtusizeInPageStandard.vsStyle(
              product: _product,
              style: VirtusizeStyle.black,
            ),
            Container(height: 16),

            /// A [VirtusizeInPageStandard] widget with a `amber` background color and a horizontal margin of `32`
            VirtusizeInPageStandard(
              product: _product,
              buttonBackgroundColor: Colors.amber,
            ),
            Container(height: 16),

            /// A button to send a test order
            Center(
              child: ElevatedButton(
                onPressed: _sendOrder,
                child: Text("Send a Test Order"),
              ),
            ),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) {
                        return ProductScreen();
                      },
                    ),
                  );
                },
                child: Text("Go to next product page"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Demonstrates how to send an order to the Virtusize server
  /// Note: The [sizeAlias], [variantId], [color], [gender] and [url] arguments for a [VirtusizeOrderItem] are optional
  void _sendOrder() {
    /// You can set the user ID anytime before sending an order
    VirtusizeSDK.instance.setUserId("123456");

    /// Create an order with items
    VirtusizeOrder order = VirtusizeOrder(
      externalOrderId: "20200601586",
      items: [
        VirtusizeOrderItem(
          externalProductId: "A001",
          size: "L",
          sizeAlias: "Large",
          variantId: "A001_SIZEL_RED",
          imageURL: "http://images.example.com/products/A001/red/image1xl.jpg",
          color: "Red",
          gender: "W",
          unitPrice: 5100.00,
          currency: "JPY",
          quantity: 1,
          url: "http://example.com/products/A001",
        ),
      ],
    );

    /// Send the order
    VirtusizeSDK.instance.sendOrder(
      order: order,

      /// The [onSuccess] callback is optional and is called when the app has successfully sent the order
      onSuccess: (sentOrder) {
        print("Successfully sent the order $sentOrder");
      },

      /// The [onError] callback is optional and gets called when an error occurs while the app is sending the order
      onError: (error) {
        print(error);
      },
    );
  }
}
