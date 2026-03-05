sealed class VirtusizeStatus {}

class VirtusizeWaiting extends VirtusizeStatus {}

class VirtusizeLoading extends VirtusizeStatus {}

class VirtusizeDone extends VirtusizeStatus {
  final String recommendedText;
  final String recommendedSize;
  VirtusizeDone({required this.recommendedText, required this.recommendedSize});
}

class VirtusizeError extends VirtusizeStatus {
  final Object error;
  VirtusizeError({required this.error});
}
