#!/bin/sh
TARGET_CLIENT_NAME=WFChatClient
TARGET_UIKIT_NAME=WFChatUIKit

BUILD_DIR=`pwd`"/build"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

UNIVERSAL_OUTPUT_FOLDER=`pwd`"/Libs&Resources"

#创建输出目录，并删除之前的framework文件
rm -rf ${UNIVERSAL_OUTPUT_FOLDER}
mkdir -p ${UNIVERSAL_OUTPUT_FOLDER}

#清理
cd wfclient
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" clean
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" clean
cd ../wfuikit
xcodebuild -target ${TARGET_UIKIT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" clean
xcodebuild -target ${TARGET_UIKIT_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" clean


#分别编译模拟器和真机的Framework
cd ../wfclient
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" build
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" build
cd ../wfuikit
xcodebuild -target ${TARGET_UIKIT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" build
xcodebuild -target ${TARGET_UIKIT_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" build

cd ..
xcodebuild -create-xcframework -framework "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework  -framework "${BUILD_DIR}"/Release-iphonesimulator/"${TARGET_CLIENT_NAME}".framework  -output "${UNIVERSAL_OUTPUT_FOLDER}"/${TARGET_CLIENT_NAME}.xcframework
xcodebuild -create-xcframework -framework "${BUILD_DIR}"/Release-iphoneos/"${TARGET_UIKIT_NAME}".framework  -framework "${BUILD_DIR}"/Release-iphonesimulator/"${TARGET_UIKIT_NAME}".framework  -output "${UNIVERSAL_OUTPUT_FOLDER}"/${TARGET_UIKIT_NAME}.xcframework

rm -rf $BUILD_DIR

##资源
cp -af wfuikit/WFChatUIKit/Resources ${UNIVERSAL_OUTPUT_FOLDER}

##依赖
cp -af wfuikit/WFChatUIKit/AVEngine/WebRTC.xcframework ${UNIVERSAL_OUTPUT_FOLDER}
cp -af wfuikit/WFChatUIKit/AVEngine/WFAVEngineKit.xcframework ${UNIVERSAL_OUTPUT_FOLDER}
cp -af wfuikit/WFChatUIKit/Vendor/ZLPhotoBrowser/ZLPhotoBrowser.xcframework ${UNIVERSAL_OUTPUT_FOLDER}
cp -af wfuikit/WFChatUIKit/Vendor/SDWebImage/SDWebImage.xcframework ${UNIVERSAL_OUTPUT_FOLDER}

#打开合并后的文件夹
open "${UNIVERSAL_OUTPUT_FOLDER}"
