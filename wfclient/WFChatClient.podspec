Pod::Spec.new do |s|
  s.name             = 'WFChatClient'
  s.version          = '1.0'
  s.summary          = 'IM的通讯能力库。'
  s.description      = <<-DESC
    ChatClient提供IM能力，另外附加群组关系托管，用户信息托管和好友关系托管，只提供能力，不包括UI界面。
                       DESC

  s.homepage         = 'https://github.com/wildfirechat/ios-chat'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'dklinzh' => 'linzhdk@gmail.com' }
  s.source           = { :git => 'https://github.com/wildfirechat/ios-chat.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.swift_version = '5.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'WFChatClient/*.h'
  s.frameworks = 'CoreTelephony'
  s.libraries = 'z', 'c++', 'resolv'
  
  s.subspec 'Proto' do |ss|
    ss.vendored_frameworks = 'WFChatClient/Proto/**/*.framework'
  end

  s.subspec 'Messages' do |ss|
    ss.source_files = 'WFChatClient/Messages/**/*.{h,m}'
  end

  s.subspec 'Model' do |ss|
    ss.source_files = 'WFChatClient/Model/**/*.{h,m}'
  end

  s.subspec 'Utility' do |ss|
    ss.source_files = 'WFChatClient/Utility/**/*.{h,m}'
  end

  s.subspec 'Client' do |ss|
    ss.source_files = 'WFChatClient/Client/**/*.{h,m,mm}'
  end

  s.subspec 'amr' do |ss|
    ss.source_files = 'WFChatClient/amr/**/*.{h,c,mm}'
    ss.vendored_libraries = 'WFChatClient/amr/**/*.a'
  end

end