import '../models/product_data_check.dart';

typedef VSEventCallback = void Function(dynamic event);
typedef VSErrorCallback = void Function(dynamic error);
typedef ProductDataCheckDataCallback = void Function(ProductDataCheck productDataCheck);
typedef ProductDataCheckErrorCallback = void Function(Exception exception);

class VirtusizeMessageListener {
  VSEventCallback vsEvent;
  VSErrorCallback vsError;
  ProductDataCheckDataCallback productDataCheckData;
  ProductDataCheckErrorCallback productDataCheckError;

  VirtusizeMessageListener({this.vsEvent, this.vsError, this.productDataCheckData, this.productDataCheckError});
}