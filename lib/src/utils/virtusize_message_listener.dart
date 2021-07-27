import '../models/product_data_check.dart';

/// A callback type for receiving the names of the events from Native
typedef VSEventCallback = void Function(String eventName);

/// A callback type for receiving the Virtusize errors from Native
typedef VSErrorCallback = void Function(dynamic error);

/// A callback type for receiving the product data check result from Native
typedef ProductDataCheckSuccessCallback = void Function(ProductDataCheck productDataCheck);

/// A callback type for receiving the product data check exception from Native
typedef ProductDataCheckErrorCallback = void Function(Exception exception);

/// This Virtusize message listener can receive Virtusize specific messages from Native
class VirtusizeMessageListener {
  VSEventCallback vsEvent;
  VSErrorCallback vsError;
  ProductDataCheckSuccessCallback productDataCheckSuccess;
  ProductDataCheckErrorCallback productDataCheckError;

  VirtusizeMessageListener({this.vsEvent, this.vsError, this.productDataCheckSuccess, this.productDataCheckError});
}