import 'virtusize_model.dart';

class Product extends VirtusizeModel {
  Product(data) : super(data);

  String get imageType => decodedData["imageType"];

  String get imageUrl  => decodedData["imageUrl"];
}