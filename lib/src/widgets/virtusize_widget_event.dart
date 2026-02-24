sealed class VirtusizeWidgetEvent {}

class RecommendedSizeChanged extends VirtusizeWidgetEvent {
  final String size;
  final String text;

  RecommendedSizeChanged(this.text, this.size);
}

class LoadingChanged extends VirtusizeWidgetEvent {
  final bool isLoading;

  LoadingChanged(this.isLoading);
}

class ErrorOccurred extends VirtusizeWidgetEvent {
  ErrorOccurred();
}