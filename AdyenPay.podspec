Pod::Spec.new do |s|
  s.name = 'AdyenPay'
  s.version = '1.1.0'
  s.summary = 'AdyenPay framework for integrating ApplePay and AdyenPay payments'
  s.license = 'LICENSE'
  s.authors = {"Adyen B.V."=>"http://adyen.com"}
  s.homepage = 'http://adyen.com'
  s.frameworks = 'PassKit'
  s.requires_arc = true
  s.source = {
    :git => "https://github.com/adyenpayments/AdyenPay-iOS.git", :tag => s.version.to_s }

  s.platform = :ios, '8.1'
  s.ios.platform             = :ios, '8.1'
  s.ios.preserve_paths       = 'AdyenPay.framework'
  s.ios.public_header_files  = 'AdyenPay.framework/Versions/A/Headers/*.h'
  # s.ios.resource             = 'AdyenPay.framework/Versions/A/Resources/**/*'
  s.ios.vendored_frameworks  = 'AdyenPay.framework'
end
