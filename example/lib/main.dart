import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_virtusize_sdk/flutter_virtusize_sdk.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  /// Add the following code before running your app
  WidgetsFlutterBinding.ensureInitialized();
  VirtusizePlugin.instance.setVirtusizeParams(
      // Only the API key is required
      apiKey: '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
      // For using the Order API, a user ID is required. You can also set the user ID later
      userId: '123',
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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        /// Refer to the code in the HomeScreen to see how to set up your product info and the Virtusize widgets
        home: HomeScreen()
    );
  }
}
