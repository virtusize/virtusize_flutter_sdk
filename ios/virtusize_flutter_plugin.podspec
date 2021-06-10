#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint virtusize_flutter_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'virtusize_flutter_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Virtusize integration in Flutter'
  s.description      = <<-DESC
Virtusize integration in Flutter
                       DESC
  s.homepage         = 'https://www.virtusize.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Virtusize' => 'client.support@virtusize.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Virtusize', '~> 2.2.1'
  s.platform = :ios, '10.3'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
