package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.*
import com.virtusize.libsource.data.local.*
import com.virtusize.libsource.data.remote.BodyProfileRecommendedSize
import com.virtusize.libsource.data.remote.ProductCheck

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.lang.IllegalArgumentException


class VirtusizeFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will create the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private var virtusize: Virtusize? = null
    private lateinit var repository: VirtusizeFlutterRepository
    private var virtusizeProduct: VirtusizeProduct? = null
    private var productDataCheck: ProductCheck? = null
    private var helper: VirtusizeFlutterHelper? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        repository = VirtusizeFlutterRepository(context)

        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.virtusize/virtusize_flutter_plugin"
        )
        channel.setMethodCallHandler(this)

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
                helper?.openVirtusizeView(virtusize, virtusizeProduct!!, productDataCheck!!)
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
                CoroutineScope(Dispatchers.Main).launch {
                    if (productDataCheck?.data?.productDataId == null) {
                        result.error("-1", "this code shouldn't get executed", null)
                        return@launch
                    }

                    val storeProduct =
                        repository.getStoreProduct(productDataCheck?.data?.productDataId!!)
                    if (storeProduct == null) {
                        result.error("-1", "storeProduct is null", null)
                        return@launch
                    }

                    val productTypes = repository.getProductTypes()
                    if (productTypes == null) {
                        result.error("-1", "productTypes is null", null)
                        return@launch
                    }

                    val i18nLocalization = repository.getI18nLocalization(virtusize?.displayLanguage)
                    if (i18nLocalization == null) {
                        result.error("-1", "i18nLocalization is null", null)
                        return@launch
                    }

                    val userSessionResponse = repository.getUserSessionResponse()
                    if (userSessionResponse == null) {
                        result.error("-1", "userSessionResponse is null", null)
                        return@launch
                    }

                    val userProducts = repository.getUserProducts()
                    if (userProducts == null) {
                        result.error("-1", "userProducts is null", null)
                        return@launch
                    }

                    val userBodyProfile = repository.getUserBodyProfile()
                    val bodyProfileRecommendedSize: BodyProfileRecommendedSize? = if (userBodyProfile == null) {
                        null
                    } else {
                        repository.getBodyProfileRecommendedSize(
                            productTypes,
                            storeProduct,
                            userBodyProfile
                        )
                    }

                    result.success(
                        helper?.getRecommendationText(
                            userProducts,
                            storeProduct,
                            productTypes,
                            bodyProfileRecommendedSize,
                            i18nLocalization
                        )
                    )
                }
            }
            else -> {
                result.notImplemented()
            }
        }
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
