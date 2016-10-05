platform :ios, '8.0'
use_frameworks!

def shared_pods
    pod 'Alamofire', :git => 'https://github.com/Lomotif/Alamofire.git'
    pod 'SwiftyBeaver'
end

target 'HttpRequest' do
    shared_pods
    pod 'HanekeSwift', :git => 'https://github.com/jasonnoahchoi/HanekeSwift', :branch => 'swift3'
end

target 'HttpRequestTests' do
    shared_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
