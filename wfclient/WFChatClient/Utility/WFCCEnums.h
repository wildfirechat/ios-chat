//
//  WFCCEnums.h
//  WFChatClient
//
//  Created by Heavyrian Lee on 2020/6/25.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#ifndef WFCCEnums_h
#define WFCCEnums_h

typedef NS_ENUM(NSInteger, WFCCErrorCode) {
    //0~255 server error
    ERROR_CODE_SUCCESS = 0,  // //"success"),
    ERROR_CODE_SECRECT_KEY_MISMATCH = 1,  //"secrect key mismatch"),
    ERROR_CODE_INVALID_DATA = 2,  //"invalid data"),
    ERROR_CODE_NODE_NOT_EXIST = 3,  //"node not exist"),
    ERROR_CODE_SERVER_ERROR = 4,  //"server error"),
    ERROR_CODE_NOT_MODIFIED = 5,  //"not modified"),

    //Auth error
    ERROR_CODE_TOKEN_ERROR = 6,  //"token error"),
    ERROR_CODE_USER_FORBIDDEN = 8,  //"user forbidden"),

    //Message error
    ERROR_CODE_NOT_IN_GROUP = 9,  //"not in group"),
    ERROR_CODE_INVALID_MESSAGE = 10,  //"invalid message"),

    //Group error
    ERROR_CODE_GROUP_ALREADY_EXIST = 11,  //"group aleady exist"),


    //user error
    ERROR_CODE_PASSWORD_INCORRECT = 15,  //"password incorrect"),

    //user error
    ERROR_CODE_FRIEND_ALREADY_REQUEST = 16,  //"already send request"),
    ERROR_CODE_FRIEND_REQUEST_BLOCKED = 18,  //"friend request blocked"),
    ERROR_CODE_FRIEND_REQUEST_EXPIRED = 19,  //"friend request expired"),

    ERROR_CODE_NOT_IN_CHATROOM = 20,  //"not in chatroom"),

    ERROR_CODE_NOT_IN_CHANNEL = 21,  //"not in channel"),

    ERROR_CODE_NOT_LICENSED = 22,  //"not licensed"),
    ERROR_CODE_ALREADY_FRIENDS = 23,  //"already friends"),

    ERROR_CODE_GROUP_EXCEED_MAX_MEMBER_COUNT = 240,  //"group exceed max member count"),
    ERROR_CODE_GROUP_MUTED = 241,  //"group is muted"),
    ERROR_CODE_SENSITIVE_MATCHED = 242,  //"sensitive matched"),
    ERROR_CODE_SIGN_EXPIRED = 243,  //"sign expired"),
    ERROR_CODE_AUTH_FAILURE = 244,  //"auth failure"),
    ERROR_CODE_CLIENT_COUNT_OUT_OF_LIMIT = 245,  //"client count out of limit"),
    ERROR_CODE_IN_BLACK_LIST = 246,  //"user in balck list"),
    ERROR_CODE_FORBIDDEN_SEND_MSG = 247,  //"forbidden send msg globally"),
    ERROR_CODE_NOT_RIGHT = 248,  //"no right to operate"),
    ERROR_CODE_TIMEOUT = 249,  //"timeout"),
    ERROR_CODE_OVER_FREQUENCY = 250,  //"over frequency"),
    ERROR_CODE_INVALID_PARAMETER = 251,  //"Invalid parameter"),
    ERROR_CODE_NOT_EXIST = 253,  //"not exist"),
    ERROR_CODE_NOT_IMPLEMENT = 254,  //"not implement"),

    //负值为mars返回错误
    ERROR_CODE_Local_TaskTimeout = -1,
    ERROR_CODE_Local_TaskRetry = -2,
    ERROR_CODE_Local_StartTaskFail = -3,
    ERROR_CODE_Local_AntiAvalanche = -4,
    ERROR_CODE_Local_ChannelSelect = -5,
    ERROR_CODE_Local_NoNet = -6,
    ERROR_CODE_Local_Cancel = -7,
    ERROR_CODE_Local_Clear = -8,
    ERROR_CODE_Local_Reset = -9,
    ERROR_CODE_Local_TaskParam = -12,
    ERROR_CODE_Local_CgiFrequcencyLimit = -13,
    ERROR_CODE_Local_ChannelID = -14,

    ERROR_CODE_Long_FirstPkgTimeout = -500,
    ERROR_CODE_Long_PkgPkgTimeout = -501,
    ERROR_CODE_Long_ReadWriteTimeout = -502,
    ERROR_CODE_Long_TaskTimeout = -503,

    ERROR_CODE_Socket_NetworkChange = -10086,
    ERROR_CODE_Socket_MakeSocketPrepared = -10087,
    ERROR_CODE_Socket_WritenWithNonBlock = -10088,
    ERROR_CODE_Socket_ReadOnce = -10089,
    ERROR_CODE_Socket_RecvErr = -10091,
    ERROR_CODE_Socket_SendErr = -10092,
    ERROR_CODE_Socket_NoopTimeout = -10093,
    ERROR_CODE_Socket_NoopAlarmTooLate = -10094,
    ERROR_CODE_Http_SplitHttpHeadAndBody = -10194,
    ERROR_CODE_Http_ParseStatusLine = -10195,
    ERROR_CODE_Net_MsgXPHandleBufferErr = -10504,
    ERROR_CODE_Dns_MakeSocketPrepared = -10606,

    //proto error code
    ERROR_CODE_Proto_CorruptData = -100001,
    ERROR_CODE_Proto_InvalideParameter = -100002,
    //消息内容超过最大值，最大值为200KB，建议不超过15KB。
    ERROR_CODE_Proto_Content_Exceed_Max_Size = -100003,
    //媒体内容超过最大值，最大值为100MB
    ERROR_CODE_Proto_Media_Exceed_Max_Size = -100004,
};

#endif /* WFCCEnums_h */
