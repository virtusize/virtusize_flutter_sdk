package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import androidx.annotation.NonNull
import com.virtusize.libsource.Virtusize
import com.virtusize.libsource.VirtusizeBuilder
import com.virtusize.libsource.data.local.VirtusizeEnvironment
import com.virtusize.libsource.data.local.VirtusizeInfoCategory
import com.virtusize.libsource.data.local.VirtusizeLanguage

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** VirtusizeFlutterPlugin */
class VirtusizeFlutterPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
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
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "setVirtusizeProps" -> {
                virtuszie = VirtusizeBuilder().init(context)
                    .setApiKey(call.argument<String>("apiKey") ?: "")
                    // For using the Order API, a user ID is required
                    .setUserId(call.argument<String>("externalUserId") ?: "")
                    // By default, the Virtusize environment will be set to GLOBAL
                    .setEnv(VirtusizeEnvironment.valueOf(call.argument<String>("env") ?: "GLOBAL"))
                    // By default, the initial language will be set based on the Virtusize environment
                    .setLanguage(
                        VirtusizeLanguage.valueOf(
                            call.argument<String>("language") ?: "EN"
                        )
                    )
                    // By default, ShowSGI is false
                    .setShowSGI(call.argument<Boolean>("showSGI") ?: false)
                    // By default, Virtusize allows all the possible languages
                    .setAllowedLanguages(
                        call.argument<List<String>>("allowedLanguages")?.map {
                            VirtusizeLanguage.valueOf(it)
                        }?.toMutableList() ?: VirtusizeLanguage.values().toMutableList()
                    )
                    // By default, Virtusize displays all the possible info categories in the Product Details tab
                    .setDetailsPanelCards(call.argument<List<String>>("detailsPanelCards")?.map {
                        VirtusizeInfoCategory.valueOf(it)
                    }?.toMutableList() ?: VirtusizeInfoCategory.values().toMutableList())
                    .build()
                result.success(virtuszie.toString())
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
