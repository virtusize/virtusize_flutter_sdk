import Flutter

extension FlutterError {
	internal static let noArguments = FlutterError(code: "NO_ARGUMENTS", message: "Missing arguments.", details: nil)
	
	internal static func argumentNotSet(_ arg: String) -> FlutterError {
		return FlutterError(code: "ARGUMENT_NOT_SET", message: "\(arg) is not set.", details: nil)
	}
	
	internal static func nullAPIResult(_ arg: String) -> FlutterError {
		return FlutterError(code: "NULL_API_RESULT", message: "\(arg) is null.", details: nil)
	}
	
	internal static let invalidUserID = FlutterError(code: "INVALID_USER_ID", message: "The user ID is set to null or empty", details: nil)
	
	internal static func sendOrder(_ errorMessage: String) -> FlutterError {
		return FlutterError(code: "SEND_ORDER", message: errorMessage, details: nil)
	}
	
	internal static let unknown = FlutterError(code: "UNKNOWN", message: "This code shouldn't get executed.", details: nil)
}
