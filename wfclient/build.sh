#!/bin/sh
#要build的target名
TARGET_NAME=${PROJECT_NAME}
if [[ $1 ]]
then
TARGET_NAME=$1
fi
UNIVERSAL_OUTPUT_FOLDER="${SRCROOT}/${PROJECT_NAME}_Products/"

#创建输出目录，并删除之前的framework文件
mkdir -p "${UNIVERSAL_OUTPUT_FOLDER}"
rm -rf "${UNIVERSAL_OUTPUT_FOLDER}/${TARGET_NAME}.framework"

#分别编译模拟器和真机的Framework
xcodebuild -target "${TARGET_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -target "${TARGET_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

#拷贝framework到univer目录
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework" "${UNIVERSAL_OUTPUT_FOLDER}"

#合并framework，输出最终的framework到build目录
lipo -create -output "${UNIVERSAL_OUTPUT_FOLDER}/${TARGET_NAME}.framework/${TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/${TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${TARGET_NAME}.framework/${TARGET_NAME}"

#删除编译之后生成的无关的配置文件
dir_path="${UNIVERSAL_OUTPUT_FOLDER}/${TARGET_NAME}.framework/"
for file in ls $dir_path
do
if [[ ${file} =~ ".xcconfig" ]]
then
rm -f "${dir_path}/${file}"
fi
done

#判断build文件夹是否存在，存在则删除
if [ -d "${SRCROOT}/build" ]
then
rm -rf "${SRCROOT}/build"
fi

rm -rf "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator" "${BUILD_DIR}/${CONFIGURATION}-iphoneos"

#打开合并后的文件夹
open "${UNIVERSAL_OUTPUT_FOLDER}"
