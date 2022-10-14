//
//  WFCUBroadcastDefine.h
//  WFChatUIKit
//
//  Created by Rain on 2022/10/14.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#ifndef WFCUBroadcastDefine_h
#define WFCUBroadcastDefine_h

//broadcast发往container app的数据头
typedef struct {
    int dataType; //0 broadcast的状态；1 数据
    int dataLen;
} PacketHeader;

//broadcast发往container app的Sample数据
typedef struct {
    int dataLen;
    int width;
    int height;
    int type;  //0, video; 1, audio
} SampleInfo;

//container app发往broadcast的命令
typedef struct {
    int type; //0 旋转状态；1 是否发送音频；2 分辨率；3 结束
    int value;
} Command;
#endif /* WFCUBroadcastDefine_h */
