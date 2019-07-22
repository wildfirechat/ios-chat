Pod::Spec.new do |s|
  s.name             = 'WFChatUIKit'
  s.version          = '1.0'
  s.summary          = 'IIM的UI控件库，依赖于chatclient。'
  s.description      = <<-DESC
    ChatUIKit提供常用的UI界面，客户可以直接使用ChatUIKit的UI来进行二次开发。
                       DESC

  s.homepage         = 'https://github.com/wildfirechat/ios-chat'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'dklinzh' => 'linzhdk@gmail.com' }
  s.source           = { :git => 'https://github.com/wildfirechat/ios-chat.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.ios.deployment_target = '8.0'

  s.prefix_header_file = 'WFChatUIKit/Predefine.h'
  s.private_header_files = 'WFChatUIKit/Predefine.h'
  s.source_files = 'WFChatUIKit/*.{h,m}'
  s.resources = 'WFChatUIKit/Resources/*.{xcassets}'
  s.dependency 'WFChatClient'

  s.subspec 'AVEngine' do |ss|
    ss.vendored_frameworks = 'WFChatUIKit/AVEngine/**/*.framework'
    ss.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -framework WFAVEngineKit -framework WebRTC'
    }
  end

  s.subspec 'Channel' do |ss|
    ss.source_files = 'WFChatUIKit/Channel/**/*.{h,m}'
  end

  s.subspec 'Voip' do |ss|
    ss.dependency 'WFChatUIKit/AVEngine'
    ss.source_files = 'WFChatUIKit/Voip/**/*.{h,m}'
  end

  s.subspec 'SelectMentionVC' do |ss|
    ss.source_files = 'WFChatUIKit/SelectMentionVC/**/*.{h,m}'
  end

  s.subspec 'AddFriend' do |ss|
    ss.source_files = 'WFChatUIKit/AddFriend/**/*.{h,m}'
  end

  s.subspec 'Category' do |ss|
    ss.source_files = 'WFChatUIKit/Category/**/*.{h,m}'
  end

  s.subspec 'CommonVC' do |ss|
    ss.source_files = 'WFChatUIKit/CommonVC/**/*.{h,m}'
  end

  s.subspec 'Contacts' do |ss|
    ss.source_files = 'WFChatUIKit/Contacts/**/*.{h,m}'
  end

  s.subspec 'ConversationList' do |ss|
    ss.source_files = 'WFChatUIKit/ConversationList/**/*.{h,m}'
  end

  s.subspec 'ConversationSetting' do |ss|
    ss.source_files = 'WFChatUIKit/ConversationSetting/**/*.{h,m}'
  end

  s.subspec 'CreateGroup' do |ss|
    ss.source_files = 'WFChatUIKit/CreateGroup/**/*.{h,m}'
  end

  s.subspec 'ForwardMessage' do |ss|
    ss.source_files = 'WFChatUIKit/ForwardMessage/**/*.{h,m}'
    ss.resources = 'WFChatUIKit/Resources/WFCUShareMessageView.xib'
  end

  s.subspec 'FriendRequest' do |ss|
    ss.source_files = 'WFChatUIKit/FriendRequest/**/*.{h,m}'
  end

  s.subspec 'Group' do |ss|
    ss.source_files = 'WFChatUIKit/Group/**/*.{h,m}'
  end

  s.subspec 'Me' do |ss|
    ss.source_files = 'WFChatUIKit/Me/**/*.{h,m}'
  end

  s.subspec 'MessageList' do |ss|
    ss.source_files = 'WFChatUIKit/MessageList/**/*.{h,m}'
  end

  s.subspec 'Utilities' do |ss|
    ss.source_files = 'WFChatUIKit/Utilities/**/*.{h,m}'
  end

  s.subspec 'Vendor' do |ss|

    ss.subspec 'ChatInputBar' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/ChatInputBar/**/*.{h,m}'
      sss.resources = 'WFChatUIKit/Resources/Stickers.bundle', 'WFChatUIKit/Resources/Emoj.plist'
    end

    ss.subspec 'CCHMapClusterController' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/CCHMapClusterController/**/*.{h,m}'
    end

    ss.subspec 'Pinyin' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/Pinyin/**/*.{h,c}'
    end

    ss.subspec 'VideoPlayerKit' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/VideoPlayerKit/**/*.{h,m}'
    end

    ss.subspec 'KZSmallVideoRecorder' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/KZSmallVideoRecorder/**/*.{h,m}'
    end

    ss.subspec 'SDPhotoBrowser' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/SDPhotoBrowser/**/*.{h,m}'
    end

    ss.subspec 'KxMenu' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/KxMenu/**/*.{h,m}'
    end

    ss.subspec 'AFNetworking' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/AFNetworking/**/*.{h,m}'
    end

    ss.subspec 'MBProgressHUD' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/MBProgressHUD/**/*.{h,m}'
    end

    ss.subspec 'SDRefeshView' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/SDRefeshView/**/*.{h,m}'
    end

    ss.subspec 'UITextViewPlaceholder' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/UITextViewPlaceholder/**/*.{h,m}'
    end

    ss.subspec 'SDWebImage' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/SDWebImage/**/*.{h,m}'
    end

    ss.subspec 'TYAlertController' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/TYAlertController/**/*.{h,m}'
    end

    ss.subspec 'YLGIFImage' do |sss|
      sss.source_files = 'WFChatUIKit/Vendor/YLGIFImage/**/*.{h,m}'
    end

  end

end
