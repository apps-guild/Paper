Pod::Spec.new do |s|
  s.name             = "Paper"
  s.version          = "0.1.0"
  s.summary          = "An Objective-C port of Paper.js"
  s.description      = <<-DESC
                       The beginning of an Objective-C port of Paper.js.
                       Designed to readily merge changes from the original Paper.js source.
                       DESC
  s.homepage         = "http://paperjs.org/"
  s.license          = 'MIT'
  s.author           = { "Nat Brown" => "natbro@gmail.com" }
  s.source           = { :git => "https://github.com/apps-guild/Paper.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/natbro'

  s.platform     = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.requires_arc = true

  s.source_files = 'Classes'
end
