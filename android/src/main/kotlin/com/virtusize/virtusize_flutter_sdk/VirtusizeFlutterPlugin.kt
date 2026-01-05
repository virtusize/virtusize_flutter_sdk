package com.virtusize.virtusize_flutter_sdk

import android.app.Activity
import android.content.Context
import com.virtusize.android.data.local.*
import com.virtusize.android.data.remote.*
import com.virtusize.android.flutter.VirtusizeFlutter
import com.virtusize.android.flutter.VirtusizeFlutterBuilder
import com.virtusize.android.flutter.VirtusizeFlutterPresenter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class VirtusizeFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  // The MethodChannel that will create the communication between Flutter and native Android
  private lateinit var channel: MethodChannel

  private lateinit var context: Context
  private lateinit var activity: Activity
  private lateinit var messageHandler: VirtusizeMessageHandler
  private lateinit var scope: CoroutineScope
  private lateinit var virtusizeFlutter: VirtusizeFlutter

  private var virtusizeFlutterPresenter: VirtusizeFlutterPresenter =
    object : VirtusizeFlutterPresenter {
      override fun onValidProductCheck(productWithPCDData: VirtusizeProduct) {
        // Post to main thread with delay to ensure Flutter widgets have time to subscribe
        // This handles the case where cached data causes synchronous callback execution
        scope.launch {
          kotlinx.coroutines.delay(100)
          channel.invokeMethod(
            VirtusizeFlutterMethod.ON_PRODUCT_DATA_CHECK,
            mutableMapOf(
              VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to productWithPCDData.externalId,
              VirtusizeFlutterKey.IS_VALID_PRODUCT to (productWithPCDData.productCheckData?.data?.validProduct ?: false),
            )
          )
        }
      }

      override fun hasInPageError(
        externalProductId: String?,
        error: VirtusizeError?,
      ) {
        channel.invokeMethod(
          VirtusizeFlutterMethod.ON_PRODUCT_ERROR,
          externalProductId
        )
      }

      override fun gotSizeRecommendations(
        externalProductId: String,
        storeProduct: Product?,
        bestUserProduct: Product?,
        recommendationText: String?,
        willFit: Boolean?,
      ) {
        scope.launch {
          kotlinx.coroutines.delay(100)
          sendOnProductResult(storeProduct, "store")
          sendOnProductResult(bestUserProduct, "user")

          // Show user product image only if:
          // - willFit is not explicitly false (when false, it means "Your size not found")
          // - AND there is a bestUserProduct available
          val showUserProductImage = willFit != false && bestUserProduct != null

          channel.invokeMethod(
            VirtusizeFlutterMethod.ON_REC_CHANGE,
            mutableMapOf(
              VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to externalProductId,
              VirtusizeFlutterKey.REC_TEXT to recommendationText,
              VirtusizeFlutterKey.SHOW_USER_PRODUCT_IMAGE to showUserProductImage
            )
          )
        }
      }

      override fun onLangugeClick(language: VirtusizeLanguage) {
        scope.launch {
          channel.invokeMethod(
            VirtusizeFlutterMethod.ON_LANGUAGE_CLICK,
            mutableMapOf(VirtusizeFlutterKey.LANGUAGE to language.value)
          )
        }
      }
    }

  private fun sendOnProductResult(product: Product?, imageType: String) {
    channel.invokeMethod(
      VirtusizeFlutterMethod.ON_PRODUCT,
      mutableMapOf(
        VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to product?.externalId,
        VirtusizeFlutterKey.IMAGE_TYPE to imageType,
        VirtusizeFlutterKey.IMAGE_URL to product?.clientProductImageURL,
        VirtusizeFlutterKey.CLOUDINARY_IMAGE_URL to product?.getCloudinaryProductImageURL(),
        VirtusizeFlutterKey.PRODUCT_TYPE to product?.productType,
        VirtusizeFlutterKey.PRODUCT_STYLE to product?.storeProductMeta?.additionalInfo?.style
      )
    )
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(
      flutterPluginBinding.binaryMessenger,
      "com.virtusize/flutter_virtusize_sdk"
    )
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.applicationContext
    scope = CoroutineScope(Dispatchers.Main)

    messageHandler = object : VirtusizeMessageHandler {
      override fun onError(error: VirtusizeError) {
        scope.launch {
          channel.invokeMethod(VirtusizeFlutterMethod.ON_VS_ERROR, error.toString())
        }
      }

      override fun onEvent(product: VirtusizeProduct, event: VirtusizeEvent) {
        var eventName: String? = null
        if (event.name.isNotEmpty()) {
          eventName = event.name
        } else if (event.data != null) {
          eventName =
            event.data!!.optString(VirtusizeEventKey.SHORT_EVENT_NAME) ?: event.data!!.optString(VirtusizeEventKey.EVENT_NAME)
        }
        eventName?.let {
          scope.launch {
            channel.invokeMethod(VirtusizeFlutterMethod.ON_VS_EVENT, eventName)
          }
        }
      }
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      VirtusizeFlutterMethod.SET_VIRTUSIZE_PARAMS -> {
        if (call.arguments == null) {
          val error = VirtusizeFlutterErrors.noArguments
          result.error(error.errorCode, error.errorMessage, null)
          return
        }

        var virtusizeFlutterBuilder = VirtusizeFlutterBuilder().init(context)

        call.argument<String>(VirtusizeFlutterKey.API_KEY)?.let { apiKey ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setApiKey(apiKey)
        } ?: run {
          val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.API_KEY)
          result.error(error.errorCode, error.errorMessage, null)
          return
        }

        call.argument<String>(VirtusizeFlutterKey.EXTERNAL_USER_ID)?.let { userId ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setUserId(userId)
        }

        call.argument<String>(VirtusizeFlutterKey.ENVIRONMENT)?.let { env ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setEnv(VirtusizeEnvironment.valueOf(env))
        }

        call.argument<String>(VirtusizeFlutterKey.LANGUAGE)?.let { lang ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setLanguage(VirtusizeLanguage.valueOf(lang))
        }

        call.argument<Boolean>(VirtusizeFlutterKey.SHOW_SGI)?.let { showSGI ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setShowSGI(showSGI)
        }

        call.argument<List<String>>(VirtusizeFlutterKey.ALLOW_LANGUAGES)?.let { langList ->
          val allowedLanguages =
            langList.map { VirtusizeLanguage.valueOf(it) }.toMutableList()
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setAllowedLanguages(allowedLanguages)
        }

        call.argument<List<String>>(VirtusizeFlutterKey.DETAILS_PANEL_CARDS)?.let { detailsPanelCardList ->
          val detailsPanelCards =
            detailsPanelCardList.map { VirtusizeInfoCategory.valueOf(it) }
              .toSet()
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setDetailsPanelCards(detailsPanelCards)
        }

        call.argument<Boolean>(VirtusizeFlutterKey.SHOW_SNS_BUTTONS)?.let { showSNSButtons ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setShowSNSButtons(showSNSButtons)
        }

        call.argument<String>(VirtusizeFlutterKey.BRANCH)?.let { branch ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setBranch(branch)
        }

        call.argument<Boolean>(VirtusizeFlutterKey.SHOW_PRIVACY_POLICY)?.let { showPrivacyPolicy ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setShowPrivacyPolicy(showPrivacyPolicy)
        }

        call.argument<Boolean>(VirtusizeFlutterKey.SERVICE_ENVIRONMENT)?.let { serviceEnvironment ->
          virtusizeFlutterBuilder = virtusizeFlutterBuilder.setServiceEnvironment(serviceEnvironment)
        }

        virtusizeFlutter = virtusizeFlutterBuilder
          .setPresenter(virtusizeFlutterPresenter)
          .build()

        virtusizeFlutter.registerMessageHandler(messageHandler)

        result.success(
          mutableMapOf(
            VirtusizeFlutterKey.VIRTUSIZE_PARAMS to call.arguments.toString(),
            VirtusizeFlutterKey.DISPLAY_LANGUAGE to virtusizeFlutter?.displayLanguage?.value
          )
        )
      }
      VirtusizeFlutterMethod.SET_USER_ID -> {
        if (call.arguments == null) {
          val error = VirtusizeFlutterErrors.noArguments
          result.error(error.errorCode, error.errorMessage, null)
          return
        }
        virtusizeFlutter.setUserId(call.arguments.toString())
        result.success(true)
      }
      VirtusizeFlutterMethod.LOAD_VIRTUSIZE -> {
        val externalId = call.argument<String>(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID)
        if (externalId == null) {
          val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID)
          result.error(error.errorCode, error.errorMessage, null)
          return
        }
        val virtusizeProduct = VirtusizeProduct(
          externalId = externalId,
          imageUrl = call.argument<String>(VirtusizeFlutterKey.IMAGE_URL)
        )

        virtusizeFlutter.load(virtusizeProduct)
        result.success(true)
      }
      VirtusizeFlutterMethod.OPEN_VIRTUSIZE_WEB_VIEW -> {
        val externalProductId = call.arguments as? String
        if (externalProductId == null) {
          val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID)
          result.error(error.errorCode, error.errorMessage, null)
          return
        }

        virtusizeFlutter.openVirtusizeWebView(
          activity,
          externalProductId
        )
        result.success(true)
      }
      VirtusizeFlutterMethod.GET_PRIVACY_POLICY_LINK -> {
        result.success(
          virtusizeFlutter.getPrivacyPolicyLink(context)
        )
      }
      VirtusizeFlutterMethod.SEND_ORDER -> {
        val orderMap = call.arguments as Map<String, Any?>;
        val virtusizeOrder = VirtusizeOrder.parseMap(orderMap);
        scope.launch {
          virtusizeFlutter.sendOrder(
            virtusizeOrder,
            onSuccess = {
              result.success(call.arguments)
            },
            onError = {
              val error = VirtusizeFlutterErrors.sendOrder(it.message)
              result.error(error.errorCode, error.errorMessage, null)
            }
          )
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    scope.cancel()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {}

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

  override fun onDetachedFromActivity() {}
}