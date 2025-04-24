package com.virtusize.virtusize_flutter_sdk.test

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import com.virtusize.android.data.local.*
import com.virtusize.android.flutter.VirtusizeFlutter
import com.virtusize.android.flutter.VirtusizeFlutterBuilder
import com.virtusize.virtusize_flutter_sdk.VirtusizeFlutterPlugin
import com.virtusize.virtusize_flutter_sdk.mock.TestMethodChannel
import com.virtusize.virtusize_flutter_sdk.mock.TestMethodResult
import com.virtusize.virtusize_flutter_sdk.util.TestUtil
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.mockk.*
import io.mockk.impl.annotations.MockK
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@ExperimentalCoroutinesApi
class VirtusizeFlutterSdkTest {
  @MockK
  private lateinit var mockContext: Context

  @MockK
  private lateinit var mockActivity: Activity

  @MockK
  private lateinit var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  @MockK
  private lateinit var mockBinaryMessenger: BinaryMessenger

  @MockK
  private lateinit var mockActivityBinding: ActivityPluginBinding

  @MockK
  private lateinit var mockVirtusizeFlutter: VirtusizeFlutter

  @MockK
  private lateinit var mockVirtusizeFlutterBuilder: VirtusizeFlutterBuilder

  private lateinit var mockResult: TestMethodResult
  private lateinit var methodChannel: TestMethodChannel
  private lateinit var plugin: VirtusizeFlutterPlugin
  private val testDispatcher = StandardTestDispatcher()

  fun injectMocks() {
    TestUtil.injectMocks(
      plugin,
      mockVirtusizeFlutter,
      methodChannel
    )
  }

  @Before
  fun setUp() {
    MockKAnnotations.init(this)
    Dispatchers.setMain(testDispatcher)

    every { mockFlutterPluginBinding.applicationContext } returns mockContext
    every { mockFlutterPluginBinding.binaryMessenger } returns mockBinaryMessenger
    every { mockBinaryMessenger.setMessageHandler(any(), any()) } just Runs
    every { mockActivityBinding.activity } returns mockActivity

    val mockSharedPreferences = mockk<SharedPreferences>(relaxed = true)
    val mockEditor = mockk<SharedPreferences.Editor>(relaxed = true)
    every { mockSharedPreferences.edit() } returns mockEditor
    every { mockEditor.putString(any(), any()) } returns mockEditor
    every { mockEditor.apply() } just Runs
    every { mockContext.getSharedPreferences(any(), any()) } returns mockSharedPreferences

    every { mockVirtusizeFlutterBuilder.init(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setApiKey(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setUserId(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setEnv(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setLanguage(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setShowSGI(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setAllowedLanguages(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setDetailsPanelCards(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.setShowSNSButtons(any()) } returns mockVirtusizeFlutterBuilder
    every { mockVirtusizeFlutterBuilder.build() } returns mockVirtusizeFlutter

    every { mockVirtusizeFlutter.load(any()) } just Runs
    every { mockVirtusizeFlutter.openVirtusizeWebView(any(), any()) } just Runs
    every { mockVirtusizeFlutter.setUserId(any()) } just Runs
    every { mockVirtusizeFlutter.getPrivacyPolicyLink(any()) } returns "https://privacy.virtusize.com"
    every { mockVirtusizeFlutter.registerMessageHandler(any()) } just Runs

    mockResult = TestMethodResult()
    methodChannel = TestMethodChannel()

    plugin = VirtusizeFlutterPlugin()
  }

  @After
  fun tearDown() {
    Dispatchers.resetMain()
    clearAllMocks()
  }

  @Test
  fun `test setVirtusizeParams with valid parameters`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val args = mapOf(
      VirtusizeFlutterKey.API_KEY to "test_api_key",
      VirtusizeFlutterKey.ENVIRONMENT to "STAGING",
      VirtusizeFlutterKey.LANGUAGE to "EN"
    )

    val call = MethodCall(VirtusizeFlutterMethod.SET_VIRTUSIZE_PARAMS, args)

    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.successCalled)
    assertFalse(mockResult.errorCalled)
  }

  @Test
  fun `test setVirtusizeParams with missing API key`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val args = mapOf(
      VirtusizeFlutterKey.ENVIRONMENT to "STAGING",
      VirtusizeFlutterKey.LANGUAGE to "EN"
    )

    val call = MethodCall(VirtusizeFlutterMethod.SET_VIRTUSIZE_PARAMS, args)

    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.errorCalled)
    assertEquals(
      VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.API_KEY).errorCode,
      mockResult.errorCode
    )
  }

  @Test
  fun `test loadVirtusize with valid parameters`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val args = mapOf(
      VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to "product123",
      VirtusizeFlutterKey.IMAGE_URL to "https://example.com/image.jpg"
    )

    val call = MethodCall(VirtusizeFlutterMethod.LOAD_VIRTUSIZE, args)
    plugin.onMethodCall(call, mockResult)

    verify { mockVirtusizeFlutter.load(match { it.externalId == "product123" }) }
    assertFalse(mockResult.errorCalled)
  }

  @Test
  fun `test loadVirtusize with missing external product ID`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val args = mapOf(
      VirtusizeFlutterKey.IMAGE_URL to "https://example.com/image.jpg"
    )

    val call = MethodCall(VirtusizeFlutterMethod.LOAD_VIRTUSIZE, args)

    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.errorCalled)
    assertEquals(
      VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID).errorCode,
      mockResult.errorCode
    )
  }

  @Test
  fun `test openVirtusizeWebView with valid product ID`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    plugin.onAttachedToActivity(mockActivityBinding)
    injectMocks()

    val productId = "product123"
    val call = MethodCall(VirtusizeFlutterMethod.OPEN_VIRTUSIZE_WEB_VIEW, productId)
    plugin.onMethodCall(call, mockResult)

    verify { mockVirtusizeFlutter.openVirtusizeWebView(mockActivity, "product123") }
    assertFalse(mockResult.errorCalled)
  }

  @Test
  fun `test openVirtusizeWebView with null product ID`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    plugin.onAttachedToActivity(mockActivityBinding)
    injectMocks()

    val call = MethodCall(VirtusizeFlutterMethod.OPEN_VIRTUSIZE_WEB_VIEW, null)
    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.errorCalled)
    assertEquals(
      VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID).errorCode,
      mockResult.errorCode
    )
  }

  @Test
  fun `test getPrivacyPolicyLink`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val call = MethodCall(VirtusizeFlutterMethod.GET_PRIVACY_POLICY_LINK, null)
    plugin.onMethodCall(call, mockResult)

    // Verify
    verify { mockVirtusizeFlutter.getPrivacyPolicyLink(any()) }
    assertTrue(mockResult.successCalled)
    assertEquals("https://privacy.virtusize.com", mockResult.successResult)
  }

  @Test
  fun `test setUserId with valid ID`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val userId = "user123"
    val call = MethodCall(VirtusizeFlutterMethod.SET_USER_ID, userId)
    plugin.onMethodCall(call, mockResult)

    verify { mockVirtusizeFlutter.setUserId("user123") }
    assertFalse(mockResult.errorCalled)
  }

  @Test
  fun `test setUserId with null ID`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val call = MethodCall(VirtusizeFlutterMethod.SET_USER_ID, null)
    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.errorCalled)
  }

  @Test
  fun `test sendOrder with success`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val orderData = TestUtil.createTestOrderData()
    val call = MethodCall(VirtusizeFlutterMethod.SEND_ORDER, orderData)
    clearMocks(mockVirtusizeFlutter)

    every {
      mockVirtusizeFlutter.sendOrder(
        any(),
        any<() -> Unit>(),
        any<(VirtusizeError) -> Unit>()
      )
    } answers {
      val successCallback = arg<() -> Unit>(1)
      successCallback.invoke()
    }

    plugin.onMethodCall(call, mockResult)
    testDispatcher.scheduler.advanceUntilIdle()

    assertTrue(mockResult.successCalled)
    assertFalse(mockResult.errorCalled)
  }

  @Test
  fun `test sendOrder with error`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)
    injectMocks()

    val orderData = TestUtil.createTestOrderData()
    val call = MethodCall(VirtusizeFlutterMethod.SEND_ORDER, orderData)
    clearMocks(mockVirtusizeFlutter)

    every {
      mockVirtusizeFlutter.sendOrder(
        any(),
        any<() -> Unit>(),
        any<(VirtusizeError) -> Unit>()
      )
    } answers {
      val errorCallback = arg<(VirtusizeError) -> Unit>(2)
      errorCallback.invoke(VirtusizeError(message = "error"))
    }

    plugin.onMethodCall(call, mockResult)
    testDispatcher.scheduler.advanceUntilIdle()

    // Verify
    assertFalse(mockResult.successCalled)
    assertTrue(mockResult.errorCalled)
    assertEquals("SEND_ORDER", mockResult.errorCode)
  }

  @Test
  fun `test unimplemented method call`() {
    plugin.onAttachedToEngine(mockFlutterPluginBinding)

    val call = MethodCall("UNKNOWN_METHOD", null)
    plugin.onMethodCall(call, mockResult)

    assertTrue(mockResult.notImplementedCalled)
  }
}
