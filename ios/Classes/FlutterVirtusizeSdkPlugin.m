#import "FlutterVirtusizeSdkPlugin.h"
#if __has_include(<flutter_virtusize_sdk/flutter_virtusize_sdk-Swift.h>)
#import <flutter_virtusize_sdk/flutter_virtusize_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_virtusize_sdk-Swift.h"
#endif

@implementation FlutterVirtusizeSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterVirtusizeSdkPlugin registerWithRegistrar:registrar];
}
@end
