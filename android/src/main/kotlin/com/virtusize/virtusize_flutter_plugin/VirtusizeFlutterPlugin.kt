package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.*
import com.virtusize.libsource.data.local.*
import com.virtusize.libsource.data.remote.*
import com.virtusize.libsource.util.valueOf

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.lang.IllegalArgumentException


class VirtusizeFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will create the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private lateinit var repository: VirtusizeFlutterRepository
    private lateinit var messageHandler: VirtusizeMessageHandler
    private lateinit var scope: CoroutineScope

    private var virtusize: Virtusize? = null
    private var virtusizeProduct: VirtusizeProduct? = null
    private var productDataCheck: ProductCheck? = null
    private var storeProduct: Product? = null
    private var productTypes: List<ProductType>? = null
    private var i18nLocalization: I18nLocalization? = null
    private var userProducts: List<Product>? = null
    private var bodyProfileRecommendedSize: BodyProfileRecommendedSize? = null
    private var selectedUserProductId: Int? = null
    private var helper: VirtusizeFlutterHelper? = null


    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.virtusize/virtusize_flutter_plugin"
        )
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
        scope = CoroutineScope(Dispatchers.Main)
        messageHandler = object : VirtusizeMessageHandler {
            override fun onError(error: VirtusizeError) {
                scope.launch {
                    channel.invokeMethod("onVSError", error.toString())
                }
            }

            override fun onEvent(event: VirtusizeEvent) {
                when (event.name) {
                    VirtusizeEvents.UserOpenedWidget.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            selectedUserProductId = null
                            getRecommendation(
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                    VirtusizeEvents.UserAuthData.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                        }
                        event.data?.let { data ->
                            repository.updateUserAuthData(data)
                        }
                    }
                    VirtusizeEvents.UserSelectedProduct.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            event.data?.optInt("userProductId")?.let { userProductId ->
                                selectedUserProductId = userProductId
                            }
                            getRecommendation(
                                selectedRecommendedType = SizeRecommendationType.compareProduct,
                                shouldUpdateUserProducts = false
                            )
                        }
                    }
                    VirtusizeEvents.UserAddedProduct.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            event.data?.optInt("userProductId")?.let { userProductId ->
                                selectedUserProductId = userProductId
                            }
                            getRecommendation(
                                selectedRecommendedType = SizeRecommendationType.compareProduct,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                    VirtusizeEvents.UserChangedRecommendationType.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            var recommendationType: SizeRecommendationType? = null
                            event.data?.optString("recommendationType")?.let {
                                recommendationType = valueOf<SizeRecommendationType>(it)
                            }
                            getRecommendation(
                                selectedRecommendedType = recommendationType,
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                    VirtusizeEvents.UserUpdatedBodyMeasurements.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            event.data?.optString("sizeRecName")?.let { sizeRecName ->
                                bodyProfileRecommendedSize = BodyProfileRecommendedSize(sizeRecName)
                                getRecommendation(
                                    selectedRecommendedType = SizeRecommendationType.body,
                                    shouldUpdateUserProducts = false,
                                    shouldUpdateUserBodyProfile = false
                                )
                            }
                        }
                    }
                    VirtusizeEvents.UserLoggedIn.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            updateUserSession()
                            getRecommendation()
                        }
                    }
                    VirtusizeEvents.UserLoggedOut.getEventName(), VirtusizeEvents.UserDeletedData.getEventName() -> {
                        scope.launch {
                            channel.invokeMethod("onVSEvent", event.data.toString())
                            clearUserData()
                            updateUserSession()
                            getRecommendation(
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                }
            }
        }
        repository = VirtusizeFlutterRepository(context, messageHandler)

        // Register the VirtusizeButton
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "com.virtusize/virtusize_button",
            FLVirtusizeButtonFactory()
        )

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "com.virtusize/virtusize_inpage_standard",
            FLVirtusizeInPageStandardFactory(flutterPluginBinding.binaryMessenger)
        )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "setVirtusizeProps" -> {
                var virtusizeBuilder = VirtusizeBuilder().init(context)

                call.argument<String>("apiKey")?.let { apiKey ->
                    virtusizeBuilder = virtusizeBuilder.setApiKey(apiKey)
                } ?: run {
                    result.error("-1", "apiKey is null", null)
                    return
                }

                call.argument<String>("externalUserId")?.let { userId ->
                    virtusizeBuilder = virtusizeBuilder.setUserId(userId)
                }

                call.argument<String>("env")?.let { env ->
                    virtusizeBuilder = virtusizeBuilder.setEnv(VirtusizeEnvironment.valueOf(env))
                }

                call.argument<String>("language")?.let { lang ->
                    virtusizeBuilder = virtusizeBuilder.setLanguage(VirtusizeLanguage.valueOf(lang))
                }

                call.argument<Boolean>("showSGI")?.let { showSGI ->
                    virtusizeBuilder = virtusizeBuilder.setShowSGI(showSGI)
                }

                call.argument<List<String>>("allowedLanguages")?.let { langList ->
                    val allowedLanguages =
                        langList.map { VirtusizeLanguage.valueOf(it) }.toMutableList()
                    virtusizeBuilder = virtusizeBuilder.setAllowedLanguages(allowedLanguages)
                }

                call.argument<List<String>>("detailsPanelCards")?.let { detailsPanelCardList ->
                    val detailsPanelCards =
                        detailsPanelCardList.map { VirtusizeInfoCategory.valueOf(it) }
                            .toMutableList()
                    virtusizeBuilder = virtusizeBuilder.setDetailsPanelCards(detailsPanelCards)
                }

                virtusize = virtusizeBuilder.build()

                result.success(call.arguments.toString())
            }
            "getProductDataCheck" -> {
                val externalId = call.argument<String>("externalId")
                    ?: throw IllegalArgumentException("Please set the product's external ID")
                virtusizeProduct = VirtusizeProduct(
                    externalId = externalId,
                    imageUrl = call.argument<String>("imageUrl")
                )
                CoroutineScope(Dispatchers.Main).launch {
                    productDataCheck = repository.productDataCheck(virtusizeProduct!!)
                    result.success(productDataCheck?.jsonString)
                }
            }
            "openVirtusizeWebView" -> {
                if (virtusizeProduct == null || productDataCheck == null) {
                    throw IllegalArgumentException("Please invoke getProductDataCheck")
                }
                helper?.openVirtusizeView(
                    virtusize,
                    virtusizeProduct!!,
                    productDataCheck!!,
                    messageHandler
                )
            }
            "setVirtusizeView" -> {
                val type = call.argument<String>("viewType")
                call.argument<Int>("viewId")?.let {
                    if (type == "VirtusizeButton") {
                        virtusize?.setupVirtusizeView(FLVirtusizeButton.virtusizeButtons.get(it))
                    } else if (type == "VirtusizeInPageStandard") {
                        virtusize?.setupVirtusizeView(
                            FLVirtusizeInPageStandard.virtusizeInPageStandards.get(
                                it
                            )
                        )
                    }
                    result.success(true)
                } ?: run {
                    result.error("-1", "viewId is null", null)
                }
            }
            "getRecommendationText" -> {
                scope.launch {
                    if (productDataCheck?.data?.productDataId == null) {
                        result.error("-1", "this code shouldn't get executed", null)
                        return@launch
                    }
                    fetchInitialData(result)
                    updateUserSession(result)
                    getRecommendation(result)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private suspend fun fetchInitialData(result: Result) {
        storeProduct =
            repository.getStoreProduct(productDataCheck?.data?.productDataId!!)
        if (storeProduct == null) {
            result.error("-1", "storeProduct is null", null)
            scope.cancel()
        }

        productTypes = repository.getProductTypes()
        if (productTypes == null) {
            result.error("-1", "productTypes is null", null)
            scope.cancel()
        }

        i18nLocalization = repository.getI18nLocalization(virtusize?.displayLanguage)
        if (i18nLocalization == null) {
            result.error("-1", "i18nLocalization is null", null)
            scope.cancel()
        }
    }

    private suspend fun updateUserSession(result: Result? = null) {
        val userSessionResponse = repository.getUserSessionResponse()
        if (userSessionResponse == null) {
            if (result != null) {
                result.error("-1", "userSessionResponse is null", null)
            } else {
                channel.invokeMethod("onError", mutableMapOf("error" to "userSessionResponse is null"))
            }
            scope.cancel()
        }
    }

    private suspend fun getRecommendation(
        result: Result? = null,
        selectedRecommendedType: SizeRecommendationType? = null,
        shouldUpdateUserProducts: Boolean = true,
        shouldUpdateUserBodyProfile: Boolean = true
    ) {
        if (shouldUpdateUserProducts) {
            userProducts = repository.getUserProducts()
            if (userProducts == null) {
                if (result != null) {
                    result.error("-1", "userProducts is null", null)
                } else {
                    channel.invokeMethod("onError", mutableMapOf("error" to "userProducts is null"))
                }
                scope.cancel()
            }
        }

        if (shouldUpdateUserBodyProfile) {
            val userBodyProfile = repository.getUserBodyProfile()
            bodyProfileRecommendedSize =
                if (userBodyProfile == null) {
                    null
                } else {
                    repository.getBodyProfileRecommendedSize(
                        productTypes!!,
                        storeProduct!!,
                        userBodyProfile
                    )
                }
        }

        val recText = helper?.getRecommendationText(
            selectedRecommendedType,
            if (selectedUserProductId != null) userProducts?.filter { it.id == selectedUserProductId } else userProducts,
            storeProduct!!,
            productTypes!!,
            bodyProfileRecommendedSize,
            i18nLocalization!!
        )
        result?.success(recText) ?: run {
            channel.invokeMethod("onRecTextChange", recText)
        }
    }

    private suspend fun clearUserData() {
        repository.deleteUser()

        userProducts = null
        bodyProfileRecommendedSize = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        helper = VirtusizeFlutterHelper(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {
        helper = null
    }
}
