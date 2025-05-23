package com.virtusize.virtusize_flutter_sdk.util

import com.virtusize.virtusize_flutter_sdk.VirtusizeFlutterPlugin
import com.virtusize.android.flutter.VirtusizeFlutter
import com.virtusize.virtusize_flutter_sdk.mock.TestMethodChannel

/**
 * Utility methods for testing
 */
object TestUtil {
  /**
   * Injects mocks into the plugin using reflection
   */
  fun injectMocks(plugin: VirtusizeFlutterPlugin, mockVirtusizeFlutter: VirtusizeFlutter, methodChannel: TestMethodChannel) {
    // Use reflection to access private fields
    val pluginClass = plugin.javaClass
    val virtusizeFlutterField = pluginClass.getDeclaredField("virtusizeFlutter")
    virtusizeFlutterField.isAccessible = true
    virtusizeFlutterField.set(plugin, mockVirtusizeFlutter)

    val channelField = pluginClass.getDeclaredField("channel")
    channelField.isAccessible = true
    channelField.set(plugin, methodChannel)
  }

  /**
   * Creates test order data for tests
   */
  fun createTestOrderData(): Map<String, Any> {
    return mapOf(
      "externalOrderId" to "order123",
      "items" to listOf(
        mapOf(
          "externalProductId" to "A001",
          "size" to "L",
          "sizeAlias" to "Large",
          "variantId" to "A001_SIZEL_RED",
          "imageUrl" to "http://images.example.com/products/A001/red/image1xl.jpg",
          "color" to "Red",
          "gender" to "W",
          "unitPrice" to 5100.00,
          "currency" to "JPY",
          "quantity" to 1,
          "url" to "http://example.com/products/A001"
        )
      )
    )
  }
}