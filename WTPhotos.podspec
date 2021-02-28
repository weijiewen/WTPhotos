#
# Be sure to run `pod lib lint WTPhotos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WTPhotos'
  s.version          = '1.0.3'
  s.summary          = '我在仰望 月亮之上 有多少梦想在自由地飞翔.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
我等待我想象 我的灵魂早已脱僵
马蹄声起 马蹄声落
Oh yeah, oh yeah
看见的看不见的 瞬间的永恒的
青草长啊 大雪飘扬
Oh yeah, oh yeah
谁在呼唤 情深意长
让我的渴望象白云在飘荡
东边牧马 西边放羊
野辣辣的情歌就唱到了天亮
在日月沧桑后 你在谁身旁
用温柔眼光 让黑夜绚烂
                       DESC

  s.homepage         = 'https://github.com/weijiewen/WTPhotos'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'txywjw@icloud.com' => 'txywjw@icloud.com' }
  s.source           = { :git => 'https://github.com/weijiewen/WTPhotos.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'WTPhotos/Classes/**/*'
  
  # s.resource_bundles = {
  #   'WTPhotos' => ['WTPhotos/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
