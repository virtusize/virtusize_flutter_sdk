#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint virtusize_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'virtusize_flutter_sdk'
  s.version          = '2.0.0'
  s.summary          = 'Virtusize SDK for Flutter.'
  s.description      = <<-DESC
This SDK helps clients to integrate Virtusize’s size and fit service into their Flutter applications for Android & iOS.
                       DESC
  s.homepage         = 'https://github.com/virtusize/virtusize_flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Virtusize' => 'client.support@virtusize.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Virtusize', '~> 2.12.1'
  s.static_framework = true
  
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
