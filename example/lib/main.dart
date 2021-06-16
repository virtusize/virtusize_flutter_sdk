import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeVirtusize();
  runApp(MyApp());
}

Future<void> initializeVirtusize() async {
  try {
    await VirtusizePlugin.setVirtusizeProps(
        // Only the API key is required
        '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
        // For using the Order API, a user ID is required
        '123',
        // By default, the Virtusize environment will be set to GLOBAL
        Env.staging,
        // By default, the initial language will be set based on the Virtusize environment
        Language.en,
        // By default, ShowSGI is false
        true,
        // By default, Virtusize allows all the possible languages
        [Language.en, Language.jp],
        // By default, Virtusize displays all the possible info categories in the Product Details tab
        [InfoCategory.generalFit, InfoCategory.brandSizing]);
  } on PlatformException {
    print('Failed to set the Virtusize props');
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  VirtusizeButton _virtusizeButton;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await VirtusizePlugin.setProduct(
          // Set the product's external ID
          '694',
          // Set the product image URL
          'http://www.image.com/goods/12345.jpg'
      );
    } on PlatformException {
      print('Failed to set VirtusizeProduct');
    }

    try {
      await VirtusizePlugin.setVirtusizeView(_virtusizeButton);
    } on PlatformException {
      print('Failed to set VirtusizeView');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    _virtusizeButton = VirtusizeButton(
      virtusizeStyle: VirtusizeStyle.Black,
      text: "Custom Text",
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Virtusize Plugin Example App'),
        ),
        body: Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _virtusizeButton
                    ]))),
      ),
    );
  }
}
