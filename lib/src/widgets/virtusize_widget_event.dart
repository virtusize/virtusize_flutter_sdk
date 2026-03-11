sealed class VirtusizeWidgetState {}

class VirtusizeWidgetCompleted extends VirtusizeWidgetState {
  final String recommendedText;
  final String recommendedSize;

  VirtusizeWidgetCompleted({required this.recommendedText,required this.recommendedSize});
}

class VirtusizeWidgetLoading extends VirtusizeWidgetState {
  VirtusizeWidgetLoading();
}

class VirtusizeWidgetError extends VirtusizeWidgetState {
  final Object error;
  VirtusizeWidgetError({required this.error});
}