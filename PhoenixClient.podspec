#
# Be sure to run `pod lib lint PhoenixClient.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PhoenixClient"
  s.version          = "0.2.0"
  s.summary          = "Phoenix Framework Channel Client"
  s.description      = <<-DESC
                        Phoenix Client allows ObjC based application to connect to Phoenix Framework channels over websocket.
                        More Information
                        https://github.com/phoenixframework/phoenix
                       DESC
  s.homepage         = "http://github.com/livehelpnow/ObjCPhoenixClient"
  s.license          = 'MIT'
  s.author           = { "Justin Schneck" => "jschneck@mac.com" }
  s.source           = { :git => "https://github.com/livehelpnow/ObjCPhoenixClient.git", :tag => "v#{s.version.to_s}"}

  s.osx.deployment_target	= '10.7'
  s.ios.deployment_target	= '7.0'

  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.dependency "SocketRocket", "0.3.1-beta2"
end
