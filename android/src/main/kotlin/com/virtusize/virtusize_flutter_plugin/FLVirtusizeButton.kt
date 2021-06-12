import android.content.Context
import android.util.SparseArray
import android.view.View
import com.virtusize.libsource.ui.VirtusizeButton
import io.flutter.plugin.platform.PlatformView

internal class FLVirtusizeButton(
    context: Context,
    id: Int, creationParams: Map<String?, Any?>?
) : PlatformView {

    companion object {
        val virtusizeButtons = SparseArray<VirtusizeButton>()
    }

    private val virtusizeButton: VirtusizeButton
    private val viewId: Int

    override fun getView(): View {
        return virtusizeButton
    }

    override fun dispose() {
        virtusizeButtons.remove(viewId)
    }

    init {
        viewId = id
        virtusizeButton = VirtusizeButton(context)
        virtusizeButtons.append(id, virtusizeButton)
    }
}