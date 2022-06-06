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
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" clean build
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch x86_64 -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" clean build

lipo -create "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework/"${TARGET_CLIENT_NAME}"  "${BUILD_DIR}"/Release-iphonesimulator/"${TARGET_CLIENT_NAME}".framework/"${TARGET_CLIENT_NAME}"  -output "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework/tmp_bin
mv -f "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework/tmp_bin "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework/"${TARGET_CLIENT_NAME}"
mv -f "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework "${UNIVERSAL_OUTPUT_FOLDER}"

rm -rf $BUILD_DIR

#打开合并后的文件夹
open "${UNIVERSAL_OUTPUT_FOLDER}"
