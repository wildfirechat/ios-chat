#!/bin/sh
TARGET_CLIENT_NAME=WFChatClient

set +e

CURRENT_PATH=`pwd`

PRG="$0"
PRGDIR=`dirname "$PRG"`
cd $PRGDIR

BUILD_DIR=`pwd`"/build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

#创建输出目录，并删除之前的framework文件
UNIVERSAL_OUTPUT_FOLDER=`pwd`"/Libs&Resources"
rm -rf "${UNIVERSAL_OUTPUT_FOLDER}"
mkdir -p "${UNIVERSAL_OUTPUT_FOLDER}"

#清理
cd wfclient
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" clean
xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" clean

xcodebuild -target ${TARGET_CLIENT_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" build

cd ..
xcodebuild -create-xcframework -framework "${BUILD_DIR}"/Release-iphoneos/"${TARGET_CLIENT_NAME}".framework  -output "${UNIVERSAL_OUTPUT_FOLDER}"/${TARGET_CLIENT_NAME}.xcframework

rm -rf "${BUILD_DIR}"

cd "${CURRENT_PATH}"
