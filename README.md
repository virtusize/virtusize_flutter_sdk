# Virtusize Flutter SDK

[![pub package](https://img.shields.io/pub/v/virtusize_flutter_sdk.svg)](https://pub.dev/packages/virtusize_flutter_sdk)

A Flutter [plugin](https://flutter.dev/developing-packages/) that wraps Virtusize Native SDKs for [Android](https://github.com/virtusize/integration_android) & [iOS](https://github.com/virtusize/integration_ios).



## Table of Contents

- [Introduction](#introduction)

- [Requirements](#requirements)

- [Usage](#usage)

- [Setup](#setup)

  - [Android](#1-android)
  - [Flutter](#2-flutter)
    - [Initialization](#1-initialization)
    - [Set Up Product Details](#2-set-up-product-details)
    - [Implement VirtusizeMessageHandler (Optional)](#3-implement-virtusizemessagehandler-optional)

- [Implement Virtusize Widgets](#implement-virtusize-widgets)
  - [Virtusize Button](#1-virtusize-button)
  - [Virtusize InPage](#2-virtusize-inpage)
    - [InPage Standard](#2-inpage-standard)
    - [InPage Mini](#3-inpage-mini)

- [The Order API](#the-order-api)
  - [Initialization](#1-initialization-1)
  - [Create a *VirtusizeOrder* object for order data](#2-create-a-virtusizeorder-object-for-order-data)
  - [Send an Order](#3-send-an-order)
  
- [Example](#example)

- [License](#license)



## Introduction

Virtusize helps retailers to illustrate the size and fit of clothing, shoes and bags online, by letting customers compare the measurements of an item they want to buy (on a retailer's product page) with an item that they already own (a reference item). This is done by comparing the silhouettes of the retailer's product with the silhouette of the customer's reference Item. Virtusize is a widget which opens when clicking on the Virtusize button, which is located next to the size selection on the product page.

Read more about Virtusize at https://www.virtusize.com

You will need a unique API key and an Admin account, only available to Virtusize customers. Contact our sales team to become a customer.

**This is the integration for Flutter apps only.** For web integration, refer to the developer documentation on https://developers.virtusize.com



## Requirements

- **iOS 10.3+**
  
  Specify the iOS version at least `10.3` in `ios/Podfile`:
  ```
  platform :ios, '10.3'
  ```
  
- **Android 5.0+ (API Level 21+)**
  
  Set the `minSdkVersion` to at least `21` in `android/app/build.gradle`:
  ```gradle
  android {
    defaultConfig {
        minSdkVersion 21
    }
  }
  ```



## Usage 

1. Add `virtusize_flutter_sdk` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

    ```yaml
    dependencies:
      virtusize_flutter_sdk: ^1.0.0
    ```


2. Run `flutter pub get` in your terminal, or click `Pub get` in IntelliJ or Android Studio.



## Setup

### 1. Android

1. Starting from API 30, Android requires package visibility in your AndroidManifest.xml to open URLs in an app.

    To be able to open URLs for the SDK, add the required `<queries>` element to the `AndroidManifest.xml`.
    
    ```xml
    <queries>
    <intent>
     <action android:name="android.intent.action.VIEW" />
     <data android:scheme="https" />
    </intent>
    </queries>
    ```

2. To be able to open the Virtusize webview in a Fragment for the SDK, inherit from **FlutterFragmentActivity** instead of FlutterActivity in the `android/app/src/main/MainActivity`.
   
    ```diff
    - import io.flutter.embedding.android.FlutterActivity
    + import io.flutter.embedding.android.FlutterFragmentActivity
    
    - class MainActivity: FlutterActivity() {
    + class MainActivity: FlutterFragmentActivity() {
    }
    ```



### 2. Flutter

#### (1) Initialization

Use the `VirtusizeSDK.instance.setVirtusizeParams` function to set up the Virtusize parameters before calling runApp.

```dart
import 'package:virtusize_flutter_sdk/virtusize_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VirtusizeSDK.instance.setVirtusizeParams(
      // Only the API key is required
      apiKey: '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
      // For using the Order API, a user ID is also required. (can be set later)
      userId: '123',
      // By default, the Virtusize environment will be set to VSEnvironment.global
      env: VSEnvironment.staging,
      // By default, the initial language will be set according to the Virtusize environment
      language: VSLanguage.jp,
      // By default, ShowSGI is false
      showSGI: true,
      // By default, Virtusize allows all possible languages
      allowedLanguages: [VSLanguage.en, VSLanguage.jp],
      // By default, Virtusize displays all possible info categories in the Product Details tab
      detailsPanelCards: [VSInfoCategory.generalFit, VSInfoCategory.brandSizing]
  );

  runApp(MyApp());
}
```

Possible argument configuration is shown in the following table:

| Argument          | Type                   | Example                                                 | Description                                                  | Required                                                     |
| ----------------- | ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| apiKey            | String                 | "api_key"                                               | A unique API key is provided to each Virtusize client.       | Yes                                                          |
| userId            | String                 | "123"                                                   | Passed from the client if the user is logged into the client's app. | Yes, if the Order API is used.                               |
| env               | VSEnvironment          | VSEnvironment.staging                                   | The environment is the region you are running the integration from, either `VSEnvironment.staging`,  `VSEnvironment.global`, `VSEnvironment.japan` or `VSEnvironment.korea`. | No. By default, the Virtusize environment will be set to `VSEnvironment.global`. |
| language          | VSLanguage             | VSLanguage.jp                                           | Sets the initial language that the integration will load in. The possible values are `VSLanguage.en`, `VSLanguage.jp` and `VSLanguage.kr` | No. By default, the initial language will be set based on the Virtusize environment. |
| showSGI           | bool                   | true                                                    | Determines whether the integration should use SGI flow for users to add user generated items to their wardrobe. | No. By default, showSGI is set to false.                     |
| allowedLanguages  | List<`VSLanguage`>     | [VSLanguage.en, VSLanguage.jp]                          | The languages which the user can switch to using the Language Selector | No. By default, the integration allows all possible languages to be displayed, including English, Japanese and Korean. |
| detailsPanelCards | List<`VSInfoCategory`> | [VSInfoCategory.generalFit, VSInfoCategory.brandSizing] | The info categories which will be display in the Product Details tab. Possible categories are: `VSInfoCategory.modelInfo`, `VSInfoCategory.generalFit`, `VSInfoCategory.brandSizing` and `VSInfoCategory.material` | No. By default, the integration displays all the possible info categories in the Product Details tab. |



#### (2) Set Up Product Details

In the `initState` of your product page widget, you will need to set up the product details:

- Pass an `exernalId` that will be used to reference the product in the Virtusize server
- Pass an `imageURL`  for the product image

```dart
@override
void initState() {
    super.initState();

    VirtusizeSDK.instance.setProduct(
        // Set the product's external ID
        externalId: 'vs_dress',
        // Set the product image URL
        imageURL: 'http://www.image.com/goods/12345.jpg'
    );
}
```



#### (3) Implement VirtusizeMessageHandler (Optional)

You can register a `VirtusizeMessageListener` to listen for events and the `ProductDataCheck` result from Virtusize. 

All the arugments for the `VirtusizeSDK.instance.setVirtusizeMessageListener` function are optional.

```dart
@override
void initState() {
    super.initState();

    VirtusizeSDK.instance.setVirtusizeMessageListener(
        VirtusizeMessageListener(
            vsEvent: (eventName) {
        				print("Virtusize event: $eventName");
      			}, vsError: (error) {
        				print("Virtusize error: $error");
      			}, productDataCheckSuccess: (productDataCheck) {
        				print('ProductDataCheck success: $productDataCheck');
      			}, productDataCheckError: (error) {
        				print('ProductDataCheck error: $error');
      			}
       )
    );
}
```



## Implement Virtusize Widgets

After setting up the SDK, add a `Virtusize` widget to allow your customers to find their ideal size.

Virtusize's Flutter SDK provides two main UI widgets for clients to use:

### 1. Virtusize Button

#### (1) Introduction

VirtusizeButton is the simplest UI Button for our SDK. It opens our application in a web view to support customers finding the right size.



#### (2) Default Styles

There are two default styles of the Virtusize Button in our Virtusize SDK.

| Teal Theme                                                   | Black Theme                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [![img](https://user-images.githubusercontent.com/7802052/92671785-22817a00-f352-11ea-8ce9-6b4f7fcb43c4.png)](https://user-images.githubusercontent.com/7802052/92671785-22817a00-f352-11ea-8ce9-6b4f7fcb43c4.png) | [![img](https://user-images.githubusercontent.com/7802052/92671771-172e4e80-f352-11ea-8443-dcb8b05f5a07.png)](https://user-images.githubusercontent.com/7802052/92671771-172e4e80-f352-11ea-8443-dcb8b05f5a07.png) |

If you like, you can also customize the button style.



#### (3) Usage

- **VirtusizeButton.vsStyle**({VirtusizeStyle style = VirtusizeStyle.Black, Widget child})

  Create a `VirtusizeButton` widget with the default Virtusize style

  ```dart
  // A `VirtusizeButton` widget with default `Black` style
  VirtusizeButton.vsStyle()
    
  // A `VirtusizeButton` widget with `Teal` style and a custom `Text` widget
  VirtusizeButton.vsStyle(
      style: VirtusizeStyle.Teal,
      child: Text("Custom Text")
  )
  ```
  
  
  
  <u>or</u> create a `VirtusizeButton` widget with your custom button widget:

- **VirtusizeButton**({required Widget child})

  ```dart
  // A `VirtusizeButton` widget with a custom `ElevatedButton` widget
  VirtusizeButton(
      child: ElevatedButton(
        child: Text('Custom Button'), 
        // Implement the `OnPressed` callback with the `VirtusizePlugin.instance.openVirtusizeWebView` function if you have customized the button
        onPressed: VirtusizeSDK.instance.openVirtusizeWebView
      )
  )
  ```



### 2. Virtusize InPage

#### (1) Introduction

Virtusize InPage is a button that behaves like a start button for our service. The button also behaves as a fitting guide that supports people to find the right size.

##### InPage types

There are two types of InPage in our Virtusize SDK.

| InPage Standard                                              | InPage Mini                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [![InPageStandard](https://user-images.githubusercontent.com/7802052/92671977-9cb1fe80-f352-11ea-803b-5e3cb3469be4.png)](https://user-images.githubusercontent.com/7802052/92671977-9cb1fe80-f352-11ea-803b-5e3cb3469be4.png) | [![InPageMini](https://user-images.githubusercontent.com/7802052/92671979-9e7bc200-f352-11ea-8594-ed441649855c.png)](https://user-images.githubusercontent.com/7802052/92671979-9e7bc200-f352-11ea-8594-ed441649855c.png) |

⚠️**Caution**⚠️

1. InPage cannot be implemented together with the Virtusize button. Please pick either InPage or Virtusize button for your online shop.
2. InPage Mini must always be used in combination with InPage Standard.



#### (2) InPage Standard

##### A. Usage

- **VirtusizeInPageStandard.vsStyle**({VirtusizeStyle style = VirtusizeStyle.Black, double horizontalMargin = 16})

  Create a `VirtusizeInPageStandard` widget with the default Virtusize style and with the ability to change the horizontal margin.

  ```dart
  // A `VirtusizeInPageStandard` widget with default `Black` style and a default horizontal margin of `16` 
  VirtusizeInPageStandard.vsStyle()
    
  // A `VirtusizeInPageStandard` widget with `Teal` style and a horizontal margin of `32`
  VirtusizeInPageStandard.vsStyle(
      style: VirtusizeStyle.Teal,
      horizontalMargin: 32
  )
  ```

  

  <u>or</u> create a `VirtusizeInPageStandard` widget with the ability to change the button background color and the horizontal margin:

- **VirtusizeInPageStandard**({Color buttonBackgroundColor = VSColors.vsGray900, double horizontalMargin = 16})

  ```dart
  // A `VirtusizeInPageStandard` widget with a default `VSColors.vsGray900` button background color and a default horizontal margin of `16`
  VirtusizeInPageStandard()
  
  // A `VirtusizeInPageStandard` widget with a `Colors.amber` button background color and a horizontal margin of `32`
  VirtusizeInPageStandard(
      buttonBackgroundColor: Colors.amber, 
      horizontalMargin: 32
  )
  ```



##### B. Design Guidelines

- ##### Default Designs

  There are two default design variations.

  | Teal Theme                                                   | Black Theme                                                  |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![InPageStandardTeal](https://user-images.githubusercontent.com/7802052/92672035-b9e6cd00-f352-11ea-9e9e-5385a19e96da.png)](https://user-images.githubusercontent.com/7802052/92672035-b9e6cd00-f352-11ea-9e9e-5385a19e96da.png) | [![InPageStandardBlack](https://user-images.githubusercontent.com/7802052/92672031-b81d0980-f352-11ea-8b7a-564dd6c2a7f1.png)](https://user-images.githubusercontent.com/7802052/92672031-b81d0980-f352-11ea-8b7a-564dd6c2a7f1.png) |

- ##### Layout Variations

  Here are some possible layouts

  | 1 thumbnail + 2 lines of message                             | 2 thumbnails + 2 lines of message                            |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![1 thumbnail + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399368-5e879300-1930-11eb-8b77-b49e06813550.png)](https://user-images.githubusercontent.com/7802052/97399368-5e879300-1930-11eb-8b77-b49e06813550.png) | [![2 thumbnails + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399370-5f202980-1930-11eb-9a2d-7b71714aa7b4.png)](https://user-images.githubusercontent.com/7802052/97399370-5f202980-1930-11eb-9a2d-7b71714aa7b4.png) |
  | **1 thumbnail + 1 line of message**                          | **2 animated thumbnails + 2 lines of message**               |
  | [![1 thumbnail + 1 line of message](https://user-images.githubusercontent.com/7802052/97399373-5f202980-1930-11eb-81fe-9946b656eb4c.png)](https://user-images.githubusercontent.com/7802052/97399373-5f202980-1930-11eb-81fe-9946b656eb4c.png) | [![2 animated thumbnails + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399355-59c2df00-1930-11eb-8a52-292956b8762d.gif)](https://user-images.githubusercontent.com/7802052/97399355-59c2df00-1930-11eb-8a52-292956b8762d.gif) |

- ##### Recommended Placement

  - Near the size table
  - In the size info section

  ![img](https://user-images.githubusercontent.com/7802052/92672185-15b15600-f353-11ea-921d-397f207cf616.png)

- ##### UI customization

  - **You can:**
    - change the background color of the CTA button as long as it passes **[WebAIM contrast test](https://webaim.org/resources/contrastchecker/)**.
    - change the width of InPage so it fits your application width.
  - **You cannot:**
    - change interface components such as shapes and spacing.
    - change the font.
    - change the CTA button shape.
    - change messages.
    - change or hide the box shadow.
    - hide the footer that contains VIRTUSIZE logo and Privacy Policy text link.



#### (3) InPage Mini

This is a mini version of InPage that you can place in your application. The discreet design is suitable for layouts where customers are browsing product images and size tables.



##### A. Usage

- **VirtusizeInPageMini.vsStyle**({VirtusizeStyle style = VirtusizeStyle.Black, double horizontalMargin = 16})

  Create a `VirtusizeInPageMini` widget with the default Virtusize style and with the ability to change the horizontal margin.

  ```dart
  // A `VirtusizeInPageMini` widget with default `Black` style and a default horizontal margin of `16` 
  VirtusizeInPageMini.vsStyle()
    
  // A `VirtusizeInPageMini` widget with `Teal` style and a default horizontal margin of `16`
  VirtusizeInPageMini.vsStyle(
      style: VirtusizeStyle.Teal
  )
  ```
  
  
  
  <u>or</u> create a `VirtusizeInPageMini` widget with the ability to change the background color and the horizontal margin:

- **VirtusizeInPageMini**({Color backgroundColor = VSColors.vsGray900, double horizontalMargin = 16})

  ```dart
  // A `VirtusizeInPageMini` widget with a default `VSColors.vsGray900` background color and a default horizontal margin of `16`
  VirtusizeInPageMini()
  
  // A `VirtusizeInPageMini` widget with a `Colors.blue` background color and a default horizontal margin of `16`
  VirtusizeInPageMini(
      backgroundColor: Colors.blue
  )
  ```



##### B. Design Guidelines

- ##### Default designs

  There are two default design variations.

  | Teal Theme                                                   | Black Theme                                                  |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![InPageMiniTeal](https://user-images.githubusercontent.com/7802052/92672234-2d88da00-f353-11ea-99d9-b9e9b6aa5620.png)](https://user-images.githubusercontent.com/7802052/92672234-2d88da00-f353-11ea-99d9-b9e9b6aa5620.png) | [![InPageMiniBlack](https://user-images.githubusercontent.com/7802052/92672232-2c57ad00-f353-11ea-80f6-55a9c72fb0b5.png)](https://user-images.githubusercontent.com/7802052/92672232-2c57ad00-f353-11ea-80f6-55a9c72fb0b5.png) |

- ##### Recommended Placements

  | Underneath the product image                                 | Underneath or near the size table                            |
  | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![img](https://user-images.githubusercontent.com/7802052/92672261-3c6f8c80-f353-11ea-995c-ede56e0aacc3.png)](https://user-images.githubusercontent.com/7802052/92672261-3c6f8c80-f353-11ea-995c-ede56e0aacc3.png) | [![img](https://user-images.githubusercontent.com/7802052/92672266-40031380-f353-11ea-8f63-a67c9cf46c68.png)](https://user-images.githubusercontent.com/7802052/92672266-40031380-f353-11ea-8f63-a67c9cf46c68.png) |

- ##### Default Fonts

  - Japanese
    - Noto Sans CJK JP
    - 12sp (Message)
    - 10sp (Button)
  - Korean
    - Noto Sans CJK KR
    - 12sp (Message)
    - 10sp (Button)
  - English
    - Proxima Nova
    - 14sp (Message)
    - 12sp (Button)

- ##### UI customization

  - You can:
    - change the background color of the bar as long as it passes **[WebAIM contrast test](https://webaim.org/resources/contrastchecker/)**.
  - You cannot:
    - change the font.
    - change the CTA button shape.
    - change messages.



## The Order API

The order API enables Virtusize to show your customers the items they have recently purchased as part of their `Purchase History`, and to use those items to compare with new items they want to buy.

#### 1. Initialization

Ensure that the **user ID** is set before sending orders to Virtusize. You can set up the user ID:

while setting the Virtusize parameters using `VirtusizeSDK.instance.setVirtusizeParams`

or

anywhere before calling the `VirtusizeSDK.instance.sendOrder` function

```dart
// Use the `VirtusizeSDK.instance.setVirtusizeParams` to set the user ID
VirtusizeSDK.instance.setVirtusizeParams(
    apiKey: '15cc36e1d7dad62b8e11722ce1a245cb6c5e6692',
    userId: '123',
    ...
);

// Use the `VirtusizeSDK.instance.setUserId` before sending an order
VirtusizeSDK.instance.setUserId("123456");
```



#### 2. Create a *VirtusizeOrder* object for order data

The ***VirtusizeOrder*** object gets passed to the `VirtusizeSDK.instance.sendOrder` function, and has the following attributes:

***Note:*** * means the argument is required

**VirtusizeOrder**

| Argument         | Type                | Example             | Description                         |
| ---------------- | ------------------------ | ------------------- | ----------------------------------- |
| externalOrderId* | String                   | "20200601586"       | The order ID provided by the client |
| items*           | List<`VirtusizeOrderItem`> | See the table below | A list of the order items.          |

**VirtusizeOrderItem**

| Argument           | Type   | Example                              | Description                                                  |
| ------------------ | ------ | ------------------------------------ | ------------------------------------------------------------ |
| externalProductId* | String | "A001"                               | The external product ID provided by the client. It must be unique for each product. |
| size*              | String | "S", "M", etc.                       | The name of the size                                         |
| sizeAlias          | String | "Small", "Large", etc.               | The alias of the size is added if the size name is not identical to the one from the product page |
| variantId          | String | "A001_SIZES_RED"                     | The variant ID is set on the product SKU, color, or size (if there are several options) |
| imageURL*          | String | "http://images.example.com/coat.jpg" | The image URL of the item                                    |
| color              | String | "RED", "R', etc.                     | The color of the item                                        |
| gender             | String | "W", "Women", etc.                   | An identifier for the gender                                 |
| unitPrice*         | double | 5100.00                              | The product price that is a double number with a maximum of 12 digits and 2 decimals (12, 2) |
| currency*          | String | "JPY", "KRW", "USD", etc.            | Currency code                                                |
| quantity*          | int    | 1                                    | The number of items purchased. If it's not passed, it will default to 1 |
| url                | String | "http://example.com/products/A001"   | The URL of the product page. Please make sure this is a URL that users can access |

**Example**

```dart
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
            url: "http://example.com/products/A001"
        )
    ]
);
```



#### 3. Send an Order

Call the `VirtusizeSDK.instance.sendOrder` function when the user places an order.

The `onSuccess` and `onError` callbacks are optional.

```dart
VirtusizeSDK.instance.sendOrder(
    order: order,
    // The `onSuccess` callback is optional and is called when the app has successfully sent the order
    onSuccess: (sentOrder) {
        print("Successfully sent the order $sentOrder");
    },
    // The `onError` callback is optional and gets called when an error occurs while the app is sending the order
    onError: (error) {
        print(error);
    }
);
```



## Example

https://github.com/virtusize/virtusize_flutter_sdk/tree/main/example



## License

Copyright (c) 2021-present Virtusize CO LTD ([https://www.virtusize.jp](https://www.virtusize.jp/))