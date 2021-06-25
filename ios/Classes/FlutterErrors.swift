import Flutter

internal let FlutterMethodNoArguments = FlutterError(code: "-1", message: "Missing arguments.", details: nil)

internal func FlutterMethodNotSetArgument(_ arg: String) -> FlutterError {
   return FlutterError(code: "-1", message: "\(arg) is not set.", details: nil)
}
