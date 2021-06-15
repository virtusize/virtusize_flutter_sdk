import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _hasSetVirtusizeProps = 'Unknown';
  VirtusizeButton _virtusizeButton;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String hasSetVirtusizeProps;
    try {
      hasSetVirtusizeProps = await VirtusizePlugin.setVirtusizeProps(
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
      hasSetVirtusizeProps = 'Failed to set VirtusizepProps';
    }

    try {
      await VirtusizePlugin.setVirtusizeProduct(
          '694', 'http://www.image.com/goods/12345.jpg');
    } on PlatformException {
      print('Failed to set VirtusizeProduct');
    }

    try {
      await VirtusizePlugin.setVirtusizeView(_virtusizeButton.getId());
    } on PlatformException {
      print('Failed to set VirtusizeView');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _hasSetVirtusizeProps = hasSetVirtusizeProps;
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
          title: const Text('Virtusize Plugin example app'),
        ),
        body: Center(
            child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Has set Virtusize props: $_hasSetVirtusizeProps\n'),
                      _virtusizeButton
                    ]))),
      ),
    );
  }
}
