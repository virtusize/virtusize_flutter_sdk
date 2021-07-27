package com.virtusize.virtusize_flutter_plugin

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.Virtusize
import com.virtusize.libsource.VirtusizeBuilder
import com.virtusize.libsource.flutter.VirtusizeFlutterRepository
import com.virtusize.libsource.flutter.VirtusizeFlutterUtils
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
    // The MethodChannel that will create the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var repository: VirtusizeFlutterRepository
    private lateinit var messageHandler: VirtusizeMessageHandler
    private lateinit var scope: CoroutineScope

    private var virtusize: Virtusize? = null

    // A set to cache the product data check data of all the visited products
    private val virtusizeProductSet = mutableSetOf<VirtusizeProduct>()

    // A stack implemented by a list to record the visited order of the external product IDs that are tied with the Virtusize widgets created on a client's app
    private val externalProductIDStack = mutableListOf<String>()

    // A set to cache the store product information of all the visited products
    private val storeProductSet = mutableSetOf<Product>()

    // The most recent visited store product on a client's app
    private val storeProduct: Product?
        get() = storeProductSet.firstOrNull { product -> product.externalId == externalProductIDStack.last() }

    private var selectedUserProductId: Int? = null
    private var productTypes: List<ProductType>? = null
    private var i18nLocalization: I18nLocalization? = null
    private var userProducts: List<Product>? = null
    private var userBodyProfile: UserBodyProfile? = null
    private var bodyProfileRecommendedSize: BodyProfileRecommendedSize? = null

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
                    channel.invokeMethod(VirtusizeFlutterMethod.ON_VS_ERROR, error.toString())
                }
            }

            override fun onEvent(event: VirtusizeEvent) {
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

                when (event.name) {
                    VirtusizeEvents.UserOpenedWidget.getEventName() -> {
                        // Unset the selected user product ID
                        selectedUserProductId = null

                        // If the store product that is associated with the current body profile recommended size is different from the most recent one,
                        // we should update the data for the body profile recommended size
                        val shouldUpdateBodyProfileRecommendedSize =
                            bodyProfileRecommendedSize?.product?.externalId != storeProduct?.externalId

                        scope.launch {
                            getRecommendation(
                                this,
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false,
                                shouldUpdateBodyProfileRecommendedSize = shouldUpdateBodyProfileRecommendedSize
                            )
                        }
                    }
                    VirtusizeEvents.UserAuthData.getEventName() -> {
                        event.data?.let { data ->
                            repository.updateUserAuthData(data)
                        }
                    }
                    VirtusizeEvents.UserSelectedProduct.getEventName() -> {
                        event.data?.optInt(VirtusizeEventKey.USER_PRODUCT_ID)?.let { userProductId ->
                            selectedUserProductId = userProductId
                        }
                        scope.launch {
                            getRecommendation(
                                this,
                                selectedRecommendedType = SizeRecommendationType.compareProduct,
                                shouldUpdateUserProducts = false
                            )
                        }
                    }
                    VirtusizeEvents.UserAddedProduct.getEventName() -> {
                        event.data?.optInt(VirtusizeEventKey.USER_PRODUCT_ID)?.let { userProductId ->
                            selectedUserProductId = userProductId
                        }
                        scope.launch {
                            getRecommendation(
                                this,
                                selectedRecommendedType = SizeRecommendationType.compareProduct,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                    VirtusizeEvents.UserChangedRecommendationType.getEventName() -> {
                        var recommendationType: SizeRecommendationType? = null
                        event.data?.optString(VirtusizeEventKey.REC_TYPE)?.let {
                            recommendationType = valueOf<SizeRecommendationType>(it)
                        }
                        scope.launch {
                            getRecommendation(
                                this,
                                selectedRecommendedType = recommendationType,
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                    VirtusizeEvents.UserUpdatedBodyMeasurements.getEventName() -> {
                        scope.launch {
                            event.data?.optString(VirtusizeEventKey.SIZE_REC_NAME)?.let { sizeRecName ->
                                bodyProfileRecommendedSize =
                                    BodyProfileRecommendedSize(storeProduct!!, sizeRecName)
                                getRecommendation(
                                    this,
                                    selectedRecommendedType = SizeRecommendationType.body,
                                    shouldUpdateUserProducts = false,
                                    shouldUpdateUserBodyProfile = false
                                )
                            }
                        }
                    }
                    VirtusizeEvents.UserLoggedIn.getEventName() -> {
                        scope.launch {
                            updateUserSession(this)
                            getRecommendation(this)
                        }
                    }
                    VirtusizeEvents.UserLoggedOut.getEventName(), VirtusizeEvents.UserDeletedData.getEventName() -> {
                        scope.launch {
                            clearUserData()
                            updateUserSession(this)
                            getRecommendation(
                                this,
                                shouldUpdateUserProducts = false,
                                shouldUpdateUserBodyProfile = false
                            )
                        }
                    }
                }
            }
        }
        repository = VirtusizeFlutterRepository(context, messageHandler)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            VirtusizeFlutterMethod.SET_VIRTUSIZE_PARAMS -> {
                if (call.arguments == null) {
                    val error = VirtusizeFlutterErrors.noArguments
                    result.error(error.errorCode, error.errorMessage, null)
                    return
                }

                var virtusizeBuilder = VirtusizeBuilder().init(context)

                call.argument<String>(VirtusizeFlutterKey.API_KEY)?.let { apiKey ->
                    virtusizeBuilder = virtusizeBuilder.setApiKey(apiKey)
                } ?: run {
                    val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.API_KEY)
                    result.error(error.errorCode, error.errorMessage, null)
                    return
                }

                call.argument<String>(VirtusizeFlutterKey.EXTERNAL_USER_ID)?.let { userId ->
                    virtusizeBuilder = virtusizeBuilder.setUserId(userId)
                }

                call.argument<String>(VirtusizeFlutterKey.ENVIRONMENT)?.let { env ->
                    virtusizeBuilder = virtusizeBuilder.setEnv(VirtusizeEnvironment.valueOf(env))
                }

                call.argument<String>(VirtusizeFlutterKey.LANGUAGE)?.let { lang ->
                    virtusizeBuilder = virtusizeBuilder.setLanguage(VirtusizeLanguage.valueOf(lang))
                }

                call.argument<Boolean>(VirtusizeFlutterKey.SHOW_SGI)?.let { showSGI ->
                    virtusizeBuilder = virtusizeBuilder.setShowSGI(showSGI)
                }

                call.argument<List<String>>(VirtusizeFlutterKey.ALLOW_LANGUAGES)?.let { langList ->
                    val allowedLanguages =
                        langList.map { VirtusizeLanguage.valueOf(it) }.toMutableList()
                    virtusizeBuilder = virtusizeBuilder.setAllowedLanguages(allowedLanguages)
                }

                call.argument<List<String>>(VirtusizeFlutterKey.DETAILS_PANEL_CARDS)?.let { detailsPanelCardList ->
                    val detailsPanelCards =
                        detailsPanelCardList.map { VirtusizeInfoCategory.valueOf(it) }
                            .toMutableList()
                    virtusizeBuilder = virtusizeBuilder.setDetailsPanelCards(detailsPanelCards)
                }

                virtusize = virtusizeBuilder.build()

                result.success(
                    mutableMapOf(
                        VirtusizeFlutterKey.VIRTUSIZE_PARAMS to call.arguments.toString(),
                        VirtusizeFlutterKey.DISPLAY_LANGUAGE to virtusize?.displayLanguage?.value
                    )
                )
            }
            VirtusizeFlutterMethod.SET_USER_ID -> {
                if (call.arguments == null) {
                    val error = VirtusizeFlutterErrors.noArguments
                    result.error(error.errorCode, error.errorMessage, null)
                    return
                }
                virtusize?.setUserId(call.arguments.toString())
            }
            VirtusizeFlutterMethod.GET_PRODUCT_DATA_CHECK -> {
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
                scope.launch {
                    val productDataCheck = repository.productDataCheck(virtusizeProduct)
                    productDataCheck?.let { productDataCheck ->
                        virtusizeProduct.productCheckData = productDataCheck
                        virtusizeProductSet.add(virtusizeProduct)
                    }
                    result.success(productDataCheck?.jsonString)
                }
            }
            VirtusizeFlutterMethod.OPEN_VIRTUSIZE_WEB_VIEW -> {
                val virtusizeProduct =
                    virtusizeProductSet.firstOrNull { product -> product.externalId == externalProductIDStack.last() }
                if (virtusizeProduct?.productCheckData == null) {
                    throw IllegalArgumentException("Please call the VirtusizePlugin.instance.setProduct function")
                }
                VirtusizeFlutterUtils.openVirtusizeView(
                    activity,
                    virtusize,
                    virtusizeProduct,
                    messageHandler
                )
            }
            VirtusizeFlutterMethod.GET_RECOMMENDATION_TEXT -> {
                val storeProductId = call.arguments as? Int
                if(storeProductId == null) {
                    val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.STORE_PRODUCT_ID)
                    result.error(error.errorCode, error.errorMessage, null)
                    return
                }
                scope.launch {
                    fetchInitialData(this, result, storeProductId = storeProductId)
                    updateUserSession(this, result)
                    getRecommendation(this, result, storeProductId = storeProductId)
                }
            }
            VirtusizeFlutterMethod.GET_PRIVACY_POLICY_LINK -> {
                result.success(VirtusizeFlutterUtils.getPrivacyPolicyLink(context, virtusize?.displayLanguage))
            }
            VirtusizeFlutterMethod.SEND_ORDER -> {
                scope.launch {
                    repository.sendOrder(
                        virtusize,
                        call.arguments as Map<String, Any?>,
                        onSuccess = {
                            result.success(call.arguments)
                        },
                        onError = {
                            val error = VirtusizeFlutterErrors.sendOrder(it.message)
                            result.error(error.errorCode, error.errorMessage, null)
                        })
                }
            }
            VirtusizeFlutterMethod.ADD_PRODUCT -> {
                val externalId = call.arguments as? String
                if (externalId == null) {
                    val error = VirtusizeFlutterErrors.argumentNotSet(VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID)
                    result.error(error.errorCode, error.errorMessage, null)
                    return
                }
                externalProductIDStack.add(externalId)
            }
            VirtusizeFlutterMethod.REMOVE_PRODUCT -> {
                externalProductIDStack.removeLast()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private suspend fun fetchInitialData(
        scope: CoroutineScope,
        result: Result,
        storeProductId: Int
    ) {
        selectedUserProductId = null

        val storeProduct = repository.getStoreProduct(storeProductId)
        if (storeProduct == null) {
            val error = VirtusizeFlutterErrors.nullAPIResult("storeProduct")
            result.error(error.errorCode, error.errorMessage, null)
            scope.cancel()
        }

        storeProductSet.add(storeProduct!!)

        channel.invokeMethod(
            VirtusizeFlutterMethod.ON_PRODUCT,
            mutableMapOf(
                VirtusizeFlutterKey.STORE_PRODUCT_ID to storeProduct.id,
                VirtusizeFlutterKey.IMAGE_TYPE to "store",
                VirtusizeFlutterKey.IMAGE_URL to storeProduct.getProductImageURL(),
                VirtusizeFlutterKey.PRODUCT_TYPE to storeProduct.productType,
                VirtusizeFlutterKey.PRODUCT_STYLE to storeProduct.storeProductMeta?.additionalInfo?.style
            )
        )

        productTypes = repository.getProductTypes()
        if (productTypes == null) {
            val error = VirtusizeFlutterErrors.nullAPIResult("productTypes")
            result.error(error.errorCode, error.errorMessage, null)
            scope.cancel()
        }

        i18nLocalization = repository.getI18nLocalization(virtusize?.displayLanguage)
        if (i18nLocalization == null) {
            val error = VirtusizeFlutterErrors.nullAPIResult("i18nLocalization")
            result.error(error.errorCode, error.errorMessage, null)
            scope.cancel()
        }
    }

    private suspend fun updateUserSession(scope: CoroutineScope, result: Result? = null) {
        val userSessionResponse = repository.getUserSessionResponse()
        if (userSessionResponse == null) {
            if (result != null) {
                val error = VirtusizeFlutterErrors.nullAPIResult("userSessionResponse")
                result.error(error.errorCode, error.errorMessage, null)
            } else {
                channel.invokeMethod(
                    VirtusizeFlutterMethod.ON_REC_CHANGE,
                    mutableMapOf(
                        VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to storeProduct!!.externalId,
                        VirtusizeFlutterKey.REC_TEXT to null,
                        VirtusizeFlutterKey.SHOW_USER_PRODUCT_IMAGE to false
                    )
                )
            }
            scope.cancel()
        }
    }

    private suspend fun getRecommendation(
        scope: CoroutineScope,
        result: Result? = null,
        storeProductId: Int? = null,
        selectedRecommendedType: SizeRecommendationType? = null,
        shouldUpdateUserProducts: Boolean = true,
        shouldUpdateUserBodyProfile: Boolean = true,
        shouldUpdateBodyProfileRecommendedSize: Boolean = false
    ) {
        // The default store product to use for the recommendation is the most recent one
        // But if the store product ID is not null, we update the store product value
        var storeProduct = storeProduct
        storeProductId?.let { productId ->
            storeProductSet.firstOrNull { product -> product.id == productId }?.let { product ->
                storeProduct = product
            }
        }

        if (shouldUpdateUserProducts) {
            userProducts = repository.getUserProducts()
            if (userProducts == null) {
                if (result != null) {
                    val error = VirtusizeFlutterErrors.nullAPIResult("userProducts")
                    result.error(error.errorCode, error.errorMessage, null)
                } else {
                    channel.invokeMethod(
                        VirtusizeFlutterMethod.ON_REC_CHANGE,
                        mutableMapOf(
                            VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to storeProduct!!.externalId,
                            VirtusizeFlutterKey.REC_TEXT to null,
                            VirtusizeFlutterKey.SHOW_USER_PRODUCT_IMAGE to false
                        )
                    )
                }
                scope.cancel()
            }
        }

        if (shouldUpdateUserBodyProfile) {
            userBodyProfile = repository.getUserBodyProfile()
        }

        if (shouldUpdateUserBodyProfile || shouldUpdateBodyProfileRecommendedSize) {
            bodyProfileRecommendedSize =
                if (userBodyProfile == null) {
                    null
                } else {
                    repository.getBodyProfileRecommendedSize(
                        productTypes!!,
                        storeProduct!!,
                        userBodyProfile!!
                    )
                }
        }

        val filteredUserProducts =
            if (selectedUserProductId != null) userProducts?.filter { it.id == selectedUserProductId } else userProducts

        val userProductRecommendedSize = VirtusizeFlutterUtils.getUserProductRecommendedSize(
            selectedRecommendedType,
            filteredUserProducts,
            storeProduct!!,
            productTypes!!
        )

        channel.invokeMethod(
            VirtusizeFlutterMethod.ON_PRODUCT,
            mutableMapOf(
                VirtusizeFlutterKey.STORE_PRODUCT_ID to storeProduct!!.id,
                VirtusizeFlutterKey.IMAGE_TYPE to "user",
                VirtusizeFlutterKey.IMAGE_URL to userProductRecommendedSize?.bestUserProduct?.getProductImageURL(),
                VirtusizeFlutterKey.PRODUCT_TYPE to userProductRecommendedSize?.bestUserProduct?.productType,
                VirtusizeFlutterKey.PRODUCT_STYLE to userProductRecommendedSize?.bestUserProduct?.storeProductMeta?.additionalInfo?.style
            )
        )

        val recText = VirtusizeFlutterUtils.getRecommendationText(
            selectedRecommendedType,
            storeProduct!!,
            userProductRecommendedSize,
            bodyProfileRecommendedSize,
            i18nLocalization!!
        )

        val resultMap = mutableMapOf(
            VirtusizeFlutterKey.EXTERNAL_PRODUCT_ID to storeProduct!!.externalId,
            VirtusizeFlutterKey.REC_TEXT to recText,
            VirtusizeFlutterKey.SHOW_USER_PRODUCT_IMAGE to (userProductRecommendedSize?.bestUserProduct != null)
        )

        result?.success(resultMap) ?: run {
            channel.invokeMethod(VirtusizeFlutterMethod.ON_REC_CHANGE, resultMap)
        }
    }

    private suspend fun clearUserData() {
        repository.deleteUser()

        selectedUserProductId = null
        userProducts = null
        bodyProfileRecommendedSize = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
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