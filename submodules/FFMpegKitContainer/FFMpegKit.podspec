Pod::Spec.new do |s|
  s.name         = "FFMpegKit"
  s.version      = "1.0.0"
  s.summary      = "FFMpegKit"
  s.description  = "FFMpegKit is a cumulative SDK to merge all FFMpegKit the SDKs."
  s.homepage     = "https://pubgi.fanapsoft.ir/chat/ios/chat-ap-models"
  s.license      = "MIT"
  s.author       = { "Hamed Hosseini" => "hamed8080@gmail.com" }
  s.platform     = :ios, "10.0"
  s.swift_versions = "4.0"
  s.source       = { :git => "https://pubgi.fanapsoft.ir/chat/ios/chat-ap-models", :tag => s.version }
  s.source_files = "Sources/Additive/**/*.{h,swift,xcdatamodeld,m,momd}"
  s.frameworks  = "Foundation"
  s.dependency "Chat", '~> 2.0.0'
end
