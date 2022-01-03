#!/bin/sh

DST_DIR="./../wfchat/Frameworks"
if [ ! -d "$DST_DIR" ]; then
    mkdir -p "$DST_DIR"
fi

cp -af WFChatUIKit/Resources/*  ${DST_DIR}/
cp -af WFChatUIKit/Vendor/ZLPhotoBrowser/*  ${DST_DIR}/
