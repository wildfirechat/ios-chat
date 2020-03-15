cd Frameworks

echo "朋友圈的库如果不存在，脚本会报错误，可以忽略掉！"
echo "打包时一定只能打开wfchat项目进行打包，不能打开ios-chat空间进行打包，原因请参考文档中的常见问题"

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

cd ../WildFireChat/Moments
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

cd ../../Frameworks

#lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin armv7 -output XXXX_armv7
lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin arm64 -output XXXX_arm64
#lipo -create XXXX_armv7 XXXX_arm64 -output XXXX
mv XXXX_arm64 GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC
rm -rf XXXX*

echo "朋友圈的库如果不存在，脚本会报错误，可以忽略掉！"
echo "执行这个脚本后，打包时一定不要打开ios-chat这个项目空间进行打包，因为会重新生成这些被瘦身的库。要打开wfchat这个项目进行打包！"
