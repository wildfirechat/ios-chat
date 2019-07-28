cd Frameworks

#lipo WFChatUIKit.framework/WFChatUIKit -thin armv7 -output XXXX_armv7
lipo WFChatUIKit.framework/WFChatUIKit -thin arm64 -output XXXX_arm64
#lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 WFChatUIKit.framework/WFChatUIKit
rm -rf XXXX*

# lipo WFAVEngineKit.framework/WFAVEngineKit -thin armv7 -output XXXX_armv7
lipo WFAVEngineKit.framework/WFAVEngineKit -thin arm64 -output XXXX_arm64
# lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 WFAVEngineKit.framework/WFAVEngineKit
rm -rf XXXX*

# lipo WFChatClient.framework/WFChatClient -thin armv7 -output XXXX_armv7
lipo WFChatClient.framework/WFChatClient -thin arm64 -output XXXX_arm64
# lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 WFChatClient.framework/WFChatClient
rm -rf XXXX*

#lipo WFMomentClient.framework/WFMomentClient -thin armv7 -output XXXX_armv7
lipo WFMomentClient.framework/WFMomentClient -thin arm64 -output XXXX_arm64
#lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 WFMomentClient.framework/WFMomentClient
rm -rf XXXX*

# lipo WFMomentUIKit.framework/WFMomentUIKit -thin armv7 -output XXXX_armv7
lipo WFMomentUIKit.framework/WFMomentUIKit -thin arm64 -output XXXX_arm64
# lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 WFMomentUIKit.framework/WFMomentUIKit
rm -rf XXXX*


#lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin armv7 -output XXXX_armv7
lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin arm64 -output XXXX_arm64
#lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC
rm -rf XXXX*
