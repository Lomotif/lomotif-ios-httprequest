Pod::Spec.new do |s|

    s.platform = :ios
    s.ios.deployment_target = '8.0'
    s.name = "HttpRequest"
    s.summary = "HttpRequest handles Lomotif iOS http request."
    s.requires_arc = true
    s.version = "0.1.0"
    s.license = { :type => "MIT", :file => "LICENSE" }
    s.author = { "Casey Law" => "casey@lomotif.com" }
    s.homepage = "http://ww.lomotif.com"
    s.source = { :git => "https://github.com/Lomotif/lomotif-ios-httprequest.git", :tag => "#{s.version}"}
    s.framework = "UIKit"
    s.dependency 'Alamofire'
    s.dependency 'AlamofireImage'
    s.source_files = "HttpRequest/**/*.{swift}"

end