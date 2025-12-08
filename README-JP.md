# Virtusize Flutter SDK

[![pub package](https://img.shields.io/pub/v/virtusize_flutter_sdk.svg)](https://pub.dev/packages/virtusize_flutter_sdk)

[English](README.md)

A Flutter [plugin](https://flutter.dev/developing-packages/) that wraps Virtusize Native SDKs for [Android](https://github.com/virtusize/integration_android) & [iOS](https://github.com/virtusize/integration_ios).


## Table of Contents

- [はじめに](#はじめに)

- [対応バージョン](#対応バージョン)

- [使用方法](#使用方法)

- [セットアップ](#セットアップ)
    - [Android](#1-android)
    - [Flutter](#2-flutter)
        - [はじめに](#1-はじめに)
        - [Virtusizeにて商品詳細をロードする](#2-virtusizeにて商品詳細をロードする)
        - [VirtusizeMessageHandlerの実装する（オプション）](#3-virtusizemessagehandlerを実装するオプション)
    
- [SNS認証を有効にする](#SNS認証を有効にする)
  - [Android](#1-android)
  - [iOS](#2-ios)

- [Virtusizeウィジェット実装](#virtusizeウィジェット実装)
    - [バーチャサイズ・ボタン（Virtusize Button）](#1-バーチャサイズボタンvirtusize-button)
    - [バーチャサイズ・インページ（Virtuzie InPage）](#2-バーチャサイズインページvirtuzie-inpage)
        - [インページ・スタンダード（InPage Standard）](#2-インページスタンダードinpage-standard)
        - [インページ・ミニ（InPage Mini）](#3-インページミニinpage-mini)

- [Order API](#order-api)
    - [はじめに](#1-はじめに)
    - [注文データのVirtusizeOrder オブジェクトを作成](#2-注文データのvirtusizeorder-オブジェクトを作成)
    - [注文情報の送信](#3-注文情報の送信)

- [Example](#example)

- [License](#license)



## はじめに

バーチャサイズは商品詳細ページにあるサイズ情報を元に、アイテムのサイズ感をシルエット化しお客様が購入されたい商品をオンライン上で比較しやすいようサポートをしてます。

詳しくはこちらをご確認ください。[https://www.virtusize.com](https://www.virtusize.com/)

実装作業を始められる前にバーチャサイズの御社ご担当者に「API キー」と「ストア名」をお訊ねください。

> **こちらは Flutter用実装ガイドです。** Webの実装は[https://developers.virtusize.com](https://developers.virtusize.com/)をご確認ください。



## 対応バージョン

- **iOS 14.0+**

  iOS バージョン`14.0`以上をご利用されているか`ios/Podfile`にてご確認ください。

  ```
  platform :ios, '14.0'
  ```
  
- **Android 5.0+ (API Level 21+)**

  `android/app/build.gradle` を `21`以上をご利用されているかご確認の上、`minSdkVersion` を設定ください。
  
  ```gradle
  android {
    defaultConfig {
        minSdkVersion 21
    }
  }
  ```



## 使用方法

1. [pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages)に`virtusize_flutter_sdk`を追加。

    ```yaml
    dependencies:
      virtusize_flutter_sdk: ^2.2.4
    ```


2. `flutter pub get` をターミナルで実行または IntelliJ / Android Studio 内`Pub get`をクリックください。



## セットアップ

### 1. Android

(1) Proguardを使用している場合は、以下のルールをProguardルールファイルに追加してください：

```
-keep class com.virtusize.android.**
```

(2) SDKでVirtusizeのWebViewをFragment内で開けるようにするには、`android/app/src/main/MainActivity`でFlutterActivityの代わりに**FlutterFragmentActivity**を継承してください。

    ```diff
    - import io.flutter.embedding.android.FlutterActivity
    + import io.flutter.embedding.android.FlutterFragmentActivity
    
    - class MainActivity: FlutterActivity() {
    + class MainActivity: FlutterFragmentActivity() {
    }
    ```


### 2. Flutter

#### (1) はじめに

runAppを実行する前に、`VirtusizeSDK.instance.setVirtusizeParams`関数を使用してVirtusizeパラメーターを設定します。

```dart
import 'package:virtusize_flutter_sdk/virtusize_flutter_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VirtusizeSDK.instance.setVirtusizeParams(
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
    detailsPanelCards: [VSInfoCategory.generalFit, VSInfoCategory.brandSizing],
    // By default, Virtusize does not show SNS buttons
    showSNSButtons: true,
    // Target the specific environment branch by its name
    branch: 'branch-name',
  );

  runApp(MyApp());
}
```

可能な引数構成を次の表に示します。

| データ形式        | タイプ                 | 例                                                      | 説明                                                         | 必須設定                                                     |
| ----------------- | ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| apiKey            | String                 | 'api_key'                                               | 担当者が用意した「API キー」遠設定ください。                 | Yes                                                          |
| userId            | String                 | '123'                                                   | ユーザーがクライアントのアプリにログインしている場合、クライアントから渡されます。 | Yes,OrderAPIが使用されている場合。                           |
| env               | VSEnvironment          | VSEnvironment.staging                                   | 設定環境は、統合を実行している地域のいずれか<br />`VSEnvironment.staging`,  `VSEnvironment.global`, `VSEnvironment.japan` または `VSEnvironment.korea`。 | No. デフォルトでは、Virtusize環境は次のように設定されます`VSEnvironment.global`。 |
| language          | VSLanguage             | VSLanguage.jp                                           | 統合がロードされる初期言語を設定します。可能な値は次のとおりです。<br />`VSLanguage.en`, `VSLanguage.jp` および  `VSLanguage.kr` | No. デフォルトでは、初期言語はVirtusize環境に基づいて設定されます。 |
| showSGI           | bool                   | true                                                    | ユーザーが生成したアイテムをワードローブに追加する方法として、SGIを取得の上、SGIフローを使用するかどうかを決定します。 | No. デフォルトではShowSGIはfalseに設定されています。         |
| allowedLanguages  | List<`VSLanguage`>     | [VSLanguage.en, VSLanguage.jp]                          | ユーザーが言語選択ボタンより選択できる言語。                 | 特になし。デフォルトでは、英語、日本語、韓国語など、表示可能なすべての言語が表示されるようになっています。 |
| detailsPanelCards | List<`VSInfoCategory`> | [VSInfoCategory.generalFit, VSInfoCategory.brandSizing] | 商品詳細タブに表示する情報のカテゴリ。表示可能カテゴリは以下：<br />`VSInfoCategory.modelInfo`, `VSInfoCategory.generalFit`, `VSInfoCategory.brandSizing` および`VSInfoCategory.material` | No. デフォルトでは、商品詳細タブに表示可能なすべての情報カテゴリが表示されます。 |
| showSNSButtons           | bool                   | true                                                    | 統合時にユーザーにSNSボタンを表示するかどうかを決定します。 | No.デフォルトでは、統合時にSNSボタンは無効になっています。                     |
| branch            | String                 | 'branch-name'                                                   | 特定の環境ブランチを対象とします。 | デフォルトでは、本番環境が対象になります。`staging` を指定するとステージング環境が対象になります。`<branch-name>` を指定すると、特定のブランチが対象になります。                              |
| showPrivacyPolicy | Boolean                           | showShowPrivacyPolicy: true                   | プライバシー ポリシーをユーザーに表示するかどうかを制御します。                                           | No. デフォルトでは、プライバシー ポリシーが表示されます。                                                               |


#### (2) Virtusizeにて商品詳細をロードする

商品詳細ページウィジェットの`initState`で、`VirtusizeSDK.instance.loadVirtusize`を使用してVirtusizeウィジェットにデータを入力する必要があります。

- `VirtusizeClientProduct`オブジェクトを作成して以下情報を設定してください。
    - Virtusizeサーバーで商品詳細をロードするために使用される`exernalId`
    - 商品画像の`imageURL`
- `VirtusizeClientProduct`オブジェクトを`VirtusizeSDK.instance.loadVirtusize`関数に渡します。

```dart
/// Declare a global `VirtusizeClientProduct` variable, 
/// which will be passed to the `Virtusize` widgets in order to bind the product info
VirtusizeClientProduct _product;

@override
void initState() {
    super.initState();

    _product = VirtusizeClientProduct(
        // Set the product's external ID
        externalProductId: 'vs_dress',
        // Set the product image URL
        imageURL: 'https://www.image.com/goods/12345.jpg'
    );

    VirtusizeSDK.instance.loadVirtusize(_product);
}
```

ユーザーが同じ画面を表示しているときに製品を別の製品に更新する場合は、別の`VirtusizeClientProduct`オブジェクトを`_product`に割り当て、`setState()`内の`VirtusizeSDK.instance.loadVirtusize`を使用して製品を再読み込みし、ウィジェットを再構築します。

```dart
setState(() {
    _product = VirtusizeClientProduct(
        externalProductId: 'vs_pants',
        imageURL: 'https://www.image.com/goods/12345.jpg'
    );
    VirtusizeSDK.instance.loadVirtusize(_product);
});
```


#### (3) VirtusizeMessageHandlerを実装する（オプション）

`VirtusizeMessageListener`を登録して、Virtusizeからのイベントと`ProductDataCheck`の結果を確認できます。

`VirtusizeSDK.instance.setVirtusizeMessageListener`関数のすべての引数はオプションです。

```dart
@override
void initState() {
    super.initState();

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
            }
       )
    );
}
```

こちらが翻訳済みの日本語バージョンです（Markdown形式を維持しています）：

---

## 3. SNS認証を有効にする

### 1. Android

SNS認証フローでは、Chrome Custom Tabを開いてユーザーがSNSアカウントでログインできるウェブページを読み込みます。ログインのレスポンスをChrome Custom Tabからアプリに返すためには、カスタムURLスキームを定義する必要があります。

`AndroidManifest.xml` ファイルを編集し、インテントフィルターおよびカスタムURLスキーム用の `<data>` タグを追加してください。

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.your-company.your-app">

    <activity android:name="com.virtusize.android.auth.views.VitrusizeAuthActivity"
        android:launchMode="singleTask" android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />

            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />

            <data android:host="sns-auth" android:scheme="com.your-company.your-app.virtusize" />
        </intent-filter>
    </activity>

</manifest>
```

**❗重要**

1. URLのホストは `sns-auth` である必要があります。
2. URLスキームはアプリのパッケージID（`com.your-company.your-app`）で始まり、**`.virtusize`で終わる**必要があります。また、スキームはすべて**小文字**で定義してください。

### 2. iOS

SNS認証フローでは、SFSafariViewControllerに切り替えて、ユーザーがSNSアカウントでログインできるウェブページを読み込みます。ログインのレスポンスをSFSafariViewControllerからアプリに返すためには、カスタムURLスキームを定義する必要があります。

#### (1) URLタイプの登録

Xcodeで、プロジェクトの **Info** タブをクリックし、**URL Types** を選択します。

新しいURLタイプを追加し、URLスキームと識別子を `com.your-company.your-app.virtusize` に設定してください。

![Screen Shot 2021-11-10 at 21 36 31](https://user-images.githubusercontent.com/7802052/141114271-373fb239-91f8-4176-830b-5bc505e45017.png)

#### (2) アプリケーションのコールバックハンドラーを設定

AppDelegate の `application(_:open:options)` メソッドを実装してください：

```Swift
override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      NotificationCenter.default.post(
        name: Notification.Name("VirtusizeFlutterHandleURL"),
        object: url
      )
      
      return super.application(app, open: url, options: options)
  }
```

**❗重要**

1. URLタイプには、アプリのバンドルIDを含め、**`.virtusize`で終わる**必要があります。
2. 複数のアプリアイデンティティ（ターゲット）がある場合は、それぞれにURLタイプを追加してください。


## Virtusizeウィジェット実装

SDKをセットアップした後、`Virtusize`ウィジェットを追加して、顧客が理想的なサイズを見つけられるようにします。

Virtusize SDKはユーザーが使用するために2つの主要なUIコンポーネントを提供します。:

### 1. バーチャサイズ・ボタン（Virtusize Button）

#### (1) はじめに

VirtusizeButtonはこのSDKの中でもっとシンプルなUIのボタンです。ユーザーが正しいサイズを見つけられるように、ウェブビューでアプリケーションを開きます。



#### (2) デフォルトスタイル

SDKのVirtusizeボタンには2つのデフォルトスタイルがあります。

| Teal Theme                                                   | Black Theme                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [![img](https://user-images.githubusercontent.com/7802052/92671785-22817a00-f352-11ea-8ce9-6b4f7fcb43c4.png)](https://user-images.githubusercontent.com/7802052/92671785-22817a00-f352-11ea-8ce9-6b4f7fcb43c4.png) | [![img](https://user-images.githubusercontent.com/7802052/92671771-172e4e80-f352-11ea-8443-dcb8b05f5a07.png)](https://user-images.githubusercontent.com/7802052/92671771-172e4e80-f352-11ea-8443-dcb8b05f5a07.png) |

もしご希望であれば、ボタンのスタイルもカスタマイズすることができます。



#### (3) 使用方法

- **VirtusizeButton.vsStyle**({required VirtusizeClientProduct product, VirtusizeStyle style = VirtusizeStyle.black, Widget child})

  デフォルトのVirtusizeスタイルで、`VirtusizeSDK.instance.loadVirtusize`関数に渡したものと同じ`VirtusizeClientProduct`オブジェクトを使用して`VirtusizeButton`ウィジェットを作成します。

  ```dart
  // A `VirtusizeButton` widget with default `black` style
  VirtusizeButton.vsStyle(product: _product)
    
  // A `VirtusizeButton` widget with `teal` style and a custom `Text` widget
  VirtusizeButton.vsStyle(
      product: _product,
      style: VirtusizeStyle.teal,
      child: Text("Custom Text")
  )
  ```



<u>または</u>、カスタムボタンウィジェットを使用して`VirtusizeButton`ウィジェットを作成します。

- **VirtusizeButton**({required VirtusizeClientProduct product, required Widget child})

  ```dart
  // A `VirtusizeButton` widget with a custom `ElevatedButton` widget
  VirtusizeButton(
      product: _product,
      child: ElevatedButton(
        child: Text('Custom Button'), 
        // Implement the `onPressed` callback with the `VirtusizePlugin.instance.openVirtusizeWebView` function if you have customized the button
        onPressed: () => VirtusizeSDK.instance.openVirtusizeWebView(_product))
      )
  )
  ```



### 2. バーチャサイズ・インページ（Virtuzie InPage）

#### (1) はじめに

Virtusize InPageは、サービスのスタートボタンのように動作するボタンです。こちらは、ユーザーが一目で適切なサイズがわかるフィッティングガイドとしても機能します。

##### InPage types

Virtusize SDKには2種類のInPageがあります。

| InPage Standard                                              | InPage Mini                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [![InPageStandard](https://user-images.githubusercontent.com/7802052/92671977-9cb1fe80-f352-11ea-803b-5e3cb3469be4.png)](https://user-images.githubusercontent.com/7802052/92671977-9cb1fe80-f352-11ea-803b-5e3cb3469be4.png) | [![InPageMini](https://user-images.githubusercontent.com/7802052/92671979-9e7bc200-f352-11ea-8594-ed441649855c.png)](https://user-images.githubusercontent.com/7802052/92671979-9e7bc200-f352-11ea-8594-ed441649855c.png) |

⚠️**注意**⚠️

1. InPageをVirtusizeボタンと一緒に実装することはできません。オンラインショップのInPageまたはVirtusizeボタンを選択してください。
2. InPage Miniは、常にInPageStandardと組み合わせて使用する必要があります。



#### (2) インページ・スタンダード（InPage Standard）

##### A. 使用方法

- **VirtusizeInPageStandard.vsStyle**({required VirtusizeClientProduct product, VirtusizeStyle style = VirtusizeStyle.black, double horizontalMargin = 16})

  `VirtusizeSDK.instance.loadVirtusize`関数に渡した同じ`VirtusizeClientProduct`オブジェクトを使用して、デフォルトのVirtusizeスタイルとhorizontal marginを変更する機能を備えた`VirtusizeInPageStandard`ウィジェットを作成します。

  ```dart
  // A `VirtusizeInPageStandard` widget with default `black` style and a default horizontal margin of `16` 
  VirtusizeInPageStandard.vsStyle(product: _product)
    
  // A `VirtusizeInPageStandard` widget with `teal` style and a horizontal margin of `32`
  VirtusizeInPageStandard.vsStyle(
      product: _product,
      style: VirtusizeStyle.teal,
      horizontalMargin: 32
  )
  ```



<u>または</u>、ボタンのbackground colorとhorizontal marginを変更する機能を備えた`VirtusizeInPageStandard`ウィジェットを作成します。

- **VirtusizeInPageStandard**({required VirtusizeClientProduct product, Color buttonBackgroundColor = VSColors.vsGray900, double horizontalMargin = 16})

  ```dart
  // A `VirtusizeInPageStandard` widget with a default `VSColors.vsGray900` button background color and a default horizontal margin of `16`
  VirtusizeInPageStandard(product: _product)
  
  // A `VirtusizeInPageStandard` widget with a `Colors.amber` button background color and a horizontal margin of `32`
  VirtusizeInPageStandard(
      product: _product,
      buttonBackgroundColor: Colors.amber, 
      horizontalMargin: 32
  )
  ```



##### B. デザインガイドライン

- ##### デフォルトのデザイン

  デフォルトのデザインバリエーションは2つあります。

  | Teal Theme                                                   | Black Theme                                                  |
    | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![InPageStandardTeal](https://user-images.githubusercontent.com/7802052/92672035-b9e6cd00-f352-11ea-9e9e-5385a19e96da.png)](https://user-images.githubusercontent.com/7802052/92672035-b9e6cd00-f352-11ea-9e9e-5385a19e96da.png) | [![InPageStandardBlack](https://user-images.githubusercontent.com/7802052/92672031-b81d0980-f352-11ea-8b7a-564dd6c2a7f1.png)](https://user-images.githubusercontent.com/7802052/92672031-b81d0980-f352-11ea-8b7a-564dd6c2a7f1.png) |

- ##### レイアウトのバリエーション

  考えられるレイアウトは次のとおりです。

  | 1 thumbnail + 2 lines of message                             | 2 thumbnails + 2 lines of message                            |
    | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![1 thumbnail + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399368-5e879300-1930-11eb-8b77-b49e06813550.png)](https://user-images.githubusercontent.com/7802052/97399368-5e879300-1930-11eb-8b77-b49e06813550.png) | [![2 thumbnails + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399370-5f202980-1930-11eb-9a2d-7b71714aa7b4.png)](https://user-images.githubusercontent.com/7802052/97399370-5f202980-1930-11eb-9a2d-7b71714aa7b4.png) |
  | **1 thumbnail + 1 line of message**                          | **2 animated thumbnails + 2 lines of message**               |
  | [![1 thumbnail + 1 line of message](https://user-images.githubusercontent.com/7802052/97399373-5f202980-1930-11eb-81fe-9946b656eb4c.png)](https://user-images.githubusercontent.com/7802052/97399373-5f202980-1930-11eb-81fe-9946b656eb4c.png) | [![2 animated thumbnails + 2 lines of message](https://user-images.githubusercontent.com/7802052/97399355-59c2df00-1930-11eb-8a52-292956b8762d.gif)](https://user-images.githubusercontent.com/7802052/97399355-59c2df00-1930-11eb-8a52-292956b8762d.gif) |

- ##### 推奨される配置

    - サイズテーブルの近く
    - サイズ情報内

  ![img](https://user-images.githubusercontent.com/7802052/92672185-15b15600-f353-11ea-921d-397f207cf616.png)

- ##### UIのカスタマイズ

    - **できる事**
        - [**WebAIMコントラストテスト**](https://webaim.org/resources/contrastchecker/)を合格した色に限り、CTAボタンの背景色を変更できます。
        - アプリケーションの幅と一致するようInPageの幅を変更できます。
    - **できない事**
        - 形やスペーシングなどのインターフェイスコンポーネントの変更。
        - フォントの変更。
        - CTAボタンの形の変更。
        - メッセージの変更。
        - インページボックス影デザインの変更または非表示切り替え。
        - VIRTUSIZEロゴとプライバシーポリシーのテキストリンクを含むフッター非表示切り替え。



#### (3) インページ・ミニ（InPage Mini）

これは、アプリケーションに配置できるInPageのミニバージョンです。目立たないデザインは、顧客が商品の画像やサイズ表を閲覧しているレイアウトに適しています。



##### A. 使用方法

- **VirtusizeInPageMini.vsStyle**({required VirtusizeClientProduct product, VirtusizeStyle style = VirtusizeStyle.black, double horizontalMargin = 16})

  `VirtusizeSDK.instance.loadVirtusize`関数に渡したものと同じ`VirtusizeClientProduct`オブジェクトを使用して、デフォルトのVirtusizeスタイルとhorizontal marginを変更する機能を備えた`VirtusizeInPageMini`ウィジェットを作成します。

  ```dart
  // A `VirtusizeInPageMini` widget with default `black` style and a default horizontal margin of `16` 
  VirtusizeInPageMini.vsStyle(product: _product)
    
  // A `VirtusizeInPageMini` widget with `teal` style and a default horizontal margin of `16`
  VirtusizeInPageMini.vsStyle(
      product: _product,
      style: VirtusizeStyle.teal
  )
  ```



<u>または</u>、background colorとhorizontal marginを変更する機能を備えた`VirtusizeInPageMini`ウィジェットを作成します。

- **VirtusizeInPageMini**({required VirtusizeClientProduct product, Color backgroundColor = VSColors.vsGray900, double horizontalMargin = 16})

  ```dart
  // A `VirtusizeInPageMini` widget with a default `VSColors.vsGray900` background color and a default horizontal margin of `16`
  VirtusizeInPageMini(product: _product)
  
  // A `VirtusizeInPageMini` widget with a `Colors.blue` background color and a default horizontal margin of `16`
  VirtusizeInPageMini(
      product: _product,
      backgroundColor: Colors.blue
  )
  ```



##### B. デザインガイドライン

- ##### デフォルトのデザイン

  デフォルトのデザインバリエーションは2つあります。

  | Teal Theme                                                   | Black Theme                                                  |
    | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![InPageMiniTeal](https://user-images.githubusercontent.com/7802052/92672234-2d88da00-f353-11ea-99d9-b9e9b6aa5620.png)](https://user-images.githubusercontent.com/7802052/92672234-2d88da00-f353-11ea-99d9-b9e9b6aa5620.png) | [![InPageMiniBlack](https://user-images.githubusercontent.com/7802052/92672232-2c57ad00-f353-11ea-80f6-55a9c72fb0b5.png)](https://user-images.githubusercontent.com/7802052/92672232-2c57ad00-f353-11ea-80f6-55a9c72fb0b5.png) |

- ##### 推奨される配置

  | Underneath the product image                                 | Underneath or near the size table                            |
    | ------------------------------------------------------------ | ------------------------------------------------------------ |
  | [![img](https://user-images.githubusercontent.com/7802052/92672261-3c6f8c80-f353-11ea-995c-ede56e0aacc3.png)](https://user-images.githubusercontent.com/7802052/92672261-3c6f8c80-f353-11ea-995c-ede56e0aacc3.png) | [![img](https://user-images.githubusercontent.com/7802052/92672266-40031380-f353-11ea-8f63-a67c9cf46c68.png)](https://user-images.githubusercontent.com/7802052/92672266-40031380-f353-11ea-8f63-a67c9cf46c68.png) |

- ##### デフォルトのフォント

    - **日本語**
        - Noto Sans CJK JP
        - (Message) Text size: 12
        - (Button) Text size: 10
    - **韓国語**
        - Noto Sans CJK KR
        - (Message) Text size: 12
        - (Button) Text size: 10
    - **英語**
        - Roboto for Android and San Francisco for iOS
        - (Message) Text size: 14
        - (Button) Text size: 12

- ##### UIのカスタマイズ

    - **できる事**
        - [**WebAIMコントラストテスト**](https://webaim.org/resources/contrastchecker/)を合格した色に限り、CTAボタンの背景色を変更できます。
    - **できない事**
        - フォントの変更。
        - CTAボタンの形変更。
        - メッセージの変更。



## Order API

注文APIを使用すると、Virtusizeは、`購入履歴`の一部として最近購入したアイテムを顧客に表示し、それらのアイテムを使用して、購入したい新しいアイテムと比較することができます。

#### 1. はじめに

Virtusizeに注文を送信する前に、**ユーザーID**が設定されていることを確認してください。以下にてユーザーIDを設定できます：

`VirtusizeSDK.instance.setVirtusizeParams`を使用してVirtusizeパラメーターを設定している間

<u>または</u>

`VirtusizeSDK.instance.sendOrder`関数を呼び出す前の任意の場所

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



#### 2. 注文データのVirtusizeOrder オブジェクトを作成

***VirtusizeOrder***オブジェクトは`VirtusizeSDK.instance.sendOrder`関数に渡され、次の属性があります。

***注：***\*は引数が必要であることを意味します。

**VirtusizeOrder**

| データ形式 | タイプ        | 例        | 説明                   |
| ---------------- | ------------------------ | ------------------- | ----------------------------------- |
| externalOrderId* | String                   | "20200601586"       | 御社にてご用意いただいたオーダーID |
| items*           | List<`VirtusizeOrderItem`> | See the table below | オーダー商品リスト |

**VirtusizeOrderItem**

| データ形式         | タイプ | 例                                   | 説明                                                         |
| ------------------ | ------ | ------------------------------------ | ------------------------------------------------------------ |
| externalProductId* | String | "A001"                               | 各商品ユニークIDをご利用ください                             |
| size*              | String | "S", "M", etc.                       | サイズ名称                                                   |
| sizeAlias          | String | "Small", "Large", etc.               | サイズ名が商品ページのものと同一でない場合は、サイズのエイリアスが追加されます |
| variantId          | String | "A001_SIZES_RED"                     | バリアントIDは、製品のSKU、色、またはサイズに設定されます（複数のオプションがある場合） |
| imageURL*          | String | "http://images.example.com/coat.jpg" | 商品画像URL                                                  |
| color              | String | "RED", "R', etc.                     | 色                                                           |
| gender             | String | "W", "Women", etc.                   | 性別                                                         |
| unitPrice*         | double | 5100.00                              | 最大12桁と小数点以下2桁の2桁の製品価格（12、2）              |
| currency*          | String | "JPY", "KRW", "USD", etc.            | 通貨コード                                                   |
| quantity*          | int    | 1                                    | 購入したアイテム数。共有がなかった場合、デフォルトで1になります。 |
| url                | String | "http://example.com/products/A001"   | 商品ページのURL。これがユーザーがアクセスできるURLであることを確認してください。 |

**サンプル例**

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



#### 3. 注文情報の送信

ユーザーが注文するときに、`VirtusizeSDK.instance.sendOrder`関数を呼び出します。

`onSuccess`および`onError`コールバックはオプションです。

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