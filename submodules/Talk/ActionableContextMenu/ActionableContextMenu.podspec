Pod::Spec.new do |s|
  s.name         = "ActionableContextMenu"
  s.version      = "1.0.0"
  s.summary      = "ActionableContextMenu"
  s.description  = "A context menu with an actionable view on the top/bottom."
  s.homepage     = "https://pubgi.fanapsoft.ir/chat/ios/actionable-context-menu"
  s.license      = "MIT"
  s.author       = { "Hamed Hosseini" => "hamed8080@gmail.com" }
  s.platform     = :ios, "10.0"
  s.swift_versions = "4.0"
  s.source       = { :git => "https://pubgi.fanapsoft.ir/chat/ios/actionable-context-menu", :tag => s.version }
  s.source_files = "Sources/ActionableContextMenu/**/*.{h,swift,xcdatamodeld,m,momd}"
  s.frameworks  = "Foundation"
end
