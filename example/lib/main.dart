import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:virtusize_flutter_plugin/virtusize_plugin.dart';
import 'package:virtusize_flutter_plugin/virtusize_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _hasSetVirtusizeProps = 'Unknown';
  VirtusizeButton _button = null;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String hasSetVirtusizeProps;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      hasSetVirtusizeProps = await VirtusizePlugin.setVirtusizeProps(
          '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
          '123',
          Env.staging,
          Language.en,
          true,
          [Language.en, Language.jp],
          [InfoCategory.generalFit, InfoCategory.brandSizing]);
    } on PlatformException {
      hasSetVirtusizeProps = 'failed to set VirtusizepProps';
    }

    try {
      await VirtusizePlugin.setVirtusizeProduct(
          '694', 'http://www.image.com/goods/12345.jpg');
    } on PlatformException {
      print('failed to set VirtusizeProduct');
    }

    try {
      await VirtusizePlugin.setVirtusizeView(_button.getViewId());
    } on PlatformException {
      print('failed to set VirtusizeView');
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
    _button = VirtusizeButton();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(children: [
          Text('Has set Virtusize props: $_hasSetVirtusizeProps\n'),
          Flexible(child: _button)
        ]),
      ),
    );
  }
}
