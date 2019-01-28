cd Frameworks

lipo WFChatUIKit.framework/WFChatUIKit -thin armv7 -output XXXX_armv7
lipo WFChatUIKit.framework/WFChatUIKit -thin arm64 -output XXXX_arm64
lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX WFChatUIKit.framework/WFChatUIKit
rm -rf XXXX*

lipo WFAVEngineKit.framework/WFAVEngineKit -thin armv7 -output XXXX_armv7
lipo WFAVEngineKit.framework/WFAVEngineKit -thin arm64 -output XXXX_arm64
lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX WFAVEngineKit.framework/WFAVEngineKit
rm -rf XXXX*

lipo WFChatClient.framework/WFChatClient -thin armv7 -output XXXX_armv7
lipo WFChatClient.framework/WFChatClient -thin arm64 -output XXXX_arm64
lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX WFChatClient.framework/WFChatClient
rm -rf XXXX*

lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin armv7 -output XXXX_armv7
lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin arm64 -output XXXX_arm64
lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC
rm -rf XXXX*
