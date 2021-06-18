package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.Virtusize
import com.virtusize.libsource.VirtusizeBuilder
import com.virtusize.libsource.data.local.*

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.IllegalArgumentException


class VirtusizeFlutterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will create the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private var virtuszie: Virtusize? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext;

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
            "setProduct" -> {
                val externalId = call.argument<String>("externalId")
                    ?: throw IllegalArgumentException("Please set the product's external ID")
                virtuszie?.setupVirtusizeProduct(
                    VirtusizeProduct(
                        externalId = externalId,
                        imageUrl = call.argument<String>("imageUrl")
                    )
                )
                result.success(true)
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
}
