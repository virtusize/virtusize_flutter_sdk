import Flutter

extension FlutterError {
	internal static let noArguments = FlutterError(code: "-1", message: "Missing arguments.", details: nil)
	
	internal static func argumentNotSet(_ arg: String) -> FlutterError {
		return FlutterError(code: "-1", message: "\(arg) is not set.", details: nil)
	}
	
	internal static func nullAPIResult(_ arg: String) -> FlutterError {
		return FlutterError(code: "-1", message: "\(arg) is null.", details: nil)
	}
	
	internal static let unKnownError = FlutterError(code: "-1", message: "This code shouldn't get executed", details: nil)
}
