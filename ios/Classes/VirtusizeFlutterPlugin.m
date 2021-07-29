#import "VirtusizeFlutterPlugin.h"
#if __has_include(<virtusize_flutter_sdk/virtusize_flutter_sdk-Swift.h>)
#import <virtusize_flutter_sdk/virtusize_flutter_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "virtusize_flutter_sdk-Swift.h"
#endif

@implementation VirtusizeFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftVirtusizeFlutterPlugin registerWithRegistrar:registrar];
}
@end
