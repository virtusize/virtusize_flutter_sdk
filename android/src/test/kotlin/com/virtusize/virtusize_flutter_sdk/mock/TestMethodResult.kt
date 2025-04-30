package com.virtusize.virtusize_flutter_sdk.mock

import io.flutter.plugin.common.MethodChannel

/**
 * Custom Result implementation to track method calls
 */
class TestMethodResult : MethodChannel.Result {
  var successCalled = false
  var successResult: Any? = null
  var errorCalled = false
  var errorCode: String? = null
  var errorMessage: String? = null
  var errorDetails: Any? = null
  var notImplementedCalled = false

  override fun success(result: Any?) {
    successCalled = true
    successResult = result
  }

  override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
    errorCalled = true
    this.errorCode = errorCode
    this.errorMessage = errorMessage
    this.errorDetails = errorDetails
  }

  override fun notImplemented() {
    notImplementedCalled = true
  }
}