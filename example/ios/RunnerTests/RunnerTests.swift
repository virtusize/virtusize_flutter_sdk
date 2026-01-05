import XCTest
import Flutter

@testable import virtusize_flutter_sdk

class RunnerTests: XCTestCase {
    
    var plugin: SwiftVirtusizeFlutterPlugin!
    var mockChannel: MockFlutterMethodChannel!
    
    override func setUp() {
        super.setUp()
        mockChannel = MockFlutterMethodChannel(name: "test_channel", binaryMessenger: FlutterBinaryMessengerDummy())
        plugin = SwiftVirtusizeFlutterPlugin(channel: mockChannel)
    }
    
    override func tearDown() {
        plugin = nil
        mockChannel = nil
        super.tearDown()
    }
    
    func testSetVirtusizeParamsWithValidArguments() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.setVirtusizeParams,
            arguments: [
                VirtusizeFlutterKey.apiKey: "test_api_key",
                VirtusizeFlutterKey.environment: "staging",
                VirtusizeFlutterKey.language: "en",
            ]
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
        if let resultDict = resultData as? [String: Any] {
            XCTAssertNotNil(resultDict[VirtusizeFlutterKey.virtusizeParams])
        } else {
            XCTFail("Result is not a dictionary")
        }
    }
    
    func testSetVirtusizeParamsWithoutApiKey() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.setVirtusizeParams,
            arguments: [
                VirtusizeFlutterKey.environment: "staging",
                VirtusizeFlutterKey.language: "en",
            ]
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
        if let error = resultData as? FlutterError {
            XCTAssertEqual(error.code, "ARGUMENT_NOT_SET")
        } else {
            XCTFail("Expected FlutterError with ARGUMENT_NOT_SET")
        }
    }
    
    func testLoadVirtusizeWithValidData() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.loadVirtusize,
            arguments: [
                VirtusizeFlutterKey.externalProductId: "product123",
                VirtusizeFlutterKey.imageURL: "https://example.com/image.jpg"
            ]
        )

        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }

        XCTAssertNotNil(resultData)
        XCTAssertEqual(resultData as? Bool, true)
    }
    
    func testLoadVirtusizeWithoutProductId() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.loadVirtusize,
            arguments: [VirtusizeFlutterKey.imageURL: "https://example.com/image.jpg"]
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
        if let error = resultData as? FlutterError {
            XCTAssertEqual(error.code, "ARGUMENT_NOT_SET")
        } else {
            XCTFail("Expected FlutterError with ARGUMENT_NOT_SET")
        }
    }
    
    func testSetUserId() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.setUserId,
            arguments: "test_user_id"
        )

        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }

        XCTAssertNotNil(resultData)
        XCTAssertEqual(resultData as? Bool, true)
    }
    
    func testSetUserIdWithEmptyId() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.setUserId,
            arguments: ""
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
        if let error = resultData as? FlutterError {
            XCTAssertEqual(error.code, "INVALID_USER_ID")
        } else {
            XCTFail("Expected FlutterError with INVALID_USER_ID")
        }
    }
    
    func testOpenVirtusizeWebViewWithProductId() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.openVirtusizeWebView,
            arguments: "product123"
        )

        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }

        XCTAssertNotNil(resultData)
        XCTAssertEqual(resultData as? Bool, true)
    }
    
    func testOpenVirtusizeWebViewWithoutProductId() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.openVirtusizeWebView,
            arguments: nil
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
        if let error = resultData as? FlutterError {
            XCTAssertEqual(error.code, "NO_ARGUMENTS")
        } else {
            XCTFail("Expected FlutterError with NO_ARGUMENTS")
        }
    }
    
    func testGetPrivacyPolicyLink() {
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.getPrivacyPolicyLink,
            arguments: nil
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNotNil(resultData)
    }
    
    func testSendOrderWithSuccess() {
        let orderItems = [
            [
                "externalProductId": "A001",
                "size": "L",
                "sizeAlias": "Large",
                "variantId": "A001_SIZEL_RED",
                "imageUrl": "http://images.example.com/products/A001/red/image1xl.jpg",
                "color": "Red",
                "gender": "W",
                "unitPrice": 5100.00,
                "currency": "JPY",
                "quantity": 1,
                "url": "http://example.com/products/A001"
            ]
        ]
        
        let orderInfo = [
            "externalOrderId": "order123",
            "items": orderItems
        ] as [String : Any]
        
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.sendOrder,
            arguments: orderInfo
        )
        
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        XCTAssertNil(resultData, "Sending order with valid data should not return an error")
    }
    
    func testSendOrderWithMissingData() {
        let orderItems = [
            [
                "externalProductId": "A001",
                "size": "L",
                "sizeAlias": "Large",
                "variantId": "A001_SIZEL_RED",
                "imageUrl": "http://images.example.com/products/A001/red/image1xl.jpg",
                "color": "Red",
                "gender": "W",
                "unitPrice": 5100.00,
                "currency": "JPY",
                "quantity": 1,
                "url": "http://example.com/products/A001"
            ]
        ]
        
        let incompleteOrderInfo = [
            "items": orderItems
        ] as [String : Any]
        
        let call = FlutterMethodCall(
            methodName: VirtusizeFlutterMethod.sendOrder,
            arguments: incompleteOrderInfo
        )
        
        // When
        var resultData: Any?
        plugin.handle(call) { result in
            resultData = result
        }
        
        // Then
        XCTAssertNotNil(resultData, "Sending order with missing externalProductId should return an error")
        if let error = resultData as? FlutterError {
            XCTAssertEqual(error.code, "SEND_ORDER")
        } else {
            XCTFail("Expected FlutterError with SEND_ORDER")
        }
    }
}

class MockFlutterMethodChannel: FlutterMethodChannel {
    var lastMethod: String?
    var lastArguments: Any?
    var methodCalls: [String] = []
    
    override func invokeMethod(_ method: String, arguments: Any?) {
        lastMethod = method
        lastArguments = arguments
        methodCalls.append(method)
    }
}

class FlutterBinaryMessengerDummy: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}
    func send(onChannel channel: String, message: Data?, binaryReply: FlutterBinaryReply?) {}
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
        return 0
    }
    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}
