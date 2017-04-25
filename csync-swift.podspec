#
# Be sure to run `pod lib lint csync-swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'csync-swift'
  s.version          = '1.3.0'
  s.summary          = 'Contextual Sync (CSync) SDK for iOS/macOS/tvOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Contextual Sync (CSync) is an open source, real-time, continuous data synchronization service for building modern applications. The CSync data store is organized with key/values where keys have a hierarchical structure. Clients can obtain the current value for a key and any subsequent updates by listening on the key. Updates are delivered to all online clients in near-real time. Clients can also listen on a key pattern where some components contain wildcards.
                       DESC

  s.homepage         = 'http://csync.io'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'dfirsht' => 'dfirsht@us.ibm.com' }
  s.source           = { :git => 'https://github.com/csync/csync-swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'CSyncSDK/**/*'
  
  # s.resource_bundles = {
  #   'csync-swift' => ['csync-swift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SwiftWebSocket', '~> 2.6.0'
  s.dependency 'SQLite.swift', '~> 0.11.0'
end
