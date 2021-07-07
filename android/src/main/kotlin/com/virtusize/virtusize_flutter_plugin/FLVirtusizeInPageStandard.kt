package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import android.graphics.Color
import android.util.SparseArray
import android.view.View
import com.virtusize.libsource.data.local.VirtusizeViewStyle
import com.virtusize.libsource.ui.VirtusizeInPageStandard
import com.virtusize.libsource.util.dpInPx
import com.virtusize.libsource.util.pxInDp
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView


internal class FLVirtusizeInPageStandard(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    companion object {
        val virtusizeInPageStandards = SparseArray<VirtusizeInPageStandard>()
    }

    private val virtusizeInPageStandard: VirtusizeInPageStandard
    private val viewId: Int
    private var channel: MethodChannel? = null

    override fun getView(): View {
        return virtusizeInPageStandard
    }

    override fun dispose() {
        virtusizeInPageStandards.remove(viewId)
    }

    init {
        viewId = id
        channel = MethodChannel(messenger, "com.virtusize/virtusize_inpage_standard_$id")

        virtusizeInPageStandard = VirtusizeInPageStandard(context)

        (creationParams?.get("virtusizeStyle") as? String)?.let {
            virtusizeInPageStandard.virtusizeViewStyle = VirtusizeViewStyle.valueOf(it)
        }
        (creationParams?.get("buttonBackgroundColor") as? String)?.let {
            virtusizeInPageStandard.setButtonBackgroundColor(Color.parseColor(it))
        }

        virtusizeInPageStandard.onInPageCardViewSizeChanged = { width, height ->
            channel?.invokeMethod("onInPageCardViewSizeChanged", mutableMapOf("width" to width.pxInDp.toDouble(), "height" to height.pxInDp.toDouble()))
        }

        virtusizeInPageStandard.onFinishLoading = {
            channel?.invokeMethod("onFinishLoading", null)
        }

        virtusizeInPageStandards.append(id, virtusizeInPageStandard)
    }
}