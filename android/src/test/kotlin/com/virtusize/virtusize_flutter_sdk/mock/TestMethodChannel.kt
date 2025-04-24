package com.virtusize.virtusize_flutter_sdk.mock

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.mockk.mockk

/**
 * Custom MethodChannel implementation to track invocations
 */
class TestMethodChannel : MethodChannel(mockk<BinaryMessenger>(), "test-channel") {
  val invocations = mutableListOf<Pair<String, Any?>>()

  override fun invokeMethod(method: String, arguments: Any?) {
    invocations.add(Pair(method, arguments))
  }
}