package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.Virtusize
import com.virtusize.libsource.VirtusizeBuilder
import com.virtusize.libsource.VirtusizeFlutterHelper
import com.virtusize.libsource.VirtusizeFlutterRepository
import com.virtusize.libsource.data.local.*
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
    private var virtuszie: Virtusize? = null
    private var virtusizeProduct: VirtusizeProduct? = null
    private var productDataCheck: ProductCheck? = null
    private lateinit var repository: VirtusizeFlutterRepository
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
                val apiKey = call.argument<String>("apiKey")
                if (apiKey == null) {
                    result.error("Missing Arguments", "apiKey is null", null)
                }
                virtuszie = VirtusizeBuilder().init(context)
                    .setApiKey(call.argument<String>("apiKey"))
                    .setUserId(call.argument<String>("externalUserId"))
                    .setEnv(call.argument<String>("env")?.let {
                        VirtusizeEnvironment.valueOf(it)
                    })
                    .setLanguage(
                        call.argument<String>("language")?.let {
                            VirtusizeLanguage.valueOf(it)
                        }
                    )
                    .setShowSGI(call.argument<Boolean>("showSGI") ?: false)
                    .setAllowedLanguages(
                        call.argument<List<String>>("allowedLanguages")?.map {
                            VirtusizeLanguage.valueOf(it)
                        }?.toMutableList()
                    )
                    .setDetailsPanelCards(
                        call.argument<List<String>>("detailsPanelCards")?.map {
                            VirtusizeInfoCategory.valueOf(it)
                        }?.toMutableList()
                    )
                    .build()
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
                helper?.openVirtusizeView(virtuszie, virtusizeProduct!!, productDataCheck!!)
            }
            "setVirtusizeView" -> {
                val type = call.argument<String>("viewType")
                call.argument<Int>("viewId")?.let {
                    if(type == "VirtusizeButton") {
                        virtuszie?.setupVirtusizeView(FLVirtusizeButton.virtusizeButtons.get(it))
                    } else if (type == "VirtusizeInPageStandard") {
                        virtuszie?.setupVirtusizeView(FLVirtusizeInPageStandard.virtusizeInPageStandards.get(it))
                    }
                    result.success(true)
                } ?: run {
                    result.error("Missing Arguments", "viewId is null", null)
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
