package com.virtusize.virtusize_flutter_plugin

import android.content.Context
import android.util.SparseArray
import android.view.View
import com.virtusize.libsource.ui.VirtusizeInPageStandard
import io.flutter.plugin.platform.PlatformView

internal class FLVirtusizeInPageStandard(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    companion object {
        val virtusizeInPageStandards = SparseArray<VirtusizeInPageStandard>()
    }

    private val virtusizeInPageStandard: VirtusizeInPageStandard
    private val viewId: Int

    override fun getView(): View {
        return virtusizeInPageStandard
    }

    override fun dispose() {
        virtusizeInPageStandards.remove(viewId)
    }

    init {
        viewId = id

        virtusizeInPageStandard = VirtusizeInPageStandard(context)

        virtusizeInPageStandards.append(id, virtusizeInPageStandard)
    }
}