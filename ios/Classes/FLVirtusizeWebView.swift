import Flutter
import UIKit

import Virtusize

class FLVirtusizeWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLVirtusizeWebView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class FLVirtusizeWebView: NSObject, FlutterPlatformView {
    private var _view: VirtusizeWebView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = VirtusizeWebView(frame: .zero)
        super.init()
        // iOS views can be created here
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: VirtusizeWebView){
		_view.load(
			URLRequest(
				url: URL(
					string: "https://virtusize-jp-demo.s3-ap-northeast-1.amazonaws.com/sns-auth-test/index.html")!
			)
		)

    }
}
