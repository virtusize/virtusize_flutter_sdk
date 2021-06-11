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
          [InfoCategory.generalFit, InfoCategory.brandSizing]
      );
    } on PlatformException {
      hasSetVirtusizeProps = 'failed to set Virtusize props';
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Has set Virtusize props: $_hasSetVirtusizeProps\n'),
        ),
      ),
    );
  }
}
