import 'package:flutter/material.dart';
import 'dart:async';
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  /// Add the following code before calling runApp
  WidgetsFlutterBinding.ensureInitialized();
  await VirtusizeSDK.instance.setVirtusizeParams(
    // Only the API key is required
    apiKey: '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
    // For using the Order API, a user ID is also required. (can be set later)
    userId: '123',
    // By default, the Virtusize environment will be set to VSEnvironment.global
    env: VSEnvironment.japan,
    // By default, the initial language will be set according to the Virtusize environment
    language: VSLanguage.en,
    // By default, ShowSGI is false
    showSGI: true,
    // By default, Virtusize allows all possible languages
    allowedLanguages: [VSLanguage.en, VSLanguage.jp],
    // By default, Virtusize displays all possible info categories in the Product Details tab
    detailsPanelCards: [VSInfoCategory.generalFit, VSInfoCategory.brandSizing],
    // By default, Virtusize does not show SNS buttons
    showSNSButtons: true,
    // Target the specific environment branch by its name
    branch: null,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// Refer to the code in the HomeScreen to see how to set up your product info and the Virtusize widgets
      home: HomeScreen(),
    );
  }
}
