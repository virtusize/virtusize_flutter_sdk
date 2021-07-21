package com.virtusize.virtusize_flutter_plugin

internal class VirtusizeFlutterErrors {
    companion object {
        val noArguments = FlutterError("NO_ARGUMENTS", errorMessage = "Missing arguments.")
        fun argumentNotSet(arg: String) = FlutterError("ARGUMENT_NOT_SET", errorMessage = "$arg is not set.")
        fun nullAPIResult(arg: String) = FlutterError("NULL_API_RESULT", errorMessage = "$arg is null.")
        val unKnown = FlutterError("UNKNOWN", errorMessage = "This code shouldn't get executed.")
        fun sendOrder(errorMessage: String) = FlutterError("SEND_ORDER", errorMessage = errorMessage)
    }
}

internal data class FlutterError(
    val errorCode: String,
    val errorMessage: String?
)