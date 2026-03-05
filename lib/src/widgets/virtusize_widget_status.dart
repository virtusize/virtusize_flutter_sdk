sealed class VirtusizeWidgetStatus {}

class VirtusizeWidgetLoading extends VirtusizeWidgetStatus {}

class VirtusizeWidgetDone extends VirtusizeWidgetStatus {
  final String recommendedText;
  final String recommendedSize;
  VirtusizeWidgetDone({required this.recommendedText, required this.recommendedSize});
}

class VirtusizeWidgetError extends VirtusizeWidgetStatus {
  final Object error;
  VirtusizeWidgetError({required this.error});
}
