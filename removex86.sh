cd wfchat/WildFireChat/SDWebImage
lipo SDWebImage.framework/SDWebImage -thin arm64 -output XXXX_arm64
mv XXXX_arm64 SDWebImage.framework/SDWebImage
rm -rf XXXX_arm64
cd ../../../


cd wfuikit/WFChatUIKit/AVEngine/
lipo WFAVEngineKit.framework/WFAVEngineKit -thin arm64 -output XXXX_arm64
mv XXXX_arm64 WFAVEngineKit.framework/WFAVEngineKit
rm -rf XXXX_arm64

lipo GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC -thin arm64 -output XXXX_arm64
mv XXXX_arm64 GoogleWebRTC/Frameworks/frameworks/WebRTC.framework/WebRTC
rm -rf XXXX_arm64

cd ../Vendor/ZLPhotoBrowser
lipo ZLPhotoBrowser.framework/ZLPhotoBrowser -thin arm64 -output XXXX_arm64
mv XXXX_arm64 ZLPhotoBrowser.framework/ZLPhotoBrowser
rm -rf XXXX_arm64

cd ../../../../

echo "Done!"
