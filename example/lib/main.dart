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
        externalId: '694',
        // Set the product image URL
        imageUrl: 'http://www.image.com/goods/12345.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Virtusize Plugin Example App'),
          ),
          body: Center(
              child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    VirtusizeButton.vsStyle(),
                    Container(height: 16),
                    VirtusizeButton.vsStyle(
                        style: VirtusizeStyle.Teal, child: Text("Custom Text")),
                    Container(height: 16),
                    VirtusizeButton(
                      child: ElevatedButton.icon(
                          label:
                              Text('サイズチェック', style: TextStyle(fontSize: 12)),
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
                    ),
                    Container(height: 16),
                    VirtusizeButton(
                      child: Text("Custom Text"),
                    ),
                    Container(height: 16),
                    VirtusizeInPageMini.vsStyle(style: VirtusizeStyle.Teal),
                    Container(height: 16),
                    VirtusizeInPageMini(
                        backgroundColor: Colors.blue, horizontalMargin: 32)
                  ])))),
    );
  }
}
