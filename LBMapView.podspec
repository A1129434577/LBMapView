Pod::Spec.new do |spec|
  spec.name         = "LBMapView"
  spec.version      = "1.0.0"
  spec.summary      = "iOS原生地图"
  spec.description  = "一个iOS原生地图的再次封装，标记点支持固定于控件中心、或跟随地图移动，支持多点标记。"
  spec.homepage     = "https://github.com/A1129434577/LBMapView"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "刘彬" => "1129434577@qq.com" }
  spec.platform     = :ios
  spec.ios.deployment_target = '8.0'
  spec.source       = { :git => 'https://github.com/A1129434577/LBMapView.git', :tag => spec.version.to_s }
  spec.source_files = "LBMapView/**/*.{h,m}"
  spec.requires_arc = true
end
