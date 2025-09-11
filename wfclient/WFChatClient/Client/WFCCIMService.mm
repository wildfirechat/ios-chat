//
//  WFCCIMService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCIMService.h"
#import "WFCCMediaMessageContent.h"
#import <proto/MessageDB.h>
#import <objc/runtime.h>
#import "WFCCNetworkService.h"
#import <app/app.h>
#import "WFCCGroupSearchInfo.h"
#import "WFCCUnknownMessageContent.h"
#import "WFCCRecallMessageContent.h"
#import "WFCCMarkUnreadMessageContent.h"
#import "wav_amr.h"
#import "WFCCUserOnlineState.h"
#import "WFAFNetworking.h"
#import "WFCCRawMessageContent.h"
#import "WFCCTextMessageContent.h"
#import "WFCCFileMessageContent.h"
#import "WFCCNetworkService.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *kSendingMessageStatusUpdated = @"kSendingMessageStatusUpdated";
NSString *kUploadMediaMessageProgresse = @"kUploadMediaMessageProgresse";
NSString *kConnectionStatusChanged = @"kConnectionStatusChanged";
NSString *kReceiveMessages = @"kReceiveMessages";
NSString *kRecallMessages = @"kRecallMessages";
NSString *kDeleteMessages = @"kDeleteMessages";
NSString *kMessageDelivered = @"kMessageDelivered";
NSString *kMessageReaded = @"kMessageReaded";
NSString *kMessageUpdated = @"kMessageUpdated";


class IMSendMessageCallback : public mars::stn::SendMsgCallback {
public:
    void(^m_successBlock)(long long messageUid, long long timestamp);
    void(^m_errorBlock)(int error_code);
    void(^m_progressBlock)(long uploaded, long total);
    void(^m_uploadedBlock)(NSString *remoteUrl);
    WFCCMessage *m_message;

    IMSendMessageCallback(WFCCMessage *message, void(^successBlock)(long long messageUid, long long timestamp), void(^progressBlock)(long uploaded, long total), void(^uploadedBlock)(NSString *remoteUrl), void(^errorBlock)(int error_code)) : mars::stn::SendMsgCallback(), m_message(message), m_successBlock(successBlock), m_progressBlock(progressBlock), m_errorBlock(errorBlock), m_uploadedBlock(uploadedBlock) {};
     void onSuccess(long long messageUid, long long timestamp) {
        dispatch_async(dispatch_get_main_queue(), ^{
            m_message.messageUid = messageUid;
            m_message.serverTime = timestamp;
            m_message.status = Message_Status_Sent;
            if (m_successBlock) {
                m_successBlock(messageUid, timestamp);
            }
            if(m_message.messageId) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(m_message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":m_message}];
            }
            delete this;

        });
     }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            m_message.status = Message_Status_Send_Failure;
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            if(m_message.messageId) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(m_message.messageId) userInfo:@{@"status":@(Message_Status_Send_Failure), @"message":m_message, @"errorCode":@(errorCode)}];
            }
            delete this;
        });
    }
    void onPrepared(long messageId, int64_t savedTime) {
        m_message.messageId = messageId;
        m_message.serverTime = savedTime;
        if(messageId) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(messageId) userInfo:@{@"status":@(Message_Status_Sending), @"message":m_message, @"savedTime":@(savedTime)}];
            });
        }
    }
    void onMediaUploaded(const std::string &remoteUrl) {
        NSString *ru = [NSString stringWithUTF8String:remoteUrl.c_str()];
        if ([WFCCNetworkService sharedInstance].urlRedirector) {
            ru = [[WFCCNetworkService sharedInstance].urlRedirector redirect:ru];
        }
        
        if ([m_message.content isKindOfClass:[WFCCMediaMessageContent class]]) {
            WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)m_message.content;
            mediaContent.remoteUrl = ru;
        }
        long messageId = m_message.messageId;
        if(messageId) {
            if (m_uploadedBlock) {
                m_uploadedBlock(ru);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kUploadMediaMessageProgresse object:@(messageId) userInfo:@{@"progress":@(1), @"finish":@(YES), @"message":m_message, @"remoteUrl":ru}];
        }
    }
    
    void onProgress(int uploaded, int total) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_progressBlock) {
                m_progressBlock(uploaded, total);
            }
            if(m_message.messageId) {
                float progress = (uploaded * 1.f)/total;
                [[NSNotificationCenter defaultCenter] postNotificationName:kUploadMediaMessageProgresse object:@(m_message.messageId) userInfo:@{@"progress":@(progress), @"finish":@(NO), @"message":m_message, @"uploaded":@(uploaded), @"total":@(total)}];
            }
        });
    }
    
    virtual ~IMSendMessageCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
        m_progressBlock = nil;
        m_uploadedBlock = nil;
        m_message = nil;
    }
};


@interface WFCUUploadModel : NSObject <NSURLSessionDelegate> {
@public
    IMSendMessageCallback *_sendCallback;
}

@property(nonatomic, strong)NSURLSessionUploadTask *uploadTask;
@property(nonatomic, assign)int fileSize;
@property(nonatomic, assign)int expireDuration;
@end

@implementation WFCUUploadModel
- (void)didUploaded:(NSString *)remoteUrl {
    WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)self->_sendCallback->m_message.content;
    mediaContent.remoteUrl = remoteUrl;
    [[WFCCIMService sharedWFCIMService] updateMessage:self->_sendCallback->m_message.messageId content:self->_sendCallback->m_message.content];
    self->_sendCallback->onMediaUploaded([remoteUrl UTF8String]);
    [[WFCCIMService sharedWFCIMService] sendSavedMessage:self->_sendCallback->m_message expireDuration:self.expireDuration success:self->_sendCallback->m_successBlock error:self->_sendCallback->m_errorBlock];
    delete self->_sendCallback;
}

- (void)didUploadedFailed:(int)errorCode {
    [[WFCCIMService sharedWFCIMService] updateMessage:self->_sendCallback->m_message.messageId status:Message_Status_Send_Failure];
    self->_sendCallback->onFalure(errorCode);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                                didSendBodyData:(int64_t)bytesSent
                                 totalBytesSent:(int64_t)totalBytesSent
                       totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    dispatch_async(dispatch_get_main_queue(), ^{
        float uploadProgress = totalBytesSent * 1.f / self.fileSize;
        NSLog(@"upload progress %f", uploadProgress);
        self->_sendCallback->onProgress((int)totalBytesSent, self.fileSize);
    });
}

@end


@interface WFCUUploaDatadModel : NSObject <NSURLSessionDelegate> {
@public
    void(^m_errorBlock)(int error_code);
    void(^m_progressBlock)(long uploaded, long total);
    void(^m_uploadedBlock)(NSString *remoteUrl);
}

@property(nonatomic, strong)NSURLSessionUploadTask *uploadTask;
@property(nonatomic, assign)int fileSize;
@end

@implementation WFCUUploaDatadModel
- (void)didUploaded:(NSString *)remoteUrl {
    if(m_uploadedBlock) {
        m_uploadedBlock(remoteUrl);
    }
}

- (void)didUploadedFailed:(int)errorCode {
    if(m_errorBlock) {
        m_errorBlock(errorCode);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                                didSendBodyData:(int64_t)bytesSent
                                 totalBytesSent:(int64_t)totalBytesSent
                       totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if(m_progressBlock) {
        float uploadProgress = totalBytesSent * 1.f / self.fileSize;
        m_progressBlock((int)totalBytesSent, self.fileSize);
    }
}
@end


extern WFCCUserInfo* convertUserInfo(const mars::stn::TUserInfo &tui);


class IMCreateGroupCallback : public mars::stn::CreateGroupCallback {
private:
    void(^m_successBlock)(NSString *groupId);
    void(^m_errorBlock)(int error_code);
public:
    IMCreateGroupCallback(void(^successBlock)(NSString *groupId), void(^errorBlock)(int error_code)) : mars::stn::CreateGroupCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::string &groupId) {
        NSString *nsstr = [NSString stringWithUTF8String:groupId.c_str()];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(nsstr);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMCreateGroupCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGeneralOperationCallback : public mars::stn::GeneralOperationCallback {
private:
    void(^m_successBlock)();
    void(^m_errorBlock)(int error_code);
public:
    IMGeneralOperationCallback(void(^successBlock)(), void(^errorBlock)(int error_code)) : mars::stn::GeneralOperationCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess() {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock();
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMGeneralOperationCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGeneralStringCallback : public mars::stn::GeneralStringCallback {
private:
    void(^m_successBlock)(NSString *generalStr);
    void(^m_errorBlock)(int error_code);
public:
    IMGeneralStringCallback(void(^successBlock)(NSString *groupId), void(^errorBlock)(int error_code)) : mars::stn::GeneralStringCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::string &str) {
        NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(nsstr);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMGeneralStringCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGeneralStringListCallback : public mars::stn::GeneralStringListCallback {
private:
    void(^m_successBlock)(NSArray<NSString *> *stringArray);
    void(^m_errorBlock)(int error_code);
public:
    IMGeneralStringListCallback(void(^successBlock)(NSArray<NSString *> *stringArray), void(^errorBlock)(int error_code)) : mars::stn::GeneralStringListCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<std::string> &strs) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it = strs.begin(); it != strs.end(); ++it) {
            [arr addObject:[NSString stringWithUTF8String:it->c_str()]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(arr);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMGeneralStringListCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMLoadRemoteDomainsCallback : public mars::stn::LoadRemoteDomainsCallback {
private:
    void(^m_successBlock)(NSArray<WFCCDomainInfo *> *domains);
    void(^m_errorBlock)(int error_code);
public:
    IMLoadRemoteDomainsCallback(void(^successBlock)(NSArray<WFCCDomainInfo *> *domains), void(^errorBlock)(int error_code)) : mars::stn::LoadRemoteDomainsCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TDomainInfo> &domainlist) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TDomainInfo>::const_iterator it = domainlist.begin(); it != domainlist.end(); ++it) {
            WFCCDomainInfo *domainInfo = [[WFCCDomainInfo alloc] init];
            domainInfo.domainId = [NSString stringWithUTF8String:it->domainId.c_str()];
            domainInfo.name = [NSString stringWithUTF8String:it->name.c_str()];
            domainInfo.desc = [NSString stringWithUTF8String:it->desc.c_str()];
            domainInfo.email = [NSString stringWithUTF8String:it->email.c_str()];
            domainInfo.tel = [NSString stringWithUTF8String:it->tel.c_str()];
            domainInfo.address = [NSString stringWithUTF8String:it->address.c_str()];
            domainInfo.extra = [NSString stringWithUTF8String:it->extra.c_str()];
            domainInfo.updateDt = it->updateDt;
            [arr addObject:domainInfo];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(arr);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMLoadRemoteDomainsCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};


class IMCreateSecretChatCallback : public mars::stn::CreateSecretChatCallback {
private:
    void(^m_successBlock)(NSString *generalStr, int line);
    void(^m_errorBlock)(int error_code);
public:
    IMCreateSecretChatCallback(void(^successBlock)(NSString *groupId, int line), void(^errorBlock)(int error_code)) : mars::stn::CreateSecretChatCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::string &str, int line) {
        NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(nsstr, line);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMCreateSecretChatCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGetAuthorizedMediaUrlCallback : public mars::stn::GetAuthorizedMediaUrlCallback {
private:
    void(^m_successBlock)(NSString *url, NSString *backupUrl);
    void(^m_errorBlock)(int error_code);
public:
    IMGetAuthorizedMediaUrlCallback(void(^successBlock)(NSString *url, NSString *backupUrl), void(^errorBlock)(int error_code)) : mars::stn::GetAuthorizedMediaUrlCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::string &url, const std::string &backupUrl) {
        NSString *nsstr = [NSString stringWithUTF8String:url.c_str()];
        NSString *nsbstr = nil;
        if(!backupUrl.empty()) {
            nsbstr = [NSString stringWithUTF8String:backupUrl.c_str()];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(nsstr, nsbstr);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMGetAuthorizedMediaUrlCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};


class RecallMessageCallback : public mars::stn::GeneralOperationCallback {
private:
    void(^m_successBlock)();
    void(^m_errorBlock)(int error_code);
    WFCCMessage *message;
public:
    RecallMessageCallback(WFCCMessage *msg, void(^successBlock)(), void(^errorBlock)(int error_code)) : mars::stn::GeneralOperationCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock), message(msg) {};
    void onSuccess() {
        WFCCRecallMessageContent *recallCnt = [[WFCCRecallMessageContent alloc] init];
        WFCCMessagePayload *orignalPayload = [message.content encode];
        
        recallCnt.operatorId = [WFCCNetworkService sharedInstance].userId;
        recallCnt.messageUid = message.messageUid;
        recallCnt.originalSender = message.fromUser;
        recallCnt.originalContent = orignalPayload.content;
        recallCnt.originalSearchableContent = orignalPayload.searchableContent;
        recallCnt.originalContentType = orignalPayload.contentType;
        recallCnt.originalExtra = orignalPayload.extra;
        recallCnt.originalMessageTimestamp = message.serverTime;
        
        message.fromUser = [WFCCNetworkService sharedInstance].userId;
        message.serverTime = [[[NSDate alloc] init] timeIntervalSince1970];
        message.content = recallCnt;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock();
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~RecallMessageCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGetChatroomInfoCallback : public mars::stn::GetChatroomInfoCallback {
private:
    NSString *chatroomId;
    void(^m_successBlock)(WFCCChatroomInfo *chatroomInfo);
    void(^m_errorBlock)(int error_code);
public:
    IMGetChatroomInfoCallback(NSString *cid, void(^successBlock)(WFCCChatroomInfo *chatroomInfo), void(^errorBlock)(int error_code)) : mars::stn::GetChatroomInfoCallback(), chatroomId(cid),  m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const mars::stn::TChatroomInfo &info) {
        WFCCChatroomInfo *chatroomInfo = [[WFCCChatroomInfo alloc] init];
        chatroomInfo.chatroomId = chatroomId;
        chatroomInfo.title = [NSString stringWithUTF8String:info.title.c_str()];
        chatroomInfo.desc = [NSString stringWithUTF8String:info.desc.c_str()];
        chatroomInfo.portrait = [NSString stringWithUTF8String:info.portrait.c_str()];
        chatroomInfo.extra = [NSString stringWithUTF8String:info.extra.c_str()];
        chatroomInfo.state = info.state;
        chatroomInfo.memberCount = info.memberCount;
        chatroomInfo.createDt = info.createDt;
        chatroomInfo.updateDt = info.updateDt;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(chatroomInfo);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMGetChatroomInfoCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

extern NSMutableArray* convertProtoMessageList(const std::list<mars::stn::TMessage> &messageList, BOOL reverse);
extern WFCCGroupInfo *convertProtoGroupInfo(const mars::stn::TGroupInfo &tgi);

class IMLoadRemoteMessagesCallback : public mars::stn::LoadRemoteMessagesCallback {
private:
    void(^m_successBlock)(NSArray<WFCCMessage *> *messages);
    void(^m_errorBlock)(int error_code);
public:
    IMLoadRemoteMessagesCallback(void(^successBlock)(NSArray<WFCCMessage *> *messages), void(^errorBlock)(int error_code)) : mars::stn::LoadRemoteMessagesCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TMessage> &messageList) {
        NSMutableArray *messages = convertProtoMessageList(messageList, NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(messages);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMLoadRemoteMessagesCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMLoadOneRemoteMessageCallback : public mars::stn::LoadRemoteMessagesCallback {
private:
    void(^m_successBlock)(WFCCMessage *message);
    void(^m_errorBlock)(int error_code);
public:
    IMLoadOneRemoteMessageCallback(void(^successBlock)(WFCCMessage *message), void(^errorBlock)(int error_code)) : mars::stn::LoadRemoteMessagesCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TMessage> &messageList) {
        NSMutableArray *messages = convertProtoMessageList(messageList, NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(messages.count) {
                if (m_successBlock) {
                    m_successBlock(messages.firstObject);
                }
            } else {
                if (m_errorBlock) {
                    m_errorBlock(253);
                }
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMLoadOneRemoteMessageCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMLoadMessagesCallback : public mars::stn::LoadRemoteMessagesCallback {
private:
    void(^m_successBlock)(NSArray<WFCCMessage *> *messages);
    void(^m_errorBlock)(int error_code);
public:
    IMLoadMessagesCallback(void(^successBlock)(NSArray<WFCCMessage *> *messages), void(^errorBlock)(int error_code)) : mars::stn::LoadRemoteMessagesCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TMessage> &messageList) {
        NSMutableArray *messages = convertProtoMessageList(messageList, YES);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(messages);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMLoadMessagesCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMLoadFileRecordCallback : public mars::stn::LoadFileRecordCallback {
private:
    void(^m_successBlock)(NSArray<WFCCFileRecord *> *files);
    void(^m_errorBlock)(int error_code);
public:
    IMLoadFileRecordCallback(void(^successBlock)(NSArray<WFCCFileRecord *> *records), void(^errorBlock)(int error_code)) : mars::stn::LoadFileRecordCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TFileRecord> &fileList) {
        NSMutableArray *output = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TFileRecord>::const_iterator it = fileList.begin(); it != fileList.end(); ++it) {
            const mars::stn::TFileRecord &tfr = *it;
            WFCCFileRecord *record = [[WFCCFileRecord alloc] init];
            record.conversation = [[WFCCConversation alloc] init];
            record.conversation.type = (WFCCConversationType)tfr.conversationType;
            record.conversation.target = [NSString stringWithUTF8String:tfr.target.c_str()];
            record.conversation.line = tfr.line;

            record.messageUid = tfr.messageUid;
            record.userId = [NSString stringWithUTF8String:tfr.userId.c_str()];
            record.name = [NSString stringWithUTF8String:tfr.name.c_str()];
            record.url = [NSString stringWithUTF8String:tfr.url.c_str()];
            record.size = tfr.size;
            record.downloadCount = tfr.downloadCount;
            record.timestamp = tfr.timestamp;
            
            
            [output addObject:record];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(output);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMLoadFileRecordCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGetChatroomMemberInfoCallback : public mars::stn::GetChatroomMemberInfoCallback {
private:
    void(^m_successBlock)(WFCCChatroomMemberInfo *chatroomMemberInfo);
    void(^m_errorBlock)(int error_code);
public:
    IMGetChatroomMemberInfoCallback(void(^successBlock)(WFCCChatroomMemberInfo *chatroomMemberInfo), void(^errorBlock)(int error_code)) : mars::stn::GetChatroomMemberInfoCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const mars::stn::TChatroomMemberInfo &info) {
        WFCCChatroomMemberInfo *memberInfo = [[WFCCChatroomMemberInfo alloc] init];
        memberInfo.memberCount = info.memberCount;
        NSMutableArray *members = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it = info.olderMembers.begin(); it != info.olderMembers.end(); it++) {
            [members addObject:[NSString stringWithUTF8String:it->c_str()]];
        }
        memberInfo.members = members;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(memberInfo);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMGetChatroomMemberInfoCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMGetGroupInfoCallback : public mars::stn::GetGroupInfoCallback {
private:
    void(^m_successBlock)(NSArray<WFCCGroupInfo *> *);
    void(^m_errorBlock)(int error_code);
public:
    IMGetGroupInfoCallback(void(^successBlock)(NSArray<WFCCGroupInfo *> *), void(^errorBlock)(int error_code)) : mars::stn::GetGroupInfoCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::list<mars::stn::TGroupInfo> &groupInfoList) {
        
        NSMutableArray *ret = nil;
        if (m_successBlock) {
            NSMutableArray *ret = [[NSMutableArray alloc] init];
            for (std::list<mars::stn::TGroupInfo>::const_iterator it = groupInfoList.begin(); it != groupInfoList.end(); it++) {
                const mars::stn::TGroupInfo &tgi = *it;
                WFCCGroupInfo *gi = convertProtoGroupInfo(tgi);
                [ret addObject:gi];
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(ret);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMGetGroupInfoCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class GeneralUpdateMediaCallback : public mars::stn::UpdateMediaCallback {
public:
  void(^m_successBlock)(NSString *remoteUrl);
  void(^m_errorBlock)(int error_code);
  void(^m_progressBlock)(long uploaded, long total);
  
  GeneralUpdateMediaCallback(void(^successBlock)(NSString *remoteUrl), void(^progressBlock)(long uploaded, long total), void(^errorBlock)(int error_code)) : mars::stn::UpdateMediaCallback(), m_successBlock(successBlock), m_progressBlock(progressBlock), m_errorBlock(errorBlock) {}
  
  void onSuccess(const std::string &remoteUrl) {
      NSString *url = [NSString stringWithUTF8String:remoteUrl.c_str()];
      dispatch_async(dispatch_get_main_queue(), ^{
          if (m_successBlock) {
              m_successBlock(url);
          }
          delete this;
      });
  }
  
  void onFalure(int errorCode) {
      dispatch_async(dispatch_get_main_queue(), ^{
          if (m_errorBlock) {
              m_errorBlock(errorCode);
          }
          delete this;
      });
  }
  
    void onProgress(int current, int total) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_progressBlock) {
                m_progressBlock(current, total);
            }
        });
    }
    
  ~GeneralUpdateMediaCallback() {
    m_successBlock = nil;
    m_errorBlock = nil;
  }
};

class IMGetUploadMediaUrlCallback : public mars::stn::GetUploadMediaUrlCallback {
public:
    void(^m_successBlock)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type);
    void(^m_errorBlock)(int error_code);
  
    IMGetUploadMediaUrlCallback(void(^successBlock)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type), void(^errorBlock)(int error_code)) : mars::stn::GetUploadMediaUrlCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {}
  
    void onSuccess(const mars::stn::TUploadMediaUrlEntry &urlEntry) {
      NSString *uploadUrl = [NSString stringWithUTF8String:urlEntry.uploadUrl.c_str()];
        NSString *mediaUrl = [NSString stringWithUTF8String:urlEntry.mediaUrl.c_str()];
        NSString *backupUrl = [NSString stringWithUTF8String:urlEntry.backupUploadUrl.c_str()];
        int type = urlEntry.type;
      dispatch_async(dispatch_get_main_queue(), ^{
          if (m_successBlock) {
              m_successBlock(uploadUrl, mediaUrl, backupUrl, type);
          }
          delete this;
      });
    }
  
    void onFalure(int errorCode) {
      dispatch_async(dispatch_get_main_queue(), ^{
          if (m_errorBlock) {
              m_errorBlock(errorCode);
          }
          delete this;
      });
    }
    
  ~IMGetUploadMediaUrlCallback() {
    m_successBlock = nil;
    m_errorBlock = nil;
  }
};

class IMWatchOnlineStateCallback : public mars::stn::WatchOnlineStateCallback {
public:
    void(^m_successBlock)(NSArray<WFCCUserOnlineState *> *states);
    void(^m_errorBlock)(int error_code);
  
    IMWatchOnlineStateCallback(void(^successBlock)(NSArray<WFCCUserOnlineState *> *states), void(^errorBlock)(int error_code)) : mars::stn::WatchOnlineStateCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {}
  
    void onSuccess(const std::list<mars::stn::TUserOnlineState> &stateList) {
        NSMutableArray<WFCCUserOnlineState *> *onlineStates = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TUserOnlineState>::const_iterator it = stateList.begin(); it != stateList.end(); ++it) {
            WFCCUserOnlineState *s = [[WFCCUserOnlineState alloc] init];
            s.userId = [NSString stringWithUTF8String:it->userId.c_str()];
            if(it->customState > 0 || !it->customText.empty()) {
                s.customState = [[WFCCUserCustomState alloc] init];
                s.customState.state = it->customState;
                s.customState.text = [NSString stringWithUTF8String:it->customText.c_str()];
            }
            if(!it->states.empty()) {
                NSMutableArray<WFCCClientState *> *css = [[NSMutableArray alloc] init];
                for (std::list<mars::stn::TOnlineState>::const_iterator it2 = it->states.begin(); it2 != it->states.end(); ++it2) {
                    WFCCClientState *cs = [[WFCCClientState alloc] init];
                    cs.platform = it2->platform;
                    cs.state = it2->state;
                    cs.lastSeen = it2->lastSeen;
                    [css addObject:cs];
                }
                s.clientStates = css;
            }
            [onlineStates addObject:s];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WFCCIMService sharedWFCIMService] putUseOnlineStates:onlineStates];
            if (m_successBlock) {
                m_successBlock(onlineStates);
            }
            delete this;
        });
    }
  
  void onFalure(int errorCode) {
      dispatch_async(dispatch_get_main_queue(), ^{
          if (m_errorBlock) {
              m_errorBlock(errorCode);
          }
          delete this;
      });
  }
    
  ~IMWatchOnlineStateCallback() {
    m_successBlock = nil;
    m_errorBlock = nil;
  }
};

class IMSetGroupRemarkCallback : public mars::stn::GeneralOperationCallback {
private:
    NSString *mGroupId;
    void(^m_successBlock)();
    void(^m_errorBlock)(int error_code);
public:
    IMSetGroupRemarkCallback(NSString *groupId, void(^successBlock)(), void(^errorBlock)(int error_code)) : mars::stn::GeneralOperationCallback(), mGroupId(groupId), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess() {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock();
            }
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:mGroupId refresh:NO];
            if(groupInfo.target.length) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated object:mGroupId userInfo:@{@"groupInfoList":@[groupInfo]}];
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMSetGroupRemarkCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

static WFCCMessage *convertProtoMessage(const mars::stn::TMessage *tMessage) {
    if (tMessage->target.empty()) {
        return nil;
    }
    WFCCMessage *ret = [[WFCCMessage alloc] init];
    ret.fromUser = [NSString stringWithUTF8String:tMessage->from.c_str()];
    ret.conversation = [[WFCCConversation alloc] init];
    ret.conversation.type = (WFCCConversationType)tMessage->conversationType;
    ret.conversation.target = [NSString stringWithUTF8String:tMessage->target.c_str()];
    ret.conversation.line = tMessage->line;
    ret.messageId = tMessage->messageId;
    ret.messageUid = tMessage->messageUid;
    ret.serverTime = tMessage->timestamp;
    
    NSMutableArray *toUsers = [[NSMutableArray alloc] init];
    for (std::list<std::string>::const_iterator it = tMessage->to.begin(); it != tMessage->to.end(); ++it) {
        NSString *user = [NSString stringWithUTF8String:(*it).c_str()];
        [toUsers addObject:user];
    }
    ret.toUsers = toUsers;
    ret.direction = (WFCCMessageDirection)tMessage->direction;
    ret.status = (WFCCMessageStatus)tMessage->status;
    ret.localExtra = [NSString stringWithUTF8String:tMessage->localExtra.c_str()];
    
    //如果消息未加载，没有必要对消息的content进行decode。
    if(!tMessage->content.notLoaded) {
        WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
        payload.contentType = tMessage->content.type;
        payload.searchableContent = [NSString stringWithUTF8String:tMessage->content.searchableContent.c_str()];
        payload.pushContent = [NSString stringWithUTF8String:tMessage->content.pushContent.c_str()];
        payload.pushData = [NSString stringWithUTF8String:tMessage->content.pushData.c_str()];
        
        payload.content = [NSString stringWithUTF8String:tMessage->content.content.c_str()];
        payload.binaryContent = [NSData dataWithBytes:tMessage->content.binaryContent.c_str() length:tMessage->content.binaryContent.length()];
        payload.localContent = [NSString stringWithUTF8String:tMessage->content.localContent.c_str()];
        payload.mediaType = (WFCCMediaType)tMessage->content.mediaType;
        payload.remoteMediaUrl = [NSString stringWithUTF8String:tMessage->content.remoteMediaUrl.c_str()];
        if (payload.remoteMediaUrl.length && [WFCCNetworkService sharedInstance].urlRedirector) {
            payload.remoteMediaUrl = [[WFCCNetworkService sharedInstance].urlRedirector redirect:payload.remoteMediaUrl];
        }
        payload.localMediaPath = [NSString stringWithUTF8String:tMessage->content.localMediaPath.c_str()];
        payload.mentionedType = tMessage->content.mentionedType;
        payload.notLoaded = NO;
        
        NSMutableArray *mentionedTargets = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it = tMessage->content.mentionedTargets.begin(); it != tMessage->content.mentionedTargets.end(); it++) {
            [mentionedTargets addObject:[NSString stringWithUTF8String:(*it).c_str()]];
        }
        payload.mentionedTargets = mentionedTargets;
        
        payload.extra = [NSString stringWithUTF8String:tMessage->content.extra.c_str()];
        
        ret.content = [[WFCCIMService sharedWFCIMService] messageContentFromPayload:payload];
    }
    return ret;
}


NSMutableArray* convertProtoMessageList(const std::list<mars::stn::TMessage> &messageList, BOOL reverse) {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TMessage>::const_iterator it = messageList.begin(); it != messageList.end(); it++) {
        const mars::stn::TMessage &tmsg = *it;
        WFCCMessage *msg = convertProtoMessage(&tmsg);
        if (msg) {
            if (reverse) {
                [messages insertObject:msg atIndex:0];
            } else {
                [messages addObject:msg];
            }
        }
    }
    return messages;
}

NSMutableArray* convertProtoDeliveryList(const std::map<std::string, int64_t> &userReceived) {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    for(std::map<std::string, int64_t>::const_iterator it = userReceived.begin(); it != userReceived.end(); ++it) {
        [messages addObject:[WFCCDeliveryReport delivered:[NSString stringWithUTF8String:it->first.c_str()] timestamp:it->second]];
    }
    
    return messages;
}

NSMutableArray* convertProtoReadedList(const std::list<mars::stn::TReadEntry> &userReceived) {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    for(std::list<mars::stn::TReadEntry>::const_iterator it = userReceived.begin(); it != userReceived.end(); ++it) {
        [messages addObject:[WFCCReadReport readed:[WFCCConversation conversationWithType:(WFCCConversationType)it->conversationType target:[NSString stringWithUTF8String:it->target.c_str()] line:it->line] userId:[NSString stringWithUTF8String:it->userId.c_str()] timestamp:it->readDt]];
    }
    
    return messages;
}



static WFCCConversationInfo* convertConversationInfo(const mars::stn::TConversation &tConv) {
    WFCCConversationInfo *info = [[WFCCConversationInfo alloc] init];
    info.conversation = [[WFCCConversation alloc] init];
    info.conversation.type = (WFCCConversationType)tConv.conversationType;
    info.conversation.target = [NSString stringWithUTF8String:tConv.target.c_str()];
    info.conversation.line = tConv.line;
    info.lastMessage = convertProtoMessage(&tConv.lastMessage);
    info.draft = [NSString stringWithUTF8String:tConv.draft.c_str()];
    if (!tConv.draft.empty() && tConv.lastMessage.timestamp > 0) {
        info.timestamp = tConv.lastMessage.timestamp;
    } else {
        info.timestamp = tConv.timestamp;
    }
    info.unreadCount = [WFCCUnreadCount countOf:tConv.unreadCount.unread mention:tConv.unreadCount.unreadMention mentionAll:tConv.unreadCount.unreadMentionAll];
    info.isTop = tConv.isTop;
    info.isSilent = tConv.isSilent;
    return info;
}

static WFCCFriendRequest* convertFriendRequest(const mars::stn::TFriendRequest &tRequest) {
    if (tRequest.target.empty()) {
        return nil;
    }
    WFCCFriendRequest *request = [[WFCCFriendRequest alloc] init];
    request.direction = tRequest.direction;
    request.target = [NSString stringWithUTF8String:tRequest.target.c_str()];
    request.reason = [NSString stringWithUTF8String:tRequest.reason.c_str()];
    request.extra = [NSString stringWithUTF8String:tRequest.extra.c_str()];
    request.status = tRequest.status;
    request.readStatus = tRequest.readStatus;
    request.timestamp = tRequest.timestamp;
    return request;
}

static NSArray<WFCCFriendRequest *>* convertFriendRequests(std::list<mars::stn::TFriendRequest> &tRequests) {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TFriendRequest>::iterator it = tRequests.begin(); it != tRequests.end(); it++) {
        WFCCFriendRequest *request = convertFriendRequest(*it);
        [ret addObject:request];
    }
    return ret;
}

static WFCCIMService * sharedSingleton = nil;

static void fillTMessageContent(mars::stn::TMessageContent &tmsgcontent, WFCCMessageContent *content) {
    if(!content) {
        return;
    }
    
    WFCCMessagePayload *payload = [content encode];
    if(!payload.contentType) {
        NSLog(@"****************************************");
        NSLog(@"Error, message content net set content type %@", content.class);
        NSLog(@"错误，消息%@的类型为空，请检查自定义消息的encode方法是不是没有调用[super encode]", content.class);
        NSLog(@"****************************************");
    }
    payload.extra = content.extra;
    tmsgcontent.type = payload.contentType;
    tmsgcontent.searchableContent = [payload.searchableContent UTF8String] ? [payload.searchableContent UTF8String] : "";
    tmsgcontent.pushContent = [payload.pushContent UTF8String] ? [payload.pushContent UTF8String] : "";
    tmsgcontent.pushData = [payload.pushData UTF8String] ? [payload.pushData UTF8String] : "";
    
    tmsgcontent.content = [payload.content UTF8String] ? [payload.content UTF8String] : "";
    if (payload.binaryContent != nil) {
        tmsgcontent.binaryContent = std::string((const char *)payload.binaryContent.bytes, payload.binaryContent.length);
    }
    tmsgcontent.localContent = [payload.localContent UTF8String] ? [payload.localContent UTF8String] : "";
    if ([payload isKindOfClass:[WFCCMediaMessagePayload class]]) {
        WFCCMediaMessagePayload *mediaPayload = (WFCCMediaMessagePayload *)payload;
        tmsgcontent.mediaType = (int)mediaPayload.mediaType;
        tmsgcontent.remoteMediaUrl = [mediaPayload.remoteMediaUrl UTF8String] ? [mediaPayload.remoteMediaUrl UTF8String] : "";
        tmsgcontent.localMediaPath = [mediaPayload.localMediaPath UTF8String] ? [mediaPayload.localMediaPath UTF8String] : "";
    }
    
    tmsgcontent.mentionedType = payload.mentionedType;
    for (NSString *target in payload.mentionedTargets) {
        tmsgcontent.mentionedTargets.insert(tmsgcontent.mentionedTargets.end(), [target UTF8String]);
    }
    tmsgcontent.extra = [payload.extra UTF8String] ? [payload.extra UTF8String] : "";
}


static void fillTMessage(mars::stn::TMessage &tmsg, WFCCConversation *conv, WFCCMessageContent *content) {
    tmsg.conversationType = (int)conv.type;
    tmsg.target = conv.target ? [conv.target UTF8String] : "";
    tmsg.line = conv.line;
    tmsg.from = [[WFCCNetworkService sharedInstance].userId UTF8String];
    tmsg.status = mars::stn::MessageStatus::Message_Status_Sending;
    tmsg.timestamp = time(NULL)*1000 + [WFCCNetworkService sharedInstance].serverDeltaTime;
    tmsg.direction = 0;
    fillTMessageContent(tmsg.content, content);
}

@interface WFCCIMService ()
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, Class> *MessageContentMaps;
@property(nonatomic, assign)BOOL defaultSilentWhenPCOnline;

@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCCUserOnlineState*> *useOnlineCacheMap;

@property(nonatomic, assign)BOOL rawMessage;

//UploadModel or UploadTask
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, NSObject *> *uploadingModelMap;
@end

@implementation WFCCIMService
+ (WFCCIMService *)sharedWFCIMService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCCIMService alloc] init];
                sharedSingleton.MessageContentMaps = [[NSMutableDictionary alloc] init];
                sharedSingleton.defaultSilentWhenPCOnline = YES;
                sharedSingleton.useOnlineCacheMap = [[NSMutableDictionary alloc] init];
                sharedSingleton.uploadingModelMap = [[NSMutableDictionary alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)useRawMessage {
    self.rawMessage = YES;
}

- (UIImage *)defaultThumbnailImage {
    if(!_defaultThumbnailImage) {
        NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:@"/9j/4AAQSkZJRgABAQAAkACQAAD/4QCARXhpZgAATU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAACQAAAAAQAAAJAAAAABAAKgAgAEAAAAAQAAAGSgAwAEAAAAAQAAAGQAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/iEaxJQ0NfUFJPRklMRQABAQAAEZxhcHBsAgAAAG1udHJHUkFZWFlaIAfcAAgAFwAPAC4AD2Fjc3BBUFBMAAAAAG5vbmUAAAAAAAAAAAAAAAAAAAAAAAD21gABAAAAANMtYXBwbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABWRlc2MAAADAAAAAeWRzY20AAAE8AAAIGmNwcnQAAAlYAAAAI3d0cHQAAAl8AAAAFGtUUkMAAAmQAAAIDGRlc2MAAAAAAAAAH0dlbmVyaWMgR3JheSBHYW1tYSAyLjIgUHJvZmlsZQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABtbHVjAAAAAAAAAB8AAAAMc2tTSwAAAC4AAAGEZGFESwAAADoAAAGyY2FFUwAAADgAAAHsdmlWTgAAAEAAAAIkcHRCUgAAAEoAAAJkdWtVQQAAACwAAAKuZnJGVQAAAD4AAALaaHVIVQAAADQAAAMYemhUVwAAABoAAANMa29LUgAAACIAAANmbmJOTwAAADoAAAOIY3NDWgAAACgAAAPCaGVJTAAAACQAAAPqcm9STwAAACoAAAQOZGVERQAAAE4AAAQ4aXRJVAAAAE4AAASGc3ZTRQAAADgAAATUemhDTgAAABoAAAUMamFKUAAAACYAAAUmZWxHUgAAACoAAAVMcHRQTwAAAFIAAAV2bmxOTAAAAEAAAAXIZXNFUwAAAEwAAAYIdGhUSAAAADIAAAZUdHJUUgAAACQAAAaGZmlGSQAAAEYAAAaqaHJIUgAAAD4AAAbwcGxQTAAAAEoAAAcuYXJFRwAAACwAAAd4cnVSVQAAADoAAAekZW5VUwAAADwAAAfeAFYBYQBlAG8AYgBlAGMAbgDhACAAcwBpAHYA4QAgAGcAYQBtAGEAIAAyACwAMgBHAGUAbgBlAHIAaQBzAGsAIABnAHIA5QAgADIALAAyACAAZwBhAG0AbQBhAC0AcAByAG8AZgBpAGwARwBhAG0AbQBhACAAZABlACAAZwByAGkAcwBvAHMAIABnAGUAbgDoAHIAaQBjAGEAIAAyAC4AMgBDHqUAdQAgAGgA7ABuAGgAIABNAOAAdQAgAHgA4QBtACAAQwBoAHUAbgBnACAARwBhAG0AbQBhACAAMgAuADIAUABlAHIAZgBpAGwAIABHAGUAbgDpAHIAaQBjAG8AIABkAGEAIABHAGEAbQBhACAAZABlACAAQwBpAG4AegBhAHMAIAAyACwAMgQXBDAEMwQwBDsETAQ9BDAAIABHAHIAYQB5AC0EMwQwBDwEMAAgADIALgAyAFAAcgBvAGYAaQBsACAAZwDpAG4A6QByAGkAcQB1AGUAIABnAHIAaQBzACAAZwBhAG0AbQBhACAAMgAsADIAwQBsAHQAYQBsAOEAbgBvAHMAIABzAHoA/AByAGsAZQAgAGcAYQBtAG0AYQAgADIALgAykBp1KHBwlo5RSV6mADIALgAygnJfaWPPj/DHfLwYACDWjMDJACCsELnIACAAMgAuADIAINUEuFzTDMd8AEcAZQBuAGUAcgBpAHMAawAgAGcAcgDlACAAZwBhAG0AbQBhACAAMgAsADIALQBwAHIAbwBmAGkAbABPAGIAZQBjAG4A4QAgAWEAZQBkAOEAIABnAGEAbQBhACAAMgAuADIF0gXQBd4F1AAgBdAF5AXVBegAIAXbBdwF3AXZACAAMgAuADIARwBhAG0AYQAgAGcAcgBpACAAZwBlAG4AZQByAGkAYwEDACAAMgAsADIAQQBsAGwAZwBlAG0AZQBpAG4AZQBzACAARwByAGEAdQBzAHQAdQBmAGUAbgAtAFAAcgBvAGYAaQBsACAARwBhAG0AbQBhACAAMgAsADIAUAByAG8AZgBpAGwAbwAgAGcAcgBpAGcAaQBvACAAZwBlAG4AZQByAGkAYwBvACAAZABlAGwAbABhACAAZwBhAG0AbQBhACAAMgAsADIARwBlAG4AZQByAGkAcwBrACAAZwByAOUAIAAyACwAMgAgAGcAYQBtAG0AYQBwAHIAbwBmAGkAbGZukBpwcF6mfPtlcAAyAC4AMmPPj/Blh072TgCCLDCwMOwwpDCsMPMw3gAgADIALgAyACAw1zDtMNUwoTCkMOsDkwO1A70DuQO6A8wAIAOTA7oDwQO5ACADkwOsA7wDvAOxACAAMgAuADIAUABlAHIAZgBpAGwAIABnAGUAbgDpAHIAaQBjAG8AIABkAGUAIABjAGkAbgB6AGUAbgB0AG8AcwAgAGQAYQAgAEcAYQBtAG0AYQAgADIALAAyAEEAbABnAGUAbQBlAGUAbgAgAGcAcgBpAGoAcwAgAGcAYQBtAG0AYQAgADIALAAyAC0AcAByAG8AZgBpAGUAbABQAGUAcgBmAGkAbAAgAGcAZQBuAOkAcgBpAGMAbwAgAGQAZQAgAGcAYQBtAG0AYQAgAGQAZQAgAGcAcgBpAHMAZQBzACAAMgAsADIOIw4xDgcOKg41DkEOAQ4hDiEOMg5ADgEOIw4iDkwOFw4xDkgOJw5EDhsAIAAyAC4AMgBHAGUAbgBlAGwAIABHAHIAaQAgAEcAYQBtAGEAIAAyACwAMgBZAGwAZQBpAG4AZQBuACAAaABhAHIAbQBhAGEAbgAgAGcAYQBtAG0AYQAgADIALAAyACAALQBwAHIAbwBmAGkAaQBsAGkARwBlAG4AZQByAGkBDQBrAGkAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABwAHIAbwBmAGkAbABVAG4AaQB3AGUAcgBzAGEAbABuAHkAIABwAHIAbwBmAGkAbAAgAHMAegBhAHIAbwFbAGMAaQAgAGcAYQBtAG0AYQAgADIALAAyBjoGJwZFBicAIAAyAC4AMgAgBkQGSAZGACAGMQZFBicGLwZKACAGOQYnBkUEHgQxBEkEMARPACAEQQQ1BEAEMARPACAEMwQwBDwEPAQwACAAMgAsADIALQQ/BEAEPgREBDgEOwRMAEcAZQBuAGUAcgBpAGMAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABQAHIAbwBmAGkAbABlAAB0ZXh0AAAAAENvcHlyaWdodCBBcHBsZSBJbmMuLCAyMDEyAABYWVogAAAAAAAA81EAAQAAAAEWzGN1cnYAAAAAAAAEAAAAAAUACgAPABQAGQAeACMAKAAtADIANwA7AEAARQBKAE8AVABZAF4AYwBoAG0AcgB3AHwAgQCGAIsAkACVAJoAnwCkAKkArgCyALcAvADBAMYAywDQANUA2wDgAOUA6wDwAPYA+wEBAQcBDQETARkBHwElASsBMgE4AT4BRQFMAVIBWQFgAWcBbgF1AXwBgwGLAZIBmgGhAakBsQG5AcEByQHRAdkB4QHpAfIB+gIDAgwCFAIdAiYCLwI4AkECSwJUAl0CZwJxAnoChAKOApgCogKsArYCwQLLAtUC4ALrAvUDAAMLAxYDIQMtAzgDQwNPA1oDZgNyA34DigOWA6IDrgO6A8cD0wPgA+wD+QQGBBMEIAQtBDsESARVBGMEcQR+BIwEmgSoBLYExATTBOEE8AT+BQ0FHAUrBToFSQVYBWcFdwWGBZYFpgW1BcUF1QXlBfYGBgYWBicGNwZIBlkGagZ7BowGnQavBsAG0QbjBvUHBwcZBysHPQdPB2EHdAeGB5kHrAe/B9IH5Qf4CAsIHwgyCEYIWghuCIIIlgiqCL4I0gjnCPsJEAklCToJTwlkCXkJjwmkCboJzwnlCfsKEQonCj0KVApqCoEKmAquCsUK3ArzCwsLIgs5C1ELaQuAC5gLsAvIC+EL+QwSDCoMQwxcDHUMjgynDMAM2QzzDQ0NJg1ADVoNdA2ODakNww3eDfgOEw4uDkkOZA5/DpsOtg7SDu4PCQ8lD0EPXg96D5YPsw/PD+wQCRAmEEMQYRB+EJsQuRDXEPURExExEU8RbRGMEaoRyRHoEgcSJhJFEmQShBKjEsMS4xMDEyMTQxNjE4MTpBPFE+UUBhQnFEkUahSLFK0UzhTwFRIVNBVWFXgVmxW9FeAWAxYmFkkWbBaPFrIW1hb6Fx0XQRdlF4kXrhfSF/cYGxhAGGUYihivGNUY+hkgGUUZaxmRGbcZ3RoEGioaURp3Gp4axRrsGxQbOxtjG4obshvaHAIcKhxSHHscoxzMHPUdHh1HHXAdmR3DHeweFh5AHmoelB6+HukfEx8+H2kflB+/H+ogFSBBIGwgmCDEIPAhHCFIIXUhoSHOIfsiJyJVIoIiryLdIwojOCNmI5QjwiPwJB8kTSR8JKsk2iUJJTglaCWXJccl9yYnJlcmhya3JugnGCdJJ3onqyfcKA0oPyhxKKIo1CkGKTgpaymdKdAqAio1KmgqmyrPKwIrNitpK50r0SwFLDksbiyiLNctDC1BLXYtqy3hLhYuTC6CLrcu7i8kL1ovkS/HL/4wNTBsMKQw2zESMUoxgjG6MfIyKjJjMpsy1DMNM0YzfzO4M/E0KzRlNJ402DUTNU01hzXCNf02NzZyNq426TckN2A3nDfXOBQ4UDiMOMg5BTlCOX85vDn5OjY6dDqyOu87LTtrO6o76DwnPGU8pDzjPSI9YT2hPeA+ID5gPqA+4D8hP2E/oj/iQCNAZECmQOdBKUFqQaxB7kIwQnJCtUL3QzpDfUPARANER0SKRM5FEkVVRZpF3kYiRmdGq0bwRzVHe0fASAVIS0iRSNdJHUljSalJ8Eo3Sn1KxEsMS1NLmkviTCpMcky6TQJNSk2TTdxOJU5uTrdPAE9JT5NP3VAnUHFQu1EGUVBRm1HmUjFSfFLHUxNTX1OqU/ZUQlSPVNtVKFV1VcJWD1ZcVqlW91dEV5JX4FgvWH1Yy1kaWWlZuFoHWlZaplr1W0VblVvlXDVchlzWXSddeF3JXhpebF69Xw9fYV+zYAVgV2CqYPxhT2GiYfViSWKcYvBjQ2OXY+tkQGSUZOllPWWSZedmPWaSZuhnPWeTZ+loP2iWaOxpQ2maafFqSGqfavdrT2una/9sV2yvbQhtYG25bhJua27Ebx5veG/RcCtwhnDgcTpxlXHwcktypnMBc11zuHQUdHB0zHUodYV14XY+dpt2+HdWd7N4EXhueMx5KnmJeed6RnqlewR7Y3vCfCF8gXzhfUF9oX4BfmJ+wn8jf4R/5YBHgKiBCoFrgc2CMIKSgvSDV4O6hB2EgITjhUeFq4YOhnKG14c7h5+IBIhpiM6JM4mZif6KZIrKizCLlov8jGOMyo0xjZiN/45mjs6PNo+ekAaQbpDWkT+RqJIRknqS45NNk7aUIJSKlPSVX5XJljSWn5cKl3WX4JhMmLiZJJmQmfyaaJrVm0Kbr5wcnImc951kndKeQJ6unx2fi5/6oGmg2KFHobaiJqKWowajdqPmpFakx6U4pammGqaLpv2nbqfgqFKoxKk3qamqHKqPqwKrdavprFys0K1ErbiuLa6hrxavi7AAsHWw6rFgsdayS7LCszizrrQltJy1E7WKtgG2ebbwt2i34LhZuNG5SrnCuju6tbsuu6e8IbybvRW9j74KvoS+/796v/XAcMDswWfB48JfwtvDWMPUxFHEzsVLxcjGRsbDx0HHv8g9yLzJOsm5yjjKt8s2y7bMNcy1zTXNtc42zrbPN8+40DnQutE80b7SP9LB00TTxtRJ1MvVTtXR1lXW2Ndc1+DYZNjo2WzZ8dp22vvbgNwF3IrdEN2W3hzeot8p36/gNuC94UThzOJT4tvjY+Pr5HPk/OWE5g3mlucf56noMui86Ubp0Opb6uXrcOv77IbtEe2c7ijutO9A78zwWPDl8XLx//KM8xnzp/Q09ML1UPXe9m32+/eK+Bn4qPk4+cf6V/rn+3f8B/yY/Sn9uv5L/tz/bf///8AACwgAZABkAQERAP/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/bAEMABwcHBwcHDAcHDBEMDAwRFxEREREXHhcXFxcXHiQeHh4eHh4kJCQkJCQkJCsrKysrKzIyMjIyODg4ODg4ODg4OP/dAAQADf/aAAgBAQAAPwD6Roooooooooooor//0PpGiiiiiiiiiiiiv//R+kaKKKKKKKKKKKK//9L6Roooooooooooor//0/pGiiiud1zxPp3h2ezj1QPHFeSGMT4/dRtjgO38O7t+vFdCCCMiloooooor/9T6RooorifHd9DaaVbW93bpdW99dw2k0cnQpKSMg9iDgg+1eSt4K0Lwnrf2DxSk02l3j4tL4TSIImPSKYKwA9mwP57fSf8AhVXgzGRBOf8At4l/+LrzqHR9Ps7nw9q9np13pU82rLA8NzLI7FFBOcMehx6fmOa+jKKKKK//1fpGiiivMfircQ2miWF3cNtjh1O2d264VSSTx7Vjv41bVAR4t0ryPDeq/uraeXqPRphn5Q/VTxjGeetcveXGuaZFaeH7TXBH4euZmS31VPneMpnbA7ggABhjdxkd8ZAvaj4i1G71nw/4d8RxeVqtnqcTMyj91PEVYCVD0we47H8QPoCiiiiv/9b6RooorlPGPhdfFulJpjXBttkyTB9gk5TOAVPBHPeuU1L4f+JNXsJNM1HxNNLbygB0+zRqCAcgZBB7Vc0jwDe2NoNH1HVPt+leWYms3to0QqehDKQQwPOeueevNcfD4L1+w8Z6VY31zPd6TZuZrGXy1cxbOfKlfhlGOAckHjA9PeqKKKK//9f6Roooooooooooor//0PpGiiiiiiiiiiiiv//R+kaKKKKKKKKKKKK//9L6Roooooooooooor//0/pGiiiiiiiiiiiiv//Z" options:NSDataBase64DecodingIgnoreUnknownCharacters];
        _defaultThumbnailImage = [UIImage imageWithData:thumbData];
    }
    return _defaultThumbnailImage;
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
              success:(void(^)(long long messageUd, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:nil error:errorBlock];
}

- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:progressBlock error:errorBlock];
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
               toUsers:(NSArray<NSString *> *)toUsers
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:nil expireDuration:expireDuration success:successBlock progress:progressBlock error:errorBlock];
}

- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *>*)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:progressBlock mediaUploaded:nil error:errorBlock];
    
}
 
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *> *)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
             mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                     error:(void(^)(int error_code))errorBlock {
    
    void(^uploadedBlock)(NSString *remoteUrl) = mediaUploadedBlock;
    BOOL isSendCmd = NO;
    
    if([WFCCNetworkService sharedInstance].sendLogCommand.length) {
        if ([content isKindOfClass:WFCCTextMessageContent.class]) {
            WFCCTextMessageContent *txtCnt = (WFCCTextMessageContent *)content;
            isSendCmd = [txtCnt.text isEqualToString:[WFCCNetworkService sharedInstance].sendLogCommand];
        } else if ([content isKindOfClass:WFCCRawMessageContent.class]) {
            WFCCRawMessageContent *rawCnt = (WFCCRawMessageContent *)content;
            if(rawCnt.payload.contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                isSendCmd = [rawCnt.payload.searchableContent isEqualToString:[WFCCNetworkService sharedInstance].sendLogCommand];
            }
        }
    }
    
    if (isSendCmd) {
        NSArray<NSString *> *logs = [WFCCNetworkService getLogFilesPath];
        if(logs.count) {
            WFCCMessage *message;
            for (NSString *logPath in logs) {
                content = [WFCCFileMessageContent fileMessageContentFromPath:logPath];
                uploadedBlock = ^(NSString *remoteUrl) {
                    [self send:conversation content:[WFCCTextMessageContent contentWith:remoteUrl]  success:nil error:nil];
                };
                message = [self sendMedia:conversation content:content toUsers:nil expireDuration:0 success:nil progress:nil mediaUploaded:uploadedBlock error:nil];
            }
            return message;
        } else {
            NSLog(@"日志文件不存在。。。");
            if ([content isKindOfClass:WFCCTextMessageContent.class]) {
                WFCCTextMessageContent *txtCnt = (WFCCTextMessageContent *)content;
                txtCnt.text = @"日志文件不存在。。。";
            } else if ([content isKindOfClass:WFCCRawMessageContent.class]) {
                WFCCRawMessageContent *rawCnt = (WFCCRawMessageContent *)content;
                if(rawCnt.payload.contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                    rawCnt.payload.searchableContent = @"日志文件不存在。。。";
                }
            }
        }
    }
    
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.conversation = conversation;
    message.content = content;
    message.toUsers = toUsers;
    mars::stn::TMessage tmsg;
    if (toUsers.count) {
        for (NSString *obj in toUsers) {
            tmsg.to.push_back([obj UTF8String]);
        }
    }
    message.status = Message_Status_Sending;
    fillTMessage(tmsg, conversation, content);
    message.fromUser = [WFCCNetworkService sharedInstance].userId;
    
    BOOL largeMedia = NO;
    int fileSize  = 0;
    if(tmsg.content.mediaType > 0 && tmsg.content.remoteMediaUrl.empty() && !tmsg.content.localMediaPath.empty()) {
        if ([[WFCCNetworkService sharedInstance] isTcpShortLink]) {
            if ([self isSupportBigFilesUpload]) {
                largeMedia = YES;
            } else {
                NSLog(@"TCP短连接不支持内置对象存储，请把对象存储切换到其他类型");
                errorBlock(-1);
                return message;
            }
        } else if([self isSupportBigFilesUpload] && conversation.type != SecretChat_Type) {
            NSString *filePath = [NSString stringWithUTF8String:tmsg.content.localMediaPath.c_str()];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSNumber *fileSizeValue = nil;
            NSError *fileSizeError = nil;
            [fileURL getResourceValue:&fileSizeValue
                               forKey:NSURLFileSizeKey
                                error:&fileSizeError];
            if (!fileSizeError) {
                NSLog(@"value for %@ is %@", fileURL, fileSizeValue);
                if(mars::stn::ForcePresignedUrlUpload()) {
                    largeMedia = YES;
                } else {
                    largeMedia = [fileSizeValue integerValue] > 100000000L;
                }
                fileSize = (int)[fileSizeValue integerValue];
            }
        }
    }
    
    if(largeMedia) {
        long msgId = mars::stn::MessageDB::Instance()->InsertMessage(tmsg);
        message.messageId = msgId;
        
        IMSendMessageCallback *callback = new IMSendMessageCallback(message, successBlock, progressBlock, uploadedBlock, errorBlock);
        callback->onPrepared(message.messageId, message.serverTime);
        
        __weak typeof(self)ws = self;
        NSString *fileContentTypeString = [self mimeTypeOfFile:[NSString stringWithUTF8String:tmsg.content.localMediaPath.c_str()]];
        [self getUploadUrl:@"" mediaType:(WFCCMediaType)tmsg.content.mediaType contentType:fileContentTypeString success:^(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type) {
            NSString *url = ([WFCCNetworkService sharedInstance].connectedToMainNetwork || !backupUploadUrl.length)?uploadUrl:backupUploadUrl;
            if(type == 1) {
                [ws uploadQiniu:url messageId:msgId file:[NSString stringWithUTF8String:tmsg.content.localMediaPath.c_str()] remoteUrl:downloadUrl fileSize:fileSize expireDuration:expireDuration callback:callback];
            } else {
                [ws upload:url messageId:msgId file:[NSString stringWithUTF8String:tmsg.content.localMediaPath.c_str()] remoteUrl:downloadUrl fileContentType:fileContentTypeString fileSize:fileSize expireDuration:expireDuration callback:callback];
            }
        } error:^(int error_code) {
            errorBlock(error_code);
        }];
    } else {
        mars::stn::sendMessage(tmsg, new IMSendMessageCallback(message, successBlock, progressBlock, uploadedBlock, errorBlock), expireDuration);
    }
    
    return message;
}

- (NSString *)mimeTypeOfFile:(NSString *)filePath {
    NSString *fileExtension = [filePath pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    return mimeType.length?mimeType:@"application/octet-stream";;
}

- (void)upload:(NSString *)url messageId:(long)messageId file:(NSString *)file remoteUrl:(NSString *)remoteUrl fileContentType:(NSString *)fileContentTypeString fileSize:(int)fileSize expireDuration:(int)expireDuration callback:(IMSendMessageCallback *)callback {
    NSURL *presignedURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPMethod:@"PUT"];
    [request setValue:fileContentTypeString forHTTPHeaderField:@"Content-Type"];

    WFCUUploadModel *model = [[WFCUUploadModel alloc] init];
    model.fileSize = fileSize;
    model.expireDuration = expireDuration;
    model->_sendCallback = callback;
    __weak typeof(self)ws = self;
    model.uploadTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:model delegateQueue:nil] uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:file] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.uploadingModelMap removeObjectForKey:@(messageId)];
            if(error) {
                NSLog(@"error %@", error.localizedDescription);
                [model didUploadedFailed:-500];
            } else {
                NSLog(@"done");
                if(((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"upload failure");
                    [model didUploadedFailed:(int)((NSHTTPURLResponse *)response).statusCode];
                } else {
                    NSLog(@"upload success %@", remoteUrl);
                    [model didUploaded:remoteUrl];
                }
            }
        });
    }];
    
    [model.uploadTask resume];
    [self.uploadingModelMap setObject:model forKey:@(messageId)];
}

- (void)uploadFile:(NSString *)url file:(NSString *)file fileContentType:(NSString *)fileContentTypeString fileSize:(int)fileSize remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
             error:(void(^)(int error_code))errorBlock {
    NSURL *presignedURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPMethod:@"PUT"];
    [request setValue:fileContentTypeString forHTTPHeaderField:@"Content-Type"];

    long messageId = [[[NSDate alloc] init] timeIntervalSince1970];
    WFCUUploadModel *model = [[WFCUUploadModel alloc] init];
    model.fileSize = fileSize;
    model->_sendCallback = new IMSendMessageCallback(nil, nil, progressBlock, nil, nil);
    __weak typeof(self)ws = self;
    model.uploadTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:model delegateQueue:nil] uploadTaskWithRequest:request fromFile:[NSURL fileURLWithPath:file] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.uploadingModelMap removeObjectForKey:@(messageId)];
            delete model->_sendCallback;
            if(error) {
                NSLog(@"error %@", error.localizedDescription);
                errorBlock(-500);
            } else {
                NSLog(@"done");
                if(((NSHTTPURLResponse *)response).statusCode != 200) {
                    errorBlock((int)((NSHTTPURLResponse *)response).statusCode);
                } else {
                    successBlock(remoteUrl);
                }
            }
        });
    }];
    
    [model.uploadTask resume];
    [self.uploadingModelMap setObject:model forKey:@(messageId)];
}

- (void)uploadData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
             error:(void(^)(int error_code))errorBlock {
    NSURL *presignedURL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setHTTPMethod:@"PUT"];
    NSString *fileContentTypeString = @"application/octet-stream";
    [request setValue:fileContentTypeString forHTTPHeaderField:@"Content-Type"];

    WFCUUploaDatadModel *model = [[WFCUUploaDatadModel alloc] init];
    model->m_uploadedBlock = successBlock;
    model->m_errorBlock = errorBlock;
    model->m_progressBlock = progressBlock;
    model.uploadTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:model delegateQueue:nil] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                NSLog(@"error %@", error.localizedDescription);
                [model didUploadedFailed:-500];
            } else {
                NSLog(@"done");
                if(((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"upload failure");
                    [model didUploadedFailed:(int)((NSHTTPURLResponse *)response).statusCode];
                } else {
                    NSLog(@"upload success %@", remoteUrl);
                    [model didUploaded:remoteUrl];
                }
            }
        });
    }];
    
    [model.uploadTask resume];
}


- (void)uploadQiniu:(NSString *)url messageId:(long)messageId file:(NSString *)file remoteUrl:(NSString *)remoteUrl fileSize:(int)fileSize expireDuration:(int)expireDuration callback:(IMSendMessageCallback *)callback {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];

    WFAFHTTPSessionManager *manage = [WFAFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [WFAFHTTPRequestSerializer serializer];
    manage.responseSerializer = [WFAFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    NSURLSessionDataTask *task = [manage POST:url parameters:nil constructingBodyWithBlock:^(id<WFAFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:file] name:@"file" fileName:@"fileName" mimeType:[self mimeTypeOfFile:file] error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
            callback->onProgress((int)uploadProgress.completedUnitCount, (int)uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [ws.uploadingModelMap removeObjectForKey:@(messageId)];
            WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)callback->m_message.content;
            mediaContent.remoteUrl = remoteUrl;
            [[WFCCIMService sharedWFCIMService] updateMessage:callback->m_message.messageId content:callback->m_message.content];
            callback->onMediaUploaded([remoteUrl UTF8String]);
            [[WFCCIMService sharedWFCIMService] sendSavedMessage:callback->m_message expireDuration:expireDuration success:callback->m_successBlock error:callback->m_errorBlock];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error %@", error.localizedDescription);
            [[WFCCIMService sharedWFCIMService] updateMessage:callback->m_message.messageId status:Message_Status_Send_Failure];
            [ws.uploadingModelMap removeObjectForKey:@(messageId)];
            callback->onFalure(-1);
    }];
    [self.uploadingModelMap setObject:task forKey:@(messageId)];
}

- (void)uploadQiniuFile:(NSString *)url file:(NSString *)file fileSize:(int)fileSize remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];
    
    long messageId = [[[NSDate alloc] init] timeIntervalSince1970];

    WFAFHTTPSessionManager *manage = [WFAFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [WFAFHTTPRequestSerializer serializer];
    manage.responseSerializer = [WFAFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    NSURLSessionDataTask *task = [manage POST:url parameters:nil constructingBodyWithBlock:^(id<WFAFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:file] name:@"file" fileName:@"fileName" mimeType:[self mimeTypeOfFile:file] error:nil];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progressBlock((long)uploadProgress.completedUnitCount, (long)uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        successBlock(remoteUrl);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error %@", error.localizedDescription);
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        errorBlock(-1);
    }];
    [self.uploadingModelMap setObject:task forKey:@(messageId)];
}


- (void)uploadQiniuData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];

    WFAFHTTPSessionManager *manage = [WFAFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [WFAFHTTPRequestSerializer serializer];
    manage.responseSerializer = [WFAFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    long messageId = [[[NSDate alloc] init] timeIntervalSince1970];
    NSURLSessionDataTask *task = [manage POST:url parameters:nil constructingBodyWithBlock:^(id<WFAFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFormData:data name:@"file"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progressBlock((int)uploadProgress.completedUnitCount, (int)uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        successBlock(remoteUrl);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        NSLog(@"error %@", error.localizedDescription);
        errorBlock(-1);
    }];
    [self.uploadingModelMap setObject:task forKey:@(messageId)];
}

- (BOOL)sendSavedMessage:(WFCCMessage *)message
          expireDuration:(int)expireDuration
                 success:(void(^)(long long messageUid, long long timestamp))successBlock
                   error:(void(^)(int error_code))errorBlock {
    
    if(mars::stn::sendMessageEx(message.messageId, new IMSendMessageCallback(message, successBlock, nil, nil, errorBlock), expireDuration)) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)cancelSendingMessage:(long)messageId {
    BOOL canceled = mars::stn::cancelSendingMessage(messageId)?YES:NO;
    if(!canceled) {
        NSObject *upload = [self.uploadingModelMap objectForKey:@(messageId)];
        if(upload) {
            if([upload isKindOfClass:[WFCUUploadModel class]]) {
                [self.uploadingModelMap removeObjectForKey:@(messageId)];
                WFCUUploadModel *uploadModel = (WFCUUploadModel *)upload;
                [uploadModel.uploadTask cancel];
                return YES;
            } else if([upload isKindOfClass:[NSURLSessionDataTask class]]) {
                [self.uploadingModelMap removeObjectForKey:@(messageId)];
                NSURLSessionDataTask *task = (NSURLSessionDataTask *)upload;
                [task cancel];
                return YES;
            }
        }
    }
    return canceled;
}

- (void)recall:(WFCCMessage *)msg
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock {
    if (msg == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"recall msg failure, message not exist");
            if(errorBlock) {
                errorBlock(-1);
            }
        });
        return;
    }
    
    mars::stn::recallMessage(msg.messageUid, new RecallMessageCallback(msg, successBlock, errorBlock));
}
- (NSArray<WFCCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines{
    std::list<int> types;
    for (NSNumber *type in conversationTypes) {
        types.push_back([type intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    std::list<mars::stn::TConversation> convers = mars::stn::MessageDB::Instance()->GetConversationList(types, ls);
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TConversation>::iterator it = convers.begin(); it != convers.end(); it++) {
        mars::stn::TConversation &tConv = *it;
        WFCCConversationInfo *info = convertConversationInfo(tConv);
        [ret addObject:info];
    }
    return ret;
}

- (WFCCConversationInfo *)getConversationInfo:(WFCCConversation *)conversation {
    mars::stn::TConversation tConv = mars::stn::MessageDB::Instance()->GetConversation((int)conversation.type, [conversation.target UTF8String], conversation.line);
    return convertConversationInfo(tConv);
}
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation contentTypes:(NSArray<NSNumber *> *)contentTypes from:(NSUInteger)fromIndex count:(NSInteger)count withUser:(NSString *)user {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetMessages((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "");
    return convertProtoMessageList(messages, YES);
}
- (void)getMessagesV2:(WFCCConversation *)conversation
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)user
                                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                                    error:(void(^)(int error_code))errorBlock {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMessages((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "", new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (void)getMentionedMessages:(WFCCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock {
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMentionedMessages((int)conversation.type, [conversation.target UTF8String], conversation.line, direction, (int)count, fromIndex, new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetMessagesByTimes((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromTime, user ? [user UTF8String] : "");
    return convertProtoMessageList(messages, YES);
}

- (void)getMessagesV2:(WFCCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
             fromTime:(NSUInteger)fromTime
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMessagesByTimes((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromTime, user ? [user UTF8String] : "", new IMLoadMessagesCallback(successBlock, errorBlock));
}
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    std::list<int> types;
    for (NSNumber *num in messageStatus) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetMessagesByMessageStatus((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "");
    return convertProtoMessageList(messages, YES);
}

- (void)getMessagesV2:(WFCCConversation *)conversation
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    std::list<int> types;
    for (NSNumber *num in messageStatus) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMessagesByMessageStatus((int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "", new IMLoadMessagesCallback(successBlock, errorBlock));
}
- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                    contentTypes:(NSArray<NSNumber *> *)contentTypes
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetMessages(convtypes, ls, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "");
    return convertProtoMessageList(messages, YES);
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMessages(convtypes, ls, types, direction, (int)count, fromIndex, user ? [user UTF8String] : "", new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                   messageStatus:(NSArray<NSNumber *> *)messageStatus
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    std::list<int> status;
    for (NSNumber *num in messageStatus) {
        status.push_back(num.intValue);
    }

    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetMessagesByMessageStatus(convtypes, ls, status, direction, (int)count, fromIndex, user ? [user UTF8String] : "");
    return convertProtoMessageList(messages, YES);
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    std::list<int> status;
    for (NSNumber *num in messageStatus) {
        status.push_back(num.intValue);
    }

    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetMessagesByMessageStatus(convtypes, ls, status, direction, (int)count, fromIndex, user ? [user UTF8String] : "", new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(WFCCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    if (!userId.length || !conversation.target.length) {
        return nil;
    }
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetUserMessages([userId UTF8String], (int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex);
    return convertProtoMessageList(messages, YES);
}

- (void)getUserMessagesV2:(NSString *)userId
             conversation:(WFCCConversation *)conversation
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetUserMessages([userId UTF8String], (int)conversation.type, [conversation.target UTF8String], conversation.line, types, direction, (int)count, fromIndex, new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    
    if (!userId.length || !conversationTypes.count) {
        return nil;
    }
    
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }

    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    std::list<mars::stn::TMessage> messages = mars::stn::MessageDB::Instance()->GetUserMessages([userId UTF8String], convtypes, ls, types, direction, (int)count, fromIndex);
    return convertProtoMessageList(messages, YES);
}

- (void)getUserMessagesV2:(NSString *)userId
        conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }

    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    mars::stn::GetUserMessages([userId UTF8String], convtypes, ls, types, direction, (int)count, fromIndex, new IMLoadMessagesCallback(successBlock, errorBlock));
}

- (void)getRemoteMessages:(WFCCConversation *)conversation
                   before:(long long)beforeMessageUid
                    count:(NSUInteger)count
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    mars::stn::TConversation conv;
    conv.target = [conversation.target UTF8String];
    conv.line = conversation.line;
    conv.conversationType = (int)conversation.type;
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    mars::stn::loadRemoteMessages(conv, types, beforeMessageUid, (int)count, new IMLoadRemoteMessagesCallback(successBlock, errorBlock));
}

- (void)getRemoteMessage:(long long)messageUid
                 success:(void(^)(WFCCMessage *message))successBlock
                   error:(void(^)(int error_code))errorBlock {
    mars::stn::loadRemoteMessage(messageUid, new IMLoadOneRemoteMessageCallback(successBlock, errorBlock));
}

- (void)getRemoteMessages:(WFCCConversation *)conversation
               messageUid:(long long)messageUid
                    count:(NSUInteger)count
                   before:(BOOL)before
                 saveToDb:(BOOL)saveToDb
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    mars::stn::TConversation conv;
    conv.target = [conversation.target UTF8String];
    conv.line = conversation.line;
    conv.conversationType = (int)conversation.type;
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    mars::stn::loadRemoteConversationMessagesEx(conv, types, messageUid, (int)count, before, saveToDb, new IMLoadRemoteMessagesCallback(successBlock, errorBlock));
}

- (WFCCMessage *)getMessage:(long)messageId {
  mars::stn::TMessage tMsg = mars::stn::MessageDB::Instance()->GetMessageById(messageId);
  return convertProtoMessage(&tMsg);
}

- (WFCCMessage *)getMessageByUid:(long long)messageUid {
  mars::stn::TMessage tMsg = mars::stn::MessageDB::Instance()->GetMessageByUid(messageUid);
  return convertProtoMessage(&tMsg);
}

- (WFCCUnreadCount *)getUnreadCount:(WFCCConversation *)conversation {
    mars::stn::TUnreadCount tcount = mars::stn::MessageDB::Instance()->GetUnreadCount((int)conversation.type, [conversation.target UTF8String], conversation.line);
    return [WFCCUnreadCount countOf:tcount.unread mention:tcount.unreadMention mentionAll:tcount.unreadMentionAll];
}

- (WFCCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    std::list<int> types;
    std::list<int> ls;
    for (NSNumber *type in conversationTypes) {
        types.insert(types.end(), type.intValue);
    }
    
    for (NSNumber *line in lines) {
        ls.insert(ls.end(), line.intValue);
    }
    mars::stn::TUnreadCount tcount =  mars::stn::MessageDB::Instance()->GetUnreadCount(types, ls);
    return [WFCCUnreadCount countOf:tcount.unread mention:tcount.unreadMention mentionAll:tcount.unreadMentionAll];
}

- (void)clearUnreadStatus:(WFCCConversation *)conversation {
    mars::stn::MessageDB::Instance()->ClearUnreadStatus((int)conversation.type, [conversation.target UTF8String], conversation.line);
}

- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines {
    std::list<int> types;
    std::list<int> ls;
    for (NSNumber *type in conversationTypes) {
        types.insert(types.end(), type.intValue);
    }
    
    for (NSNumber *line in lines) {
        ls.insert(ls.end(), line.intValue);
    }
    mars::stn::MessageDB::Instance()->ClearUnreadStatus(types, ls);
}
- (void)clearAllUnreadStatus {
    mars::stn::MessageDB::Instance()->ClearAllUnreadStatus();
}

- (void)clearMessageUnreadStatus:(long)messageId {
    if(messageId) {
        mars::stn::MessageDB::Instance()->ClearUnreadStatus((int)messageId);
    }
}

- (void)clearMessageUnreadStatusBefore:(long)messageId conversation:(WFCCConversation *)conversation {
    if(messageId) {
        mars::stn::MessageDB::Instance()->ClearUnreadStatusBeforeMessage((int)messageId, conversation.type, conversation.target?[conversation.target UTF8String]:"", conversation.line);
    }
}

- (BOOL)markAsUnRead:(WFCCConversation *)conversation syncToOtherClient:(BOOL)sync {
    int64_t messageUid = mars::stn::MessageDB::Instance()->SetLastReceivedMessageUnRead((int)conversation.type, [conversation.target UTF8String], conversation.line, 0, 0);
    if(sync && messageUid) {
        WFCCMarkUnreadMessageContent *syncMsg = [[WFCCMarkUnreadMessageContent alloc] init];
        syncMsg.messageUid = messageUid;
        syncMsg.timestamp = [self getMessageByUid:messageUid].serverTime;
        [[WFCCIMService sharedWFCIMService] send:conversation content:syncMsg toUsers:@[[WFCCNetworkService sharedInstance].userId] expireDuration:86400 success:nil error:nil];
    }
    return messageUid > 0;
}

- (void)uploadBadgeNumber:(int)number {
    [self setUserSetting:UserSettingScope_Sync_Badge key:nil value:[NSString stringWithFormat:@"%d", number] success:nil error:nil];
}

- (void)setMediaMessagePlayed:(long)messageId {
    WFCCMessage *message = [self getMessage:messageId];
    if (!message) {
        return;
    }
    
    mars::stn::MessageDB::Instance()->updateMessageStatus(messageId, mars::stn::Message_Status_Played);
}

- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra {
    return mars::stn::MessageDB::Instance()->setMessageLocalExtra(messageId, extra ? [extra UTF8String] : "") ? YES : NO;
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(WFCCConversation *)conversation {
    std::map<std::string, int64_t> reads = mars::stn::MessageDB::Instance()->GetConversationRead((int)conversation.type, [conversation.target UTF8String], conversation.line);
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    
    for (std::map<std::string, int64_t>::iterator it = reads.begin(); it != reads.end(); ++it) {
        [ret setValue:@(it->second) forKey:[NSString stringWithUTF8String:it->first.c_str()]];
    }
    
    return ret;
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(WFCCConversation *)conversation {
    std::map<std::string, int64_t> reads = mars::stn::MessageDB::Instance()->GetDelivery((int)conversation.type, [conversation.target UTF8String]);
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    
    for (std::map<std::string, int64_t>::iterator it = reads.begin(); it != reads.end(); ++it) {
        [ret setValue:@(it->second) forKey:[NSString stringWithUTF8String:it->first.c_str()]];
    }
    
    return ret;
}

- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status {
    bool updated = mars::stn::MessageDB::Instance()->updateMessageStatus(messageId, (mars::stn::MessageStatus)status);
    if(updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
    }
    return updated ? YES : NO;
}

- (void)removeConversation:(WFCCConversation *)conversation clearMessage:(BOOL)clearMessage {
    mars::stn::MessageDB::Instance()->RemoveConversation((int)conversation.type, [conversation.target UTF8String], conversation.line, clearMessage);
}

- (void)clearMessages:(WFCCConversation *)conversation {
    mars::stn::MessageDB::Instance()->ClearMessages((int)conversation.type, [conversation.target UTF8String], conversation.line);
}

- (void)clearMessages:(WFCCConversation *)conversation before:(int64_t)before {
    mars::stn::MessageDB::Instance()->ClearMessages((int)conversation.type, conversation.target.length ? [conversation.target UTF8String] : "", conversation.line, before);
}

- (void)clearMessages:(WFCCConversation *)conversation keepLatest:(int)keepCount {
    mars::stn::MessageDB::Instance()->ClearMessagesKeepLatest((int)conversation.type, conversation.target.length ? [conversation.target UTF8String] : "", conversation.line, keepCount);
}

- (void)clearMessages:(NSString *)userId start:(int64_t)start end:(int64_t)end {
    mars::stn::MessageDB::Instance()->ClearUserMessages([userId UTF8String], start, end);
}

- (void)clearAllMessages:(BOOL)removeConversation {
    mars::stn::MessageDB::Instance()->ClearAllMessages(removeConversation);
}

- (void)setConversation:(WFCCConversation *)conversation top:(int)top
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:(UserSettingScope)mars::stn::kUserSettingConversationTop key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:[NSString stringWithFormat:@"%d", top] success:successBlock error:errorBlock];
}

- (void)setConversation:(WFCCConversation *)conversation draft:(NSString *)draft {
    mars::stn::MessageDB::Instance()->updateConversationDraft((int)conversation.type, [conversation.target UTF8String], conversation.line, draft ? [draft UTF8String] : "");
}

- (void)setConversation:(WFCCConversation *)conversation
              timestamp:(long long)timestamp {
    mars::stn::MessageDB::Instance()->updateConversationTimestamp((int)conversation.type, [conversation.target UTF8String], conversation.line, timestamp);
}

- (long)getFirstUnreadMessageId:(WFCCConversation *)conversation {
    return mars::stn::MessageDB::Instance()->GetConversationFirstUnreadMessageId((int)conversation.type, [conversation.target UTF8String], conversation.line);
}

- (void)clearRemoteConversationMessage:(WFCCConversation *)conversation
                               success:(void(^)(void))successBlock
                                 error:(void(^)(int error_code))errorBlock {
    mars::stn::clearRemoteConversationMessages((int)conversation.type, [conversation.target UTF8String], conversation.line, new IMGeneralOperationCallback(successBlock, errorBlock));
}

class IMSearchUserCallback : public mars::stn::SearchUserCallback {
private:
    void(^m_successBlock)(NSArray<WFCCUserInfo *> *machedUsers);
    void(^m_errorBlock)(int errorCode);
public:
    IMSearchUserCallback(void(^successBlock)(NSArray<WFCCUserInfo *> *machedUsers), void(^errorBlock)(int errorCode)) : m_successBlock(successBlock), m_errorBlock(errorBlock) {}
    
    void onSuccess(const std::list<mars::stn::TUserInfo> &users, const std::string &keyword, int page) {
        NSMutableArray *outUsers = [[NSMutableArray alloc] initWithCapacity:users.size()];
        for(std::list<mars::stn::TUserInfo>::const_iterator it = users.begin(); it != users.end(); it++) {
            [outUsers addObject:convertUserInfo(*it)];
        }
        m_successBlock(outUsers);
        delete this;
    }
    void onFalure(int errorCode) {
        m_errorBlock(errorCode);
        delete this;
    }
    
    ~IMSearchUserCallback() {}
};

- (void)searchUser:(NSString *)keyword
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock {
    [self searchUser:keyword domain:nil searchType:searchType page:page success:successBlock error:errorBlock];
}

- (void)searchUser:(NSString *)keyword
            domain:(NSString *)domainId
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock {
    [self searchUser:keyword domain:domainId searchType:searchType userType:UserSearchUserType_All page:page success:successBlock error:errorBlock];
}

- (void)searchUser:(NSString *)keyword
            domain:(NSString *)domainId
        searchType:(WFCCSearchUserType)searchType
          userType:(WFCCUserSearchUserType)userType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock {
    if(keyword.length == 0) {
        successBlock(@[]);
    }
    
    if (self.userSource) {
        [self.userSource searchUser:keyword domain:domainId searchType:searchType userType:userType page:page success:successBlock error:errorBlock];
        return;
    }
    
    mars::stn::searchUser(domainId?[domainId UTF8String]:"", keyword?[keyword UTF8String]:"", (int)searchType, (int)userType, page, new IMSearchUserCallback(successBlock, errorBlock));
}
class IMGetOneUserInfoCallback : public mars::stn::GetOneUserInfoCallback {
private:
    void(^m_successBlock)(WFCCUserInfo *userInfo);
    void(^m_errorBlock)(int errorCode);
public:
    IMGetOneUserInfoCallback(void(^successBlock)(WFCCUserInfo *machedUsers), void(^errorBlock)(int errorCode)) : m_successBlock(successBlock), m_errorBlock(errorBlock) {}
    
    void onSuccess(const mars::stn::TUserInfo &tUserInfo) {
        if(m_successBlock) {
            m_successBlock(convertUserInfo(tUserInfo));
        }
        delete this;
    }
    
    void onFalure(int errorCode) {
        if(m_errorBlock) {
            m_errorBlock(errorCode);
        }
        delete this;
    }
    
    ~IMGetOneUserInfoCallback() {}
};

class IMGetUserInfoCallback : public mars::stn::GetUserInfoCallback {
private:
    void(^m_successBlock)(NSArray<WFCCUserInfo *> *userInfos);
    void(^m_errorBlock)(int errorCode);
public:
    IMGetUserInfoCallback(void(^successBlock)(NSArray<WFCCUserInfo *> *machedUsers), void(^errorBlock)(int errorCode)) : m_successBlock(successBlock), m_errorBlock(errorBlock) {}
    
    void onSuccess(const std::list<mars::stn::TUserInfo> &userInfoList) {
        if(m_successBlock) {
            NSMutableArray<WFCCUserInfo *> *ret = [[NSMutableArray alloc] init];
            for (std::list<mars::stn::TUserInfo>::const_iterator it = userInfoList.begin(); it != userInfoList.end(); it++) {
                WFCCUserInfo *userInfo = convertUserInfo(*it);
                [ret addObject:userInfo];
            }
            m_successBlock(ret);
        }
        delete this;
    }
    
    void onFalure(int errorCode) {
        if(m_errorBlock) {
            m_errorBlock(errorCode);
        }
        delete this;
    }
    
    ~IMGetUserInfoCallback() {}
};

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode))errorBlock {
    if (!userId.length) {
        return;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:success:error:)]) {
        [self.userSource getUserInfo:userId refresh:refresh success:successBlock error:errorBlock];
        return;
    }
    
    mars::stn::MessageDB::Instance()->GetUserInfo([userId UTF8String], refresh ? true : false, new IMGetOneUserInfoCallback(successBlock, errorBlock));
}

- (void)getUserInfo:(NSString *)userId
            groupId:(NSString *)groupId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode))errorBlock {
    if (!userId.length) {
        return;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:groupId:refresh:success:error:)]) {
        [self.userSource getUserInfo:userId groupId:groupId refresh:refresh success:successBlock error:errorBlock];
        return;
    }
    
    mars::stn::MessageDB::Instance()->GetUserInfo([userId UTF8String], groupId.length?[groupId UTF8String]:"", refresh ? true : false, new IMGetOneUserInfoCallback(successBlock, errorBlock));
}

- (void)getUserInfos:(NSArray<NSString *> *)userIds
             groupId:(NSString *)groupId
             success:(void(^)(NSArray<WFCCUserInfo *> *userInfo))successBlock
               error:(void(^)(int errorCode))errorBlock {
    if (!userIds.count) {
        return;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfos:groupId:success:error:)]) {
        [self.userSource getUserInfos:userIds groupId:groupId success:successBlock error:errorBlock];
        return;
    }
    
    std::list<std::string> strIds;
    for (NSString *userId in userIds) {
        strIds.insert(strIds.end(), [userId UTF8String]);
    }
    
    mars::stn::MessageDB::Instance()->BatchGetUserInfos(strIds, groupId ? [groupId UTF8String] : "", new IMGetUserInfoCallback(successBlock, errorBlock));
}

- (BOOL)isMyFriend:(NSString *)userId {
    if(!userId)
        return NO;
    return mars::stn::MessageDB::Instance()->isMyFriend([userId UTF8String]);
}

- (NSArray<NSString *> *)getMyFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    std::list<std::string> friendList = mars::stn::MessageDB::Instance()->getMyFriendList(refresh);
    for (std::list<std::string>::iterator it = friendList.begin(); it != friendList.end(); it++) {
        [ret addObject:[NSString stringWithUTF8String:(*it).c_str()]];
    }
    return ret;
}

- (NSArray<WFCCFriend *> *)getFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    std::list<mars::stn::TFriend> friendList = mars::stn::MessageDB::Instance()->getFriendList(refresh);
    
    for (std::list<mars::stn::TFriend>::iterator it = friendList.begin(); it != friendList.end(); it++) {
        WFCCFriend *f = [[WFCCFriend alloc] init];
        f.userId = [NSString stringWithUTF8String:it->userId.c_str()];
        f.alias = [NSString stringWithUTF8String:it->alias.c_str()];
        f.extra = [NSString stringWithUTF8String:it->extra.c_str()];
        f.timestamp = it->timestamp;
        [ret addObject:f];
    }
    return ret;
}

- (NSArray<WFCCUserInfo *> *)searchFriends:(NSString *)keyword {
    if(!keyword)
        return nil;
    
    std::list<mars::stn::TUserInfo> friends = mars::stn::MessageDB::Instance()->SearchFriends(keyword?[keyword UTF8String]:"", 50);
    NSMutableArray<WFCCUserInfo *> *ret = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TUserInfo>::iterator it = friends.begin(); it != friends.end(); it++) {
        WFCCUserInfo *userInfo = convertUserInfo(*it);
        if (userInfo) {
            [ret addObject:userInfo];
        }
    }
  return ret;
}

NSArray *convertProtoChannelMenu(const std::vector<mars::stn::TChannelMenu> &tms) {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (std::vector<mars::stn::TChannelMenu>::const_iterator it = tms.begin(); it != tms.end(); ++it) {
        WFCCChannelMenu *cMenu = [[WFCCChannelMenu alloc] init];
        cMenu.menuId = [NSString stringWithUTF8String:it->menuId.c_str()];
        cMenu.type = [NSString stringWithUTF8String:it->type.c_str()];
        cMenu.name = [NSString stringWithUTF8String:it->name.c_str()];
        if(!it->key.empty()) cMenu.key = [NSString stringWithUTF8String:it->key.c_str()];
        if(!it->url.empty()) cMenu.url = [NSString stringWithUTF8String:it->url.c_str()];
        if(!it->mediaId.empty()) cMenu.mediaId = [NSString stringWithUTF8String:it->mediaId.c_str()];
        if(!it->articleId.empty()) cMenu.articleId = [NSString stringWithUTF8String:it->articleId.c_str()];
        if(!it->appId.empty()) cMenu.appId = [NSString stringWithUTF8String:it->appId.c_str()];
        if(!it->appPage.empty()) cMenu.appPage = [NSString stringWithUTF8String:it->appPage.c_str()];
        if(!it->extra.empty()) cMenu.extra = [NSString stringWithUTF8String:it->extra.c_str()];
        if (!it->subMenus.empty()) {
            cMenu.subMenus = convertProtoChannelMenu(it->subMenus);
        }
        [arr addObject:cMenu];
    }
    return arr;
}

WFCCChannelInfo *convertProtoChannelInfo(const mars::stn::TChannelInfo &tci) {
    if (tci.channelId.empty()) {
        return nil;
    }
    WFCCChannelInfo *channelInfo = [[WFCCChannelInfo alloc] init];
    channelInfo.channelId = [NSString stringWithUTF8String:tci.channelId.c_str()];
    channelInfo.desc = [NSString stringWithUTF8String:tci.desc.c_str()];
    channelInfo.name = [NSString stringWithUTF8String:tci.name.c_str()];
    channelInfo.extra = [NSString stringWithUTF8String:tci.extra.c_str()];
    channelInfo.portrait = [NSString stringWithUTF8String:tci.portrait.c_str()];
    if (channelInfo.portrait.length && [WFCCNetworkService sharedInstance].urlRedirector) {
        channelInfo.portrait = [[WFCCNetworkService sharedInstance].urlRedirector redirect:channelInfo.portrait];
    }
    channelInfo.owner = [NSString stringWithUTF8String:tci.owner.c_str()];
    channelInfo.secret = [NSString stringWithUTF8String:tci.secret.c_str()];
    channelInfo.callback = [NSString stringWithUTF8String:tci.callback.c_str()];
    channelInfo.status = tci.status;
    channelInfo.updateDt = tci.updateDt;
    channelInfo.menus = convertProtoChannelMenu(tci.menus);
    
    return channelInfo;
}


class IMCreateChannelCallback : public mars::stn::CreateChannelCallback {
private:
    void(^m_successBlock)(WFCCChannelInfo *channelInfo);
    void(^m_errorBlock)(int error_code);
public:
    IMCreateChannelCallback(void(^successBlock)(WFCCChannelInfo *channelInfo), void(^errorBlock)(int error_code)) : mars::stn::CreateChannelCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const mars::stn::TChannelInfo &channelInfo) {
        WFCCChannelInfo *ci = convertProtoChannelInfo(channelInfo);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(ci);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMCreateChannelCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

class IMSearchChannelCallback : public mars::stn::SearchChannelCallback {
private:
    void(^m_successBlock)(NSArray<WFCCChannelInfo *> *machedChannels);
    void(^m_errorBlock)(int errorCode);
public:
    IMSearchChannelCallback(void(^successBlock)(NSArray<WFCCChannelInfo *> *machedUsers), void(^errorBlock)(int errorCode)) : m_successBlock(successBlock), m_errorBlock(errorBlock) {}
    
    void onSuccess(const std::list<mars::stn::TChannelInfo> &users, const std::string &keyword) {
        NSMutableArray *outUsers = [[NSMutableArray alloc] initWithCapacity:users.size()];
        for(std::list<mars::stn::TChannelInfo>::const_iterator it = users.begin(); it != users.end(); it++) {
            [outUsers addObject:convertProtoChannelInfo(*it)];
        }
        m_successBlock(outUsers);
        delete this;
    }
    void onFalure(int errorCode) {
        m_errorBlock(errorCode);
        delete this;
    }
    
    ~IMSearchChannelCallback() {}
};

WFCCGroupInfo *convertProtoGroupInfo(const mars::stn::TGroupInfo &tgi) {
    if (tgi.target.empty()) {
        return nil;
    }
    WFCCGroupInfo *groupInfo = [[WFCCGroupInfo alloc] init];
    groupInfo.type = (WFCCGroupType)tgi.type;
    groupInfo.target = [NSString stringWithUTF8String:tgi.target.c_str()];
    groupInfo.name = [NSString stringWithUTF8String:tgi.name.c_str()];
    groupInfo.extra = [NSString stringWithUTF8String:tgi.extra.c_str()];;
    groupInfo.portrait = [NSString stringWithUTF8String:tgi.portrait.c_str()];
    if (groupInfo.portrait.length && [WFCCNetworkService sharedInstance].urlRedirector) {
        groupInfo.portrait = [[WFCCNetworkService sharedInstance].urlRedirector redirect:groupInfo.portrait];
    }
    
    groupInfo.owner = [NSString stringWithUTF8String:tgi.owner.c_str()];
    groupInfo.remark = [NSString stringWithUTF8String:tgi.remark.c_str()];
    groupInfo.memberCount = tgi.memberCount;
    groupInfo.mute = tgi.mute;
    groupInfo.joinType = tgi.joinType;
    groupInfo.privateChat = tgi.privateChat;
    groupInfo.searchable = tgi.searchable;
    groupInfo.historyMessage = tgi.historyMessage;
    groupInfo.maxMemberCount = tgi.maxMemberCount;
    groupInfo.superGroup = tgi.superGroup;
    groupInfo.deleted = tgi.deleted;
    groupInfo.updateDt = tgi.updateDt;
    groupInfo.memberDt = tgi.memberDt;
    
    if(!groupInfo.portrait.length && [WFCCNetworkService sharedInstance].defaultPortraitProvider && [[WFCCNetworkService sharedInstance].defaultPortraitProvider respondsToSelector:@selector(groupDefaultPortrait:memberInfos:)]) {
        __block NSMutableArray<WFCCUserInfo *> *memberUserInfos = [[NSMutableArray alloc] init];
        __block BOOL pendding = NO;
        NSArray<WFCCGroupMember *> *groupMembers = [[WFCCIMService sharedWFCIMService] getGroupMembers:groupInfo.target count:9];
        if(groupMembers.count) {
            [groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:obj.memberId refresh:NO];
                if(userInfo) {
                    [memberUserInfos addObject:userInfo];
                } else {
                    pendding = YES;
                    *stop = YES;
                }
            }];
            
            if(!pendding) {
                groupInfo.portrait = [[WFCCNetworkService sharedInstance].defaultPortraitProvider groupDefaultPortrait:groupInfo memberInfos:memberUserInfos];
            }
        }
    }
    
    return groupInfo;
}


- (NSArray<WFCCGroupSearchInfo *> *)searchGroups:(NSString *)keyword {
    if(!keyword)
        return nil;
    std::list<mars::stn::TGroupSearchResult> groups = mars::stn::MessageDB::Instance()->SearchGroups(keyword?[keyword UTF8String]:"", 50);
    NSMutableArray<WFCCGroupSearchInfo *> *ret = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TGroupSearchResult>::iterator it = groups.begin(); it != groups.end(); it++) {
        WFCCGroupSearchInfo *searchGroupInfo = [[WFCCGroupSearchInfo alloc] init];
        searchGroupInfo.groupInfo = convertProtoGroupInfo(it->groupInfo);
        searchGroupInfo.marchType = it->marchedType;
        if (!it->marchedMemberNames.empty()) {
            NSMutableArray *members = [[NSMutableArray alloc] init];
            for (std::string name : it->marchedMemberNames) {
                [members addObject:[NSString stringWithUTF8String:name.c_str()]];
            }
            searchGroupInfo.marchedMemberNames = [members copy];
        }
        searchGroupInfo.keyword = keyword;
        [ret addObject:searchGroupInfo];
    }
    return ret;
}


- (void)loadFriendRequestFromRemote {
    mars::stn::loadFriendRequestFromRemote();
}

- (NSArray<WFCCFriendRequest *> *)getIncommingFriendRequest {
    std::list<mars::stn::TFriendRequest> tRequests = mars::stn::MessageDB::Instance()->getFriendRequest(1);
    return convertFriendRequests(tRequests);
}

- (NSArray<WFCCFriendRequest *> *)getOutgoingFriendRequest {
    std::list<mars::stn::TFriendRequest> tRequests = mars::stn::MessageDB::Instance()->getFriendRequest(0);
    return convertFriendRequests(tRequests);
}

- (NSArray<WFCCFriendRequest *> *)getAllFriendRequest {
    std::list<mars::stn::TFriendRequest> tRequests = mars::stn::MessageDB::Instance()->getFriendRequest(2);
    return convertFriendRequests(tRequests);
}

- (WFCCFriendRequest *)getFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId)
        return nil;
    mars::stn::TFriendRequest tRequest = mars::stn::MessageDB::Instance()->getFriendRequest([userId UTF8String], direction);
    return convertFriendRequest(tRequest);
}

- (NSArray<WFCCFriendRequest *> *)getFriendRequestByStatus:(int)status direction:(int)direction {
    std::list<mars::stn::TFriendRequest> tRequests = mars::stn::MessageDB::Instance()->getFriendRequestByStatus(status, direction);
    return convertFriendRequests(tRequests);
}

- (int)getFriendRequestCountByStatus:(int)status direction:(int)direction {
    return mars::stn::MessageDB::Instance()->getFriendRequestCountByStatus(status, direction);
}

- (BOOL)clearFriendRequest:(int)direction beforeTime:(int64_t)beforeTime {
    return mars::stn::MessageDB::Instance()->ClearFriendRequest(direction>0, beforeTime);
}

- (BOOL)deleteFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId.length)
        return false;
    return mars::stn::MessageDB::Instance()->DeleteFriendRequest([userId UTF8String], direction>0);
}

- (void)clearUnreadFriendRequestStatus {
    mars::stn::MessageDB::Instance()->clearUnreadFriendRequestStatus();
}

- (int)getUnreadFriendRequestStatus {
    return mars::stn::MessageDB::Instance()->unreadFriendRequest();
}

- (void)sendFriendRequest:(NSString *)userId
                   reason:(NSString *)reason
                    extra:(NSString *)extra
                  success:(void(^)())successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::sendFriendRequest([userId UTF8String], reason ? [reason UTF8String] : "", extra ? [extra UTF8String] : "", new IMGeneralOperationCallback(successBlock, errorBlock));
}


- (void)handleFriendRequest:(NSString *)userId
                     accept:(BOOL)accpet
                      extra:(NSString *)extra
                    success:(void(^)())successBlock
                      error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::handleFriendRequest([userId UTF8String], accpet, extra ? [extra UTF8String] : "", new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)deleteFriend:(NSString *)userId
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::deleteFriend([userId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSString *)getFriendAlias:(NSString *)friendId {
    if(!friendId) {
        return nil;
    }
    
    std::string strAlias = mars::stn::MessageDB::Instance()->GetFriendAlias([friendId UTF8String]);
    return [NSString stringWithUTF8String:strAlias.c_str()];
}

- (void)setFriend:(NSString *)friendId
            alias:(NSString *)alias
          success:(void(^)(void))successBlock
            error:(void(^)(int error_code))errorBlock {
    if(!friendId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::setFriendAlias([friendId UTF8String], alias ? [alias UTF8String] : "", new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSString *)getFriendExtra:(NSString *)friendId {
    if(!friendId)
        return nil;
    std::string extra = mars::stn::MessageDB::Instance()->GetFriendExtra([friendId UTF8String]);
    return [NSString stringWithUTF8String:extra.c_str()];
}

- (BOOL)isBlackListed:(NSString *)userId {
    if(!userId)
        return NO;
    return mars::stn::MessageDB::Instance()->isBlackListed([userId UTF8String]);
}

- (NSArray<NSString *> *)getBlackList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    std::list<std::string> friendList = mars::stn::MessageDB::Instance()->getBlackList(refresh);
    for (std::list<std::string>::iterator it = friendList.begin(); it != friendList.end(); it++) {
        [ret addObject:[NSString stringWithUTF8String:(*it).c_str()]];
    }
    return ret;
}

- (void)setBlackList:(NSString *)userId
       isBlackListed:(BOOL)isBlackListed
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::blackListRequest([userId UTF8String], isBlackListed, new IMGeneralOperationCallback(successBlock, errorBlock));
}
- (WFCCUserInfo *)getUserInfo:(NSString *)userId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:)]) {
        return [self.userSource getUserInfo:userId refresh:refresh];
    }
    
    return [self getUserInfo:userId inGroup:nil refresh:refresh];
}

- (WFCCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:inGroup:refresh:)]) {
        return [self.userSource getUserInfo:userId inGroup:groupId refresh:refresh];
    }
    
    mars::stn::TUserInfo tui = mars::stn::MessageDB::Instance()->getUserInfo([userId UTF8String], groupId ? [groupId UTF8String] : "", refresh);
    if (!tui.uid.empty()) {
        WFCCUserInfo *userInfo = convertUserInfo(tui);
        return userInfo;
    }
    return nil;
}

- (NSArray<WFCCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId {
    if ([userIds count] == 0) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfos:inGroup:)]) {
        return [self.userSource getUserInfos:userIds inGroup:groupId];;
    }
    
    std::list<std::string> strIds;
    for (NSString *userId in userIds) {
        strIds.insert(strIds.end(), [userId UTF8String]);
    }
    std::list<mars::stn::TUserInfo> tuis = mars::stn::MessageDB::Instance()->getUserInfos(strIds, groupId ? [groupId UTF8String] : "");
    
    NSMutableArray<WFCCUserInfo *> *ret = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TUserInfo>::iterator it = tuis.begin(); it != tuis.end(); it++) {
        WFCCUserInfo *userInfo = convertUserInfo(*it);
        [ret addObject:userInfo];
    }
    return ret;
}

- (void)uploadMedia:(NSString *)fileName
          mediaData:(NSData *)mediaData
          mediaType:(WFCCMediaType)mediaType
            success:(void(^)(NSString *remoteUrl))successBlock
           progress:(void(^)(long uploaded, long total))progressBlock
              error:(void(^)(int error_code))errorBlock {
    BOOL largeMedia = NO;
    if ([[WFCCNetworkService sharedInstance] isTcpShortLink]) {
        if ([self isSupportBigFilesUpload]) {
            largeMedia = YES;
        } else {
            NSLog(@"TCP短连接不支持内置对象存储，请把对象存储切换到其他类型");
            errorBlock(-1);
            return;
        }
    } else if([self isSupportBigFilesUpload]) {
        if(mars::stn::ForcePresignedUrlUpload()) {
            largeMedia = YES;
        } else {
            largeMedia = mediaData.length > 100000000L;
        }
    }
    
    if(largeMedia) {
        __weak typeof(self)ws = self;
        [self getUploadUrl:@"" mediaType:mediaType contentType:nil success:^(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type) {
            NSString *url = ([WFCCNetworkService sharedInstance].connectedToMainNetwork || !backupUploadUrl.length)?uploadUrl:backupUploadUrl;
            if(type == 1) {
                [ws uploadQiniuData:mediaData url:url remoteUrl:downloadUrl success:successBlock progress:progressBlock error:errorBlock];
                return;
            } else {
                [ws uploadData:mediaData url:url remoteUrl:downloadUrl success:successBlock progress:progressBlock error:errorBlock];
            }
        } error:^(int error_code) {
            errorBlock(error_code);
        }];
    } else {
        mars::stn::uploadGeneralMedia(fileName == nil ? "" : [fileName UTF8String], std::string((char *)mediaData.bytes, mediaData.length), (int)mediaType, new GeneralUpdateMediaCallback(successBlock, progressBlock, errorBlock));
    }
}

- (void)uploadMediaFile:(NSString *)filePath
              mediaType:(WFCCMediaType)mediaType
                success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    long long fileSize = [fileSizeNumber longLongValue];
    
    BOOL largeMedia = NO;
    if ([[WFCCNetworkService sharedInstance] isTcpShortLink]) {
        if ([self isSupportBigFilesUpload]) {
            largeMedia = YES;
        } else {
            NSLog(@"TCP短连接不支持内置对象存储，请把对象存储切换到其他类型");
            errorBlock(-1);
            return;
        }
    } else if([self isSupportBigFilesUpload]) {
        if(mars::stn::ForcePresignedUrlUpload()) {
            largeMedia = YES;
        } else {
            largeMedia = fileSize > 100000000L;
        }
    }
    
    if(largeMedia) {
        __weak typeof(self)ws = self;
        NSString *fileContentTypeString = [self mimeTypeOfFile:filePath];
        [self getUploadUrl:[filePath lastPathComponent] mediaType:mediaType contentType:fileContentTypeString success:^(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type) {
            NSString *url = ([WFCCNetworkService sharedInstance].connectedToMainNetwork || !backupUploadUrl.length)?uploadUrl:backupUploadUrl;
            if(type == 1) {
                [ws uploadQiniuFile:url file:filePath fileSize:(int)fileSize remoteUrl:downloadUrl success:successBlock progress:progressBlock error:errorBlock];
            } else {
                [ws uploadFile:url file:filePath fileContentType:fileContentTypeString fileSize:(int)fileSize remoteUrl:downloadUrl success:successBlock progress:progressBlock error:errorBlock];
            }
        } error:^(int error_code) {
            errorBlock(error_code);
        }];
    } else {
        NSData *mediaData = [NSData dataWithContentsOfFile:filePath];
        mars::stn::uploadGeneralMedia([[filePath lastPathComponent] UTF8String], std::string((char *)mediaData.bytes, mediaData.length), (int)mediaType, new GeneralUpdateMediaCallback(successBlock, progressBlock, errorBlock));
    }
}

- (BOOL)syncUploadMedia:(NSString *)fileName
              mediaData:(NSData *)mediaData
              mediaType:(WFCCMediaType)mediaType
                success:(void(^)(NSString *remoteUrl))successBlock
            progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSCondition *condition = [[NSCondition alloc] init];
    __block BOOL success = NO;

    [condition lock];
    [[WFCCIMService sharedWFCIMService] uploadMedia:fileName mediaData:mediaData mediaType:mediaType success:^(NSString *remoteUrl) {
        successBlock(remoteUrl);
        
        success = YES;
        [condition lock];
        [condition signal];
        [condition unlock];
    } progress:^(long uploaded, long total) {
        progressBlock(uploaded, total);
    } error:^(int error_code) {
        errorBlock(error_code);
        success = NO;
        [condition lock];
        [condition signal];
        [condition unlock];
    }];
    
    [condition wait];
    [condition unlock];
    
    return success;
}

- (void)getUploadUrl:(NSString *)fileName
           mediaType:(WFCCMediaType)mediaType
         contentType:(NSString *)contentType
            success:(void(^)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type))successBlock
               error:(void(^)(int error_code))errorBlock {
    mars::stn::getUploadMediaUrl(fileName == nil ? "" : [fileName UTF8String], (int)mediaType, contentType == nil ? "" : [contentType UTF8String], new IMGetUploadMediaUrlCallback(successBlock, errorBlock));
}

- (BOOL)isSupportBigFilesUpload {
    return mars::stn::HasMediaPresignedUrl() ? YES : NO;
}

-(void)modifyMyInfo:(NSDictionary<NSNumber */*ModifyMyInfoType*/, NSString *> *)values
            success:(void(^)())successBlock
              error:(void(^)(int error_code))errorBlock {
    if (self.userSource) {
        [self.userSource modifyMyInfo:values success:successBlock error:errorBlock];
        return;
    }
    
    std::list<std::pair<int, std::string>> infos;
    for(NSNumber *key in values.allKeys) {
        infos.push_back(std::pair<int, std::string>([key intValue], [values[key] UTF8String]));
    }
    mars::stn::modifyMyInfo(infos, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (BOOL)isGlobalSilent {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Global_Silent key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setGlobalSilent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Global_Silent key:@"" value:silent?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)isVoipNotificationSilent {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Voip_Silent key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setVoipNotificationSilent:(BOOL)silent
                          success:(void(^)(void))successBlock
                            error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Voip_Silent key:@"" value:silent?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}
- (BOOL)isEnableSyncDraft {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Disable_Sync_Draft key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setEnableSyncDraft:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Disable_Sync_Draft key:@"" value:enable?@"0":@"1" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)isUserEnableReceipt {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_DisableRecipt key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableReceipt:(BOOL)enable
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_DisableRecipt key:@"" value:enable?@"0":@"1" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)isAddFriendNeedVerify {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_AddFriend_NoVerify key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setAddFriendNeedVerify:(BOOL)enable
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_AddFriend_NoVerify key:@"" value:enable?@"0":@"1" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (void)getNoDisturbingTimes:(void(^)(int startMins, int endMins))resultBlock
                       error:(void(^)(int error_code))errorBlock {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_No_Disturbing key:@""];
    if (strValue.length) {
        NSArray<NSString *> *arrs = [strValue componentsSeparatedByString:@"|"];
        if (arrs.count == 2) {
            int startMins = [arrs[0] intValue];
            int endMins = [arrs[1] intValue];
            resultBlock(startMins, endMins);
        } else {
            if(errorBlock) {
                errorBlock(-1);
            }
        }
    } else {
        if(errorBlock) {
            errorBlock(-1);
        }
    }
}

- (void)setNoDisturbingTimes:(int)startMins
                     endMins:(int)endMins
                     success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:[NSString stringWithFormat:@"%d|%d", startMins, endMins] success:successBlock error:errorBlock];
}

- (void)clearNoDisturbingTimes:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:@"" success:successBlock error:errorBlock];
}

- (BOOL)isNoDisturbing {
    __block BOOL isNoDisturbing = NO;
    [self getNoDisturbingTimes:^(int startMins, int endMins) {
        NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *nowCmps = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
        int nowMins = (int)(nowCmps.hour * 60 + nowCmps.minute);
        if (endMins > startMins) {
            if (endMins > nowMins && nowMins > startMins) {
                isNoDisturbing = YES;
            }
        } else {
            if (endMins > nowMins || nowMins > startMins) {
                isNoDisturbing = YES;
            }
        }
        
    } error:^(int error_code) {
        
    }];
    return isNoDisturbing;
}

- (BOOL)isHiddenNotificationDetail {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Hidden_Notification_Detail key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setHiddenNotificationDetail:(BOOL)hidden
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Hidden_Notification_Detail key:@"" value:hidden?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

//UserSettingScope_Hidden_Notification_Detail = 4,
- (BOOL)isHiddenGroupMemberName:(NSString *)groupId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Group_Hide_Nickname key:groupId];
    return [strValue isEqualToString:@"1"];
}

- (void)setHiddenGroupMemberName:(BOOL)hidden
                           group:(NSString *)groupId
                            success:(void(^)(void))successBlock
                              error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Group_Hide_Nickname key:groupId value:hidden?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

-(void)getMyGroups:(void(^)(NSArray<NSString *> *))successBlock
                error:(void(^)(int error_code))errorBlock {
    mars::stn::getMyGroups(new IMGeneralStringListCallback(successBlock, errorBlock));
}

- (void)getCommonGroups:(NSString *)userId
                success:(void(^)(NSArray<NSString *> *))successBlock
                  error:(void(^)(int error_code))errorBlock {
    mars::stn::getCommonGroups([userId UTF8String], new IMGeneralStringListCallback(successBlock, errorBlock));
}

- (BOOL)deleteMessage:(long)messageId {
    return mars::stn::MessageDB::Instance()->DeleteMessage(messageId) > 0;
}

- (BOOL)batchDeleteMessages:(NSArray<NSNumber *> *)messageUids {
    std::list<int64_t> uids;
    for (NSNumber *uid in messageUids) {
        uids.push_back([uid longLongValue]);
    }
    return mars::stn::MessageDB::Instance()->BatchDeleteMessage(uids);
}

- (void)deleteRemoteMessage:(long long)messageUid
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock  {
    mars::stn::deleteRemoteMessage(messageUid, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)updateRemoteMessage:(long long)messageUid
                    content:(WFCCMessageContent *)content
                 distribute:(BOOL)distribute
                updateLocal:(BOOL)updateLocal
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, content);
        
    mars::stn::updateRemoteMessageContent(messageUid, tcontent, distribute, updateLocal, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    return [self searchConversation:keyword inConversation:conversationTypes lines:lines startTime:0 endTime:0 desc:YES limit:50 offset:0];
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines startTime:(int64_t)startTime endTime:(int64_t)endTime desc:(BOOL)desc limit:(int)limit offset:(int)offset {
    std::list<int> types;
    std::list<int> ls;
    for (NSNumber *type in conversationTypes) {
        types.insert(types.end(), type.intValue);
    }
    
    for (NSNumber *line in lines) {
        ls.insert(ls.end(), line.intValue);
    }
    
    if(lines.count == 0) {
        ls.insert(ls.end(), 0);
    }
    
    std::list<mars::stn::TConversationSearchresult> tresult = mars::stn::MessageDB::Instance()->SearchConversationsEx(types, ls, keyword?[keyword UTF8String]:"", startTime, endTime, desc?YES:NO, limit, offset);
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TConversationSearchresult>::iterator it = tresult.begin(); it != tresult.end(); it++) {
        WFCCConversationSearchInfo *info = [[WFCCConversationSearchInfo alloc] init];
        [results addObject:info];
        info.conversation = [[WFCCConversation alloc] init];
        info.conversation.type = (WFCCConversationType)(it->conversationType);
        info.conversation.target = [NSString stringWithUTF8String:it->target.c_str()];
        info.conversation.line = it->line;
        info.marchedCount = it->marchedCount;
        info.marchedMessage = convertProtoMessage(&(it->marchedMessage));
        info.keyword = keyword;
        info.timestamp = it->timestamp;
    }
    return results;
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                     cntTypes:(NSArray<NSNumber *> *)cntTypes
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset
                                             onlyMentionedMsg:(BOOL)onlyMentionedMsg {
    std::list<int> types;
    std::list<int> ls;
    std::list<int> cnts;
    for (NSNumber *type in conversationTypes) {
        types.insert(types.end(), type.intValue);
    }
    
    for (NSNumber *line in lines) {
        ls.insert(ls.end(), line.intValue);
    }
    
    if(lines.count == 0) {
        ls.insert(ls.end(), 0);
    }
    
    for (NSNumber *cnt in cntTypes) {
        cnts.insert(cnts.end(), cnt.intValue);
    }
    
    
    std::list<mars::stn::TConversationSearchresult> tresult = mars::stn::MessageDB::Instance()->SearchConversationsEx2(types, ls, keyword?[keyword UTF8String]:"", cnts, startTime, endTime, desc?YES:NO, limit, offset, onlyMentionedMsg?YES:NO);
    NSMutableArray *results = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TConversationSearchresult>::iterator it = tresult.begin(); it != tresult.end(); it++) {
        WFCCConversationSearchInfo *info = [[WFCCConversationSearchInfo alloc] init];
        [results addObject:info];
        info.conversation = [[WFCCConversation alloc] init];
        info.conversation.type = (WFCCConversationType)(it->conversationType);
        info.conversation.target = [NSString stringWithUTF8String:it->target.c_str()];
        info.conversation.line = it->line;
        info.marchedCount = it->marchedCount;
        info.marchedMessage = convertProtoMessage(&(it->marchedMessage));
        info.keyword = keyword;
    }
    return results;
}
- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMessages((int)conversation.type, conversation.target ? [conversation.target UTF8String] : "", conversation.line, keyword?[keyword UTF8String]:"", desc ? true : false, limit, offset, withUser.length?[withUser UTF8String]:"");
    return convertProtoMessageList(tmessages, NO);
}

- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMessagesByTypes((int)conversation.type, conversation.target ? [conversation.target UTF8String] : "", conversation.line, keyword?[keyword UTF8String]:"", types, desc ? true : false, limit, offset, withUser.length?[withUser UTF8String]:"");
    return convertProtoMessageList(tmessages, NO);
}

- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                startTime:(int64_t)startTime
                                  endTime:(int64_t)endTime
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMessagesByTypesAndTimes((int)conversation.type, conversation.target ? [conversation.target UTF8String] : "", conversation.line, keyword?[keyword UTF8String]:"", types, startTime, endTime, desc ? true : false, limit, offset, withUser.length?[withUser UTF8String]:"");
    return convertProtoMessageList(tmessages, NO);
}

- (NSArray<WFCCMessage *> *)searchMentionedMessages:(WFCCConversation *)conversation
                                            keyword:(NSString *)keyword
                                              order:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset {
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMentionedMessages((int)conversation.type, conversation.target ? [conversation.target UTF8String] : "", conversation.line, keyword?[keyword UTF8String]:"", desc ? true : false, limit, offset);
    return convertProtoMessageList(tmessages, NO);
}

- (NSArray<WFCCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)withUser {
    
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    bool direction = true;
    if (count < 0) {
        direction = false;
        count = -count;
    }
    
    
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMessagesEx(convtypes, ls, keyword?[keyword UTF8String]:"", types, direction, (int)count, fromIndex, withUser.length?[withUser UTF8String]:"");
    return convertProtoMessageList(tmessages, NO);
}

- (NSArray<WFCCMessage *> *)searchMentionedMessage:(NSArray<NSNumber *> *)conversationTypes
                                             lines:(NSArray<NSNumber *> *)lines
                                           keyword:(NSString *)keyword
                                             order:(BOOL)desc
                                             limit:(int)limit
                                            offset:(int)offset {
    std::list<int> convtypes;
    for (NSNumber *ct in conversationTypes) {
        convtypes.push_back([ct intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    
    
    std::list<mars::stn::TMessage> tmessages = mars::stn::MessageDB::Instance()->SearchMentionedMessagesEx(convtypes, ls, keyword?[keyword UTF8String]:"", desc, limit, offset);
    return convertProtoMessageList(tmessages, NO);
}

- (void)createGroup:(NSString *)groupId
               name:(NSString *)groupName
           portrait:(NSString *)groupPortrait
               type:(WFCCGroupType)type
         groupExtra:(NSString *)groupExtra
            members:(NSArray *)groupMembers
        memberExtra:(NSString *)memberExtra
        notifyLines:(NSArray<NSNumber *> *)notifyLines
      notifyContent:(WFCCMessageContent *)notifyContent
            success:(void(^)(NSString *groupId))successBlock
              error:(void(^)(int error_code))errorBlock {

    std::list<std::string> memberList;
    for (NSString *member in groupMembers) {
        memberList.push_back([member UTF8String]);
    }
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    mars::stn::createGroup(groupId == nil ? "" : [groupId UTF8String], groupName == nil ? "" : [groupName UTF8String], groupPortrait == nil ? "" : [groupPortrait UTF8String], (int)type, groupExtra == nil ? "" : [groupExtra UTF8String], memberList, memberExtra == nil ? "" : [memberExtra UTF8String], lines, tcontent, new IMCreateGroupCallback(successBlock, errorBlock));
}

- (void)addMembers:(NSArray *)members
           toGroup:(NSString *)groupId
       memberExtra:(NSString *)memberExtra
       notifyLines:(NSArray<NSNumber *> *)notifyLines
     notifyContent:(WFCCMessageContent *)notifyContent
           success:(void(^)())successBlock
             error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }

    std::list<std::string> memberList;
    for (NSString *member in members) {
        memberList.push_back([member UTF8String]);
    }

    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::addMembers([groupId UTF8String], memberList, memberExtra == nil ? "" : [memberExtra UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)kickoffMembers:(NSArray *)members
             fromGroup:(NSString *)groupId
           notifyLines:(NSArray<NSNumber *> *)notifyLines
         notifyContent:(WFCCMessageContent *)notifyContent
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {

    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    std::list<std::string> memberList;
    for (NSString *member in members) {
        memberList.push_back([member UTF8String]);
    }

    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::kickoffMembers([groupId UTF8String], memberList, lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)quitGroup:(NSString *)groupId
      notifyLines:(NSArray<NSNumber *> *)notifyLines
    notifyContent:(WFCCMessageContent *)notifyContent
          success:(void(^)())successBlock
            error:(void(^)(int error_code))errorBlock {
    [self quitGroup:groupId keepMessage:false notifyLines:notifyLines notifyContent:notifyContent success:successBlock error:errorBlock];
}

- (void)quitGroup:(NSString *)groupId
        keepMessage:(BOOL)keepMessage
      notifyLines:(NSArray<NSNumber *> *)notifyLines
    notifyContent:(WFCCMessageContent *)notifyContent
          success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::quitGroup([groupId UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock), keepMessage);
}

- (void)dismissGroup:(NSString *)groupId
         notifyLines:(NSArray<NSNumber *> *)notifyLines
       notifyContent:(WFCCMessageContent *)notifyContent
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {

    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::dismissGroup([groupId UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)modifyGroupInfo:(NSString *)groupId
                   type:(ModifyGroupInfoType)type
               newValue:(NSString *)newValue
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::modifyGroupInfo([groupId UTF8String], (int)type, [newValue UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)modifyGroupAlias:(NSString *)groupId
                   alias:(NSString *)newAlias
             notifyLines:(NSArray<NSNumber *> *)notifyLines
           notifyContent:(WFCCMessageContent *)notifyContent
                 success:(void(^)())successBlock
                   error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::modifyGroupAlias([groupId UTF8String], newAlias ? [newAlias UTF8String] : "", lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)modifyGroupMemberAlias:(NSString *)groupId
                      memberId:(NSString *)memberId
                         alias:(NSString *)newAlias
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    
    mars::stn::modifyGroupMemberAlias([groupId UTF8String], [memberId UTF8String], newAlias.length?[newAlias UTF8String]:"", lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [self modifyGroupMemberExtra:groupId memberId:[WFCCNetworkService sharedInstance].userId extra:extra notifyLines:notifyLines notifyContent:notifyContent success:successBlock error:errorBlock];
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                      memberId:(NSString *)memberId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::modifyGroupMemberExtra([groupId UTF8String], [memberId UTF8String], [extra UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

WFCCGroupMember* convertProtoGroupMember(const mars::stn::TGroupMember &tm) {
    WFCCGroupMember *member = [[WFCCGroupMember alloc] init];
    member.groupId = [NSString stringWithUTF8String:tm.groupId.c_str()];
    member.memberId = [NSString stringWithUTF8String:tm.memberId.c_str()];
    member.alias = [NSString stringWithUTF8String:tm.alias.c_str()];
    member.extra = [NSString stringWithUTF8String:tm.extra.c_str()];
    member.type = (WFCCGroupMemberType)tm.type;
    member.createTime = tm.createDt;
    return member;;
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             forceUpdate:(BOOL)refresh {
    if(groupId.length == 0) {
        return nil;
    }
    
    std::list<mars::stn::TGroupMember> tmembers = mars::stn::MessageDB::Instance()->GetGroupMembers([groupId UTF8String], refresh);
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(std::list<mars::stn::TGroupMember>::iterator it = tmembers.begin(); it != tmembers.end(); it++) {
        WFCCGroupMember *member = convertProtoGroupMember(*it);
        [output addObject:member];
    }
    return output;
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             type:(WFCCGroupMemberType)memberType {
    if(groupId.length == 0) {
        return nil;
    }
    
    std::list<mars::stn::TGroupMember> tmembers = mars::stn::MessageDB::Instance()->GetGroupMembersByType([groupId UTF8String], (int)memberType);
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(std::list<mars::stn::TGroupMember>::iterator it = tmembers.begin(); it != tmembers.end(); it++) {
        WFCCGroupMember *member = convertProtoGroupMember(*it);
        [output addObject:member];
    }
    return output;
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                                          count:(int)count {
    if(groupId.length == 0) {
        return nil;
    }
    
    std::list<mars::stn::TGroupMember> tmembers = mars::stn::MessageDB::Instance()->GetGroupMembersByCount([groupId UTF8String], count);
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(std::list<mars::stn::TGroupMember>::iterator it = tmembers.begin(); it != tmembers.end(); it++) {
        WFCCGroupMember *member = convertProtoGroupMember(*it);
        [output addObject:member];
    }
    return output;
}

class IMGetGroupMembersCallback : public mars::stn::GetGroupMembersCallback {
private:
    void(^m_successBlock)(NSString *groupId, NSArray<WFCCGroupMember *> *memberList);
    void(^m_errorBlock)(int error_code);
public:
    IMGetGroupMembersCallback(void(^successBlock)(NSString *groupId, NSArray<WFCCGroupMember *> *memberList), void(^errorBlock)(int error_code)) : mars::stn::GetGroupMembersCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    
    void onSuccess(const std::string &groupId, const std::list<mars::stn::TGroupMember> &groupMemberList) {
        NSMutableArray *output = [[NSMutableArray alloc] init];
        for(std::list<mars::stn::TGroupMember>::const_iterator it = groupMemberList.begin(); it != groupMemberList.end(); it++) {
            WFCCGroupMember *member = convertProtoGroupMember(*it);
            [output addObject:member];
        }
        NSString *gid = [NSString stringWithUTF8String:groupId.c_str()];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(m_successBlock) {
                m_successBlock(gid, output);
            }
            delete this;
        });
        
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMGetGroupMembersCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

- (void)getGroupMembers:(NSString *)groupId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *groupId, NSArray<WFCCGroupMember *> *))successBlock
                  error:(void(^)(int errorCode))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    
    mars::stn::MessageDB::Instance()->GetGroupMembers([groupId UTF8String], refresh, new IMGetGroupMembersCallback(successBlock, errorBlock));
}

- (WFCCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId {
    if (!groupId || !memberId) {
        return nil;
    }
    mars::stn::TGroupMember tmember = mars::stn::MessageDB::Instance()->GetGroupMember([groupId UTF8String], [memberId UTF8String]);
    if (tmember.memberId == [memberId UTF8String]) {
        return convertProtoGroupMember(tmember);
    }
    return nil;
}

- (void)transferGroup:(NSString *)groupId
                   to:(NSString *)newOwner
          notifyLines:(NSArray<NSNumber *> *)notifyLines
        notifyContent:(WFCCMessageContent *)notifyContent
              success:(void(^)())successBlock
                error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    mars::stn::transferGroup([groupId UTF8String], [newOwner UTF8String], lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)setGroupManager:(NSString *)groupId
                  isSet:(BOOL)isSet
              memberIds:(NSArray<NSString *> *)memberIds
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    std::list<std::string> memberList;
    for (NSString *member in memberIds) {
        memberList.push_back([member UTF8String]);
    }
    
    mars::stn::SetGroupManager([groupId UTF8String], memberList, isSet, lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}
- (void)muteGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(WFCCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    std::list<std::string> memberList;
    for (NSString *member in memberIds) {
        memberList.push_back([member UTF8String]);
    }
    
    mars::stn::MuteOrAllowGroupMember([groupId UTF8String], memberList, isSet, false, lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)allowGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(WFCCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::TMessageContent tcontent;
    fillTMessageContent(tcontent, notifyContent);
    
    std::list<int> lines;
    for (NSNumber *number in notifyLines) {
        lines.push_back([number intValue]);
    }
    
    std::list<std::string> memberList;
    for (NSString *member in memberIds) {
        memberList.push_back([member UTF8String]);
    }
    
    mars::stn::MuteOrAllowGroupMember([groupId UTF8String], memberList, isSet, true, lines, tcontent, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSString *)getGroupRemark:(NSString *)groupId {
    return [NSString stringWithUTF8String:mars::stn::getGroupRemark([groupId UTF8String]).c_str()];
}

- (void)setGroup:(NSString *)groupId
          remark:(NSString *)remark
         success:(void(^)(void))successBlock
           error:(void(^)(int error_code))errorBlock {
    mars::stn::setGroupRemark([groupId UTF8String], remark.length?[remark UTF8String]:"", new IMSetGroupRemarkCallback(groupId, successBlock, errorBlock));
}

- (NSArray<NSString *> *)getFavGroups {
    NSDictionary *favGroupDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_Group];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favGroupDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavGroup:(NSString *)groupId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_Group key:groupId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavGroup:(NSString *)groupId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_Group key:groupId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}
- (WFCCGroupInfo *)getGroupInfo:(NSString *)groupId refresh:(BOOL)refresh {
    if (!groupId) {
        return nil;
    }
    if(![groupId isKindOfClass:NSString.class]) {
        return nil;
    }
    mars::stn::TGroupInfo tgi = mars::stn::MessageDB::Instance()->GetGroupInfo([groupId UTF8String], refresh);
    return convertProtoGroupInfo(tgi);
}

- (NSArray<WFCCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds
                                    refresh:(BOOL)refresh {
    if (![groupIds count]) {
        return nil;
    }
    
    std::list<std::string> gids;
    for (NSString *groupId : groupIds) {
        gids.push_back([groupId UTF8String]);
    }
    std::list<mars::stn::TGroupInfo> tgroupInfos = mars::stn::MessageDB::Instance()->GetGroupInfos(gids, refresh);
    NSMutableArray<WFCCGroupInfo *> *groupInfos = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TGroupInfo>::iterator it = tgroupInfos.begin(); it != tgroupInfos.end(); ++it) {
        WFCCGroupInfo *groupInfo = convertProtoGroupInfo(*it);
        [groupInfos addObject:groupInfo];
    }
    return groupInfos;
}

class IMGetOneGroupInfoCallback : public mars::stn::GetOneGroupInfoCallback {
private:
    void(^m_successBlock)(WFCCGroupInfo *);
    void(^m_errorBlock)(int error_code);
public:
    IMGetOneGroupInfoCallback(void(^successBlock)(WFCCGroupInfo *), void(^errorBlock)(int error_code)) : mars::stn::GetOneGroupInfoCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    
    void onSuccess(const mars::stn::TGroupInfo &tgi) {
        WFCCGroupInfo *gi = convertProtoGroupInfo(tgi);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(gi);
            }
                
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }
    
    virtual ~IMGetOneGroupInfoCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errorCode))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    mars::stn::MessageDB::Instance()->GetGroupInfo([groupId UTF8String], refresh, new IMGetOneGroupInfoCallback(successBlock, errorBlock));
}

- (NSString *)getUserSetting:(UserSettingScope)scope key:(NSString *)key {
    if (!key) {
        key = @"";
    }
    std::string str = mars::stn::MessageDB::Instance()->GetUserSetting((int)scope, [key UTF8String]);
    return [NSString stringWithUTF8String:str.c_str()];
}

- (NSDictionary<NSString *, NSString *> *)getUserSettings:(UserSettingScope)scope {
    std::map<std::string, std::string> settings = mars::stn::MessageDB::Instance()->GetUserSettings((int)scope);
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (std::map<std::string, std::string>::iterator it = settings.begin() ; it != settings.end(); it++) {
        NSString *key = [NSString stringWithUTF8String:it->first.c_str()];
        NSString *value = [NSString stringWithUTF8String:it->second.c_str()];
        [result setObject:value forKey:key];
    }
    return result;
}

- (void)setUserSetting:(UserSettingScope)scope key:(NSString *)key value:(NSString *)value
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {
    if(!key) {
        key = @"";
    }
    if(!value) {
        value = @"";
    }
    mars::stn::modifyUserSetting((int)scope, [key UTF8String], [value UTF8String], new IMGeneralOperationCallback(^{
        if(successBlock) {
            successBlock();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kSettingUpdated object:nil];
    }, errorBlock));
}

- (void)setConversation:(WFCCConversation *)conversation silent:(BOOL)silent
                success:(void(^)())successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:(UserSettingScope)mars::stn::kUserSettingConversationSilent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:silent ? @"1" : @"0" success:successBlock error:errorBlock];
}

- (BOOL)isConversationSilent:(WFCCConversation *)conversation {
    return [@"1" isEqualToString:[self getUserSetting:UserSettingScope_Conversation_Silent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target]]];
}

- (WFCCMessageContent *)messageContentFromPayload:(WFCCMessagePayload *)payload {
    if(self.rawMessage && (payload.contentType < 400 || payload.contentType >= 500)) {
        WFCCRawMessageContent *rawContent = [[WFCCRawMessageContent alloc] init];
        rawContent.payload = payload;
        return rawContent;
    }
    
    int contenttype = payload.contentType;
    Class contentClass = self.MessageContentMaps[@(contenttype)];
    if (contentClass != nil) {
        id messageInstance = [[contentClass alloc] init];
        
        if ([contentClass conformsToProtocol:@protocol(WFCCMessageContent)]) {
            if ([messageInstance respondsToSelector:@selector(decode:)]) {
                [messageInstance performSelector:@selector(decode:)
                                      withObject:payload];
            }
        }
        return messageInstance;
    }
    WFCCUnknownMessageContent *unknownMsg = [[WFCCUnknownMessageContent alloc] init];
    [unknownMsg decode:payload];
    return unknownMsg;
}

- (WFCCMessage *)insert:(WFCCConversation *)conversation
                 sender:(NSString *)sender
                content:(WFCCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime {
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.conversation = conversation;
    message.content = content;
    
    mars::stn::TMessage tmsg;
    fillTMessage(tmsg, conversation, content);
    
    if(status >= Message_Status_Mentioned) {
        tmsg.direction = 1;
        message.direction = MessageDirection_Receive;
        if(conversation.type == Single_Type) {
            tmsg.from = [conversation.target UTF8String];
        } else {
            tmsg.from = [sender UTF8String];
        }
    }
    message.status = status;
    tmsg.status = (mars::stn::MessageStatus)status;
    
    if(serverTime > 0) {
        message.serverTime = serverTime;
        tmsg.timestamp = serverTime;
    }
    
    if(toUsers.count) {
        for (NSString *toUser in toUsers) {
            tmsg.to.push_back([toUser UTF8String]);
        }
    }
    
    long msgId = mars::stn::MessageDB::Instance()->InsertMessage(tmsg);
    message.messageId = msgId;
    
    message.fromUser = sender;
    if (notify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:@[message]];
        [[WFCCNetworkService sharedInstance].receiveMessageDelegate onReceiveMessage:@[message] hasMore:NO];
    }
    return message;
}

- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content {
    mars::stn::TMessageContent tmc;
    fillTMessageContent(tmc, content);
    bool updated = mars::stn::MessageDB::Instance()->UpdateMessageContent(messageId, tmc);
    if(updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
    }
}

- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content
            timestamp:(long long)timestamp {
    mars::stn::TMessageContent tmc;
    fillTMessageContent(tmc, content);
    bool updated = mars::stn::MessageDB::Instance()->UpdateMessageContentAndTime(messageId, tmc, timestamp);
    if(updated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageUpdated object:@(messageId)];
    }
}

- (void)registerMessageContent:(Class)contentClass {
    int contenttype;
    if (class_getClassMethod(contentClass, @selector(getContentType))) {
        contenttype = [contentClass getContentType];
        if(self.MessageContentMaps[@(contenttype)] && ![contentClass isEqual:self.MessageContentMaps[@(contenttype)]]) {
            NSLog(@"****************************************");
            NSLog(@"Error, duplicate message content type %d", contenttype);
            NSLog(@"****************************************");
#if DEBUG
            @throw [[NSException alloc] initWithName:@"重复定义消息" reason:[NSString stringWithFormat:@"消息类型(%d)重复定义在消息(%@)和(%@)中", contenttype, NSStringFromClass(contentClass), NSStringFromClass(self.MessageContentMaps[@(contenttype)])] userInfo:nil];
#endif
        }
        self.MessageContentMaps[@(contenttype)] = contentClass;
        int contentflag = [contentClass getContentFlags];
        mars::stn::MessageDB::Instance()->RegisterMessageFlag(contenttype, contentflag);
    } else {
        return;
    }
}

- (void)registerMessageFlag:(int)contentType flag:(int)contentFlag {
    mars::stn::MessageDB::Instance()->RegisterMessageFlag(contentType, contentFlag);
}

- (void)joinChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::joinChatroom([chatroomId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)quitChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::quitChatroom([chatroomId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)getChatroomInfo:(NSString *)chatroomId
                upateDt:(long long)updateDt
                success:(void(^)(WFCCChatroomInfo *chatroomInfo))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::getChatroomInfo([chatroomId UTF8String], updateDt, new IMGetChatroomInfoCallback(chatroomId, successBlock, errorBlock));
}

- (void)getChatroomMemberInfo:(NSString *)chatroomId
                     maxCount:(int)maxCount
                      success:(void(^)(WFCCChatroomMemberInfo *memberInfo))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (maxCount <= 0) {
        maxCount = 30;
    }
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::getChatroomMemberInfo([chatroomId UTF8String], maxCount, new IMGetChatroomMemberInfoCallback(successBlock, errorBlock));
}

- (NSString *)getJoinedChatroomId {
    std::string chatroomId = mars::stn::getJoinedChatroom();
    if (chatroomId.empty()) {
        return nil;
    }
    return [NSString stringWithUTF8String:chatroomId.c_str()];
}

- (void)createChannel:(NSString *)channelName
             portrait:(NSString *)channelPortrait
                 desc:(NSString *)desc
                extra:(NSString *)extra
              success:(void(^)(WFCCChannelInfo *channelInfo))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!extra) {
        extra = @"";
    }
    //status只能是0，请参考 https://docs.wildfirechat.cn/base_knowledge/channel.html#频道属性
    mars::stn::createChannel("", [channelName UTF8String], channelPortrait ? [channelPortrait UTF8String] : "", 0, desc?[desc UTF8String]:"", [extra UTF8String], "", "", new IMCreateChannelCallback(successBlock, errorBlock));
}

- (void)destoryChannel:(NSString *)channelId
              success:(void(^)(void))successBlock
                error:(void(^)(int error_code))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::destoryChannel([channelId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (WFCCChannelInfo *)getChannelInfo:(NSString *)channelId
                            refresh:(BOOL)refresh {
    if(!channelId) {
        return nil;
    }
    mars::stn::TChannelInfo tgi = mars::stn::MessageDB::Instance()->GetChannelInfo([channelId UTF8String], refresh);
    
    return convertProtoChannelInfo(tgi);
}

- (void)modifyChannelInfo:(NSString *)channelId
                     type:(ModifyChannelInfoType)type
                 newValue:(NSString *)newValue
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!channelId || !newValue) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::modifyChannelInfo([channelId UTF8String], (int)type, [newValue UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)searchChannel:(NSString *)keyword success:(void(^)(NSArray<WFCCChannelInfo *> *machedChannels))successBlock error:(void(^)(int errorCode))errorBlock {
    
    if(!keyword.length) {
        successBlock(@[]);
        return;
    }
    mars::stn::searchChannel(keyword?[keyword UTF8String]:"", YES, new IMSearchChannelCallback(successBlock, errorBlock));
}

- (BOOL)isListenedChannel:(NSString *)channelId {
    if([@"1" isEqualToString:[self getUserSetting:UserSettingScope_Listened_Channel key:channelId]]) {
        return YES;
    }
    return NO;
}

- (void)listenChannel:(NSString *)channelId listen:(BOOL)listen success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::listenChannel([channelId UTF8String], listen, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSArray<NSString *> *)getMyChannels {
    NSDictionary *myChannelDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_My_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}
- (NSArray<NSString *> *)getListenedChannels {
    NSDictionary *myChannelDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Listened_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (void)getRemoteListenedChannels:(void(^)(NSArray<NSString *> *))successBlock error:(void(^)(int errorCode))errorBlock {
    mars::stn::getListenedChannels(new IMGeneralStringListCallback(successBlock, errorBlock));
}

- (WFCCDomainInfo *)getDomainInfo:(NSString *)domainId refresh:(BOOL)refresh {
    mars::stn::TDomainInfo tdomain = mars::stn::MessageDB::Instance()->GetDomainInfo([domainId UTF8String], refresh?true:false);
    if(tdomain.domainId.size()) {
        WFCCDomainInfo *domainInfo = [[WFCCDomainInfo alloc] init];
        domainInfo.domainId = [NSString stringWithUTF8String:tdomain.domainId.c_str()];
        domainInfo.name = [NSString stringWithUTF8String:tdomain.name.c_str()];
        domainInfo.desc = [NSString stringWithUTF8String:tdomain.desc.c_str()];
        domainInfo.email = [NSString stringWithUTF8String:tdomain.email.c_str()];
        domainInfo.tel = [NSString stringWithUTF8String:tdomain.tel.c_str()];
        domainInfo.address = [NSString stringWithUTF8String:tdomain.address.c_str()];
        domainInfo.extra = [NSString stringWithUTF8String:tdomain.extra.c_str()];
        domainInfo.updateDt = tdomain.updateDt;
        return domainInfo;
    }
    return nil;
}

- (void)getRemoteDomains:(void (^)(NSArray<WFCCDomainInfo *> *domains))successBlock error:(void (^)(int errorCode))errorBlock {
    mars::stn::loadRemoteDomains(new IMLoadRemoteDomainsCallback(successBlock, errorBlock));
}

- (void)createSecretChat:(NSString *)userId
                success:(void(^)(NSString *targetId, int line))successBlock
                  error:(void(^)(int error_code))errorBlock {
    mars::stn::createSecretChat([userId UTF8String], new IMCreateSecretChatCallback(successBlock, errorBlock));
}

- (void)destroySecretChat:(NSString *)targetId
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    mars::stn::destroySecretChat([targetId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (WFCCSecretChatInfo *)getSecretChatInfo:(NSString *)targetId {
    mars::stn::TSecretChatInfo t = mars::stn::MessageDB::Instance()->GetSecretChatInfo([targetId UTF8String]);
    if(t.targetId.empty()) {
        return nil;
    }
    WFCCSecretChatInfo *info = [[WFCCSecretChatInfo alloc] init];
    info.targetId = targetId;
    info.userId = [NSString stringWithUTF8String:t.userId.c_str()];
    info.state = (WFCCSecretChatState)t.state;
    info.burnTime = t.burnTime;
    info.createTime = t.createTime;
    return info;
}

- (NSData *)encodeSecretChat:(NSString *)targetId mediaData:(NSData *)data {
    std::string sd = mars::stn::encodeSecretChatMediaData([targetId UTF8String], (const unsigned char *)data.bytes, (int)data.length);
    if(sd.empty()) {
        return nil;
    }
    return [[NSData alloc] initWithBytes:sd.data() length:sd.length()];
}

- (NSData *)decodeSecretChat:(NSString *)targetId mediaData:(NSData *)encryptData {
    std::string sd = mars::stn::decodeSecretChatMediaData([targetId UTF8String], (const unsigned char *)encryptData.bytes, (int)encryptData.length);
    if(sd.empty()) {
        return nil;
    }
    return [[NSData alloc] initWithBytes:sd.data() length:sd.length()];
}

- (void)setSecretChat:(NSString *)targetId burnTime:(int)millisecond {
    mars::stn::MessageDB::Instance()->SetSecretChatBurnTime([targetId UTF8String], millisecond);
}

- (NSArray<WFCCPCOnlineInfo *> *)getPCOnlineInfos {
    NSString *pcOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"PC"];
    NSString *webOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Web"];
    NSString *wxOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"WX"];
    NSString *padOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Pad"];
    
    NSMutableArray *output = [[NSMutableArray alloc] init];
    if (pcOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:pcOnline withType:PC_Online]];
    }
    if (webOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:webOnline withType:Web_Online]];
    }
    if (wxOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:wxOnline withType:WX_Online]];
    }
    if (padOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:padOnline withType:Pad_Online]];
    }
    return output;
}

- (void)kickoffPCClient:(NSString *)pcClientId
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!pcClientId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::KickoffPCClient([pcClientId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (BOOL)isMuteNotificationWhenPcOnline {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Mute_When_PC_Online key:@""];
    if ([strValue isEqualToString:@"1"]) {
        return !self.defaultSilentWhenPCOnline;
    }
    return self.defaultSilentWhenPCOnline;
}

- (void)setDefaultSilentWhenPcOnline:(BOOL)defaultSilent {
    self.defaultSilentWhenPCOnline = defaultSilent;
}

- (void)muteNotificationWhenPcOnline:(BOOL)isMute
                             success:(void(^)(void))successBlock
                               error:(void(^)(int error_code))errorBlock {
    if(!self.defaultSilentWhenPCOnline) {
        isMute = !isMute;
    }
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Mute_When_PC_Online key:@"" value:isMute? @"0" : @"1" success:successBlock error:errorBlock];
}

- (void)getConversationFiles:(WFCCConversation *)conversation
                    fromUser:(NSString *)userId
            beforeMessageUid:(long long)messageUid
                       order:(WFCCFileRecordOrder)order
                       count:(int)count
                     success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                       error:(void(^)(int error_code))errorBlock {
    mars::stn::TConversation conv;
    conv.target = conversation.target ? [conversation.target UTF8String] : "";
    conv.line = conversation.line;
    conv.conversationType = (int)conversation.type;
    
    std::string fromUser = userId ? [userId UTF8String] : "";
    mars::stn::loadConversationFileRecords(conv, fromUser, messageUid, (int)order, count, new IMLoadFileRecordCallback(successBlock, errorBlock));
}

- (void)getMyFiles:(long long)beforeMessageUid
             order:(WFCCFileRecordOrder)order
             count:(int)count
           success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
             error:(void(^)(int error_code))errorBlock {
    mars::stn::loadMyFileRecords(beforeMessageUid, (int)order, count, new IMLoadFileRecordCallback(successBlock, errorBlock));
}

- (void)searchMyFiles:(NSString *)keyword
     beforeMessageUid:(long long)beforeMessageUid
                order:(WFCCFileRecordOrder)order
                count:(int)count
              success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::searchMyFileRecords(keyword?[keyword UTF8String]:"", beforeMessageUid, (int)order, count, new IMLoadFileRecordCallback(successBlock, errorBlock));
}

- (void)deleteFileRecord:(long long)messageUid
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    mars::stn::deleteFileRecords(messageUid, new IMGeneralOperationCallback(successBlock, errorBlock));
}
       
- (void)searchFiles:(NSString *)keyword
       conversation:(WFCCConversation *)conversation
           fromUser:(NSString *)userId
   beforeMessageUid:(long long)messageUid
              order:(WFCCFileRecordOrder)order
              count:(int)count
            success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::TConversation conv;
    conv.target = conversation.target ? [conversation.target UTF8String] : "";
    conv.line = conversation.line;
    conv.conversationType = (int)conversation.type;
    
    std::string fromUser = userId ? [userId UTF8String] : "";
    mars::stn::searchConversationFileRecords(keyword?[keyword UTF8String]:"", conv, fromUser, messageUid, (int)order, count, new IMLoadFileRecordCallback(successBlock, errorBlock));
}

- (void)getAuthorizedMediaUrl:(long long)messageUid
                    mediaType:(WFCCMediaType)mediaType
                    mediaPath:(NSString *)mediaPath
                      success:(void(^)(NSString *authorizedUrl, NSString *backupAuthorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (!mediaPath.length) {
        if (errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    mars::stn::getAuthorizedMediaUrl(messageUid, (int)mediaType, [mediaPath UTF8String], new IMGetAuthorizedMediaUrlCallback(successBlock, errorBlock));
}

- (void)getAuthCode:(NSString *)applicationId
               type:(int)type
               host:(NSString *)host
            success:(void(^)(NSString *authCode))successBlock
              error:(void(^)(int error_code))errorBlock {
    mars::stn::GetAuthCode([applicationId UTF8String], type, [host UTF8String], new IMGeneralStringCallback(successBlock, errorBlock));
}

- (void)configApplication:(NSString *)applicationId
                     type:(int)type
                timestamp:(int64_t)timestamp
                    nonce:(NSString *)nonce
                signature:(NSString *)signature
            success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    mars::stn::ApplicationConfig([applicationId UTF8String], type, timestamp, [nonce UTF8String], [signature UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (NSData *)getWavData:(NSString *)amrPath {
    if ([amrPath pathExtension].length>0 && ![@"amr" isEqualToString:[amrPath pathExtension]]) {
        return [NSData dataWithContentsOfFile:amrPath];
    } else {
        NSMutableData *data = [[NSMutableData alloc] init];
        decode_amr([amrPath UTF8String], data);
        return data;
    }
}

- (NSString *)imageThumbPara {
    std::string cstr = mars::stn::GetImageThumbPara();
    if (cstr.empty()) {
        return nil;
    }
    return [NSString stringWithUTF8String:cstr.c_str()];
}

- (long)insertMessage:(WFCCMessage *)message {
    mars::stn::TMessage tmsg;
    
    tmsg.messageUid = message.messageUid;
    fillTMessage(tmsg, message.conversation, message.content);
    
    if(message.status >= Message_Status_Unread) {
        tmsg.direction = 1;
    }
    if(!message.fromUser)
        message.fromUser = [WFCCNetworkService sharedInstance].userId;
    
    tmsg.from = [message.fromUser UTF8String];
    
    tmsg.status = (mars::stn::MessageStatus)message.status;
    tmsg.timestamp = message.serverTime;
    tmsg.localExtra = message.localExtra ? [message.localExtra UTF8String] : "";
    
    if(message.toUsers.count) {
        for (NSString *toUser in message.toUsers) {
            tmsg.to.push_back([toUser UTF8String]);
        }
    }
    
    long msgId = mars::stn::MessageDB::Instance()->InsertMessage(tmsg);
    message.messageId = msgId;
    
    return msgId;
}

- (int)getMessageCount:(WFCCConversation *)conversation {
    return mars::stn::MessageDB::Instance()->GetMsgTotalCount((int)conversation.type, conversation.target?[conversation.target UTF8String]:"", conversation.line);
}

- (int)getConversationMessageCount:(NSArray<NSNumber *> *)conversationTypes
                             lines:(NSArray<NSNumber *> *)lines {
    std::list<int> types;
    for (NSNumber *type in conversationTypes) {
        types.push_back([type intValue]);
    }
    
    std::list<int> ls;
    for (NSNumber *type in lines) {
        ls.push_back([type intValue]);
    }
    return mars::stn::MessageDB::Instance()->GetConversationMessageCount(types, ls);
}

- (NSDictionary<NSString *, NSNumber *> *)getMessageCountByDay:(WFCCConversation *)conversation contentTypes:(NSArray<NSNumber *> *)contentTypes startTime:(int64_t)startTime endTime:(int64_t)endTime {
    std::list<int> types;
    for (NSNumber *num in contentTypes) {
        types.push_back(num.intValue);
    }
    
    std::list<std::pair<std::string, int>> dayCounts = mars::stn::MessageDB::Instance()->GetMessageCountByDay((int)conversation.type, conversation.target?[conversation.target UTF8String]:"", conversation.line, types, startTime, endTime);
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for(std::list<std::pair<std::string, int>>::iterator it = dayCounts.begin(); it != dayCounts.end(); it++) {
        [result setValue:@(it->second) forKey:[NSString stringWithUTF8String:it->first.c_str()]];
    }
    
    return result;
}

- (BOOL)beginTransaction {
    return mars::stn::MessageDB::Instance()->BeginTransaction();
}

- (BOOL)commitTransaction {
    return mars::stn::MessageDB::Instance()->CommitTransaction();
}

- (BOOL)rollbackTransaction {
    return mars::stn::MessageDB::Instance()->RollbackTransaction();
}

- (BOOL)isCommercialServer {
    return mars::stn::IsCommercialServer() == true;
}

- (BOOL)isReceiptEnabled {
    return mars::stn::IsReceiptEnabled() == true;
}

- (BOOL)isGroupReceiptEnabled {
    return mars::stn::IsGroupReceiptEnabled() == true;
}

- (BOOL)isGlobalDisableSyncDraft {
    return mars::stn::IsGlobalDisableSyncDraft() == true;
}

- (BOOL)isMeshEnabled {
    return mars::stn::IsEnableMesh() == true;
}

- (WFCCUserOnlineState *)getUserOnlineState:(NSString *)userId {
    return self.useOnlineCacheMap[userId];
}

- (WFCCUserCustomState *)getMyCustomState {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Custom_State key:@""];
    if(strValue.length) {
        NSRange range = [strValue rangeOfString:@"-"];
        if(range.location != NSNotFound) {
            WFCCUserCustomState *state = [[WFCCUserCustomState alloc] init];
            NSString *numStr = [strValue substringToIndex:range.length];
            NSString *text = [strValue substringFromIndex:range.length+1];
            state.state = [numStr intValue];
            state.text = text;
            return state;
        }
    }
    
    return nil;
}

- (void)setMyCustomState:(WFCCUserCustomState *)state
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (!state.text) {
        state.text = @"";
    }
    NSString *strValue = [NSString stringWithFormat:@"%d-%@", state.state, state.text];
    [self setUserSetting:UserSettingScope_Custom_State key:@"" value:strValue success:successBlock error:errorBlock];
}

- (void)watchOnlineState:(WFCCConversationType)conversationType
                 targets:(NSArray<NSString *> *)targets
                duration:(int)watchDuration
                 success:(void(^)(NSArray<WFCCUserOnlineState *> *states))successBlock
                   error:(void(^)(int error_code))errorBlock {
    std::list<std::string> ts;
    for (NSString *t in targets) {
        ts.push_back([t UTF8String]);
    }

    mars::stn::watchOnlineState((int)conversationType, ts, watchDuration, new IMWatchOnlineStateCallback(successBlock, errorBlock));
}

- (void)unwatchOnlineState:(WFCCConversationType)conversationType
                   targets:(NSArray<NSString *> *)targets
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    std::list<std::string> ts;
    for (NSString *t in targets) {
        ts.push_back([t UTF8String]);
    }
    mars::stn::unwatchOnlineState((int)conversationType, ts, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (BOOL)isEnableUserOnlineState {
    return mars::stn::IsEnableUserOnlineState();
}

- (BOOL)isEnableSecretChat {
    return mars::stn::IsEnableSecretChat();
}

- (BOOL)isUserEnableSecretChat {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Disable_Secret_Chat key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableSecretChat:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Disable_Secret_Chat key:@"" value:enable?@"0":@"1" success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    [self sendConferenceRequest:sessionId room:roomId request:request data:data success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                     advanced:(BOOL)advanced
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    mars::stn::sendConferenceRequest(sessionId, roomId?[roomId UTF8String]:"", [request UTF8String], advanced?true:false, data ? [data UTF8String]:"", new IMGeneralStringCallback(successBlock, errorBlock));
}

- (NSArray<NSString *> *)getFavUsers {
    NSDictionary *favUserDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_User];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favUserDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavUser:(NSString *)userId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_User key:userId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavUser:(NSString *)userId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_User key:userId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}

- (void)requireLock:(NSString *)lockId
           duration:(NSUInteger)duration
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    mars::stn::requireLock([lockId UTF8String], duration, new IMGeneralOperationCallback(successBlock, errorBlock));
}

- (void)releaseLock:(NSString *)lockId
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    mars::stn::releaseLock([lockId UTF8String], new IMGeneralOperationCallback(successBlock, errorBlock));
}

class IMGeneralDataCallback : public mars::stn::GeneralStringCallback {
private:
    void(^m_successBlock)(NSData *generalStr);
    void(^m_errorBlock)(int error_code);
public:
    IMGeneralDataCallback(void(^successBlock)(NSData *groupId), void(^errorBlock)(int error_code)) : mars::stn::GeneralStringCallback(), m_successBlock(successBlock), m_errorBlock(errorBlock) {};
    void onSuccess(const std::string &str) {
        NSData *data = [NSData dataWithBytes:str.c_str() length:str.length()];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_successBlock) {
                m_successBlock(data);
            }
            delete this;
        });
    }
    void onFalure(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_errorBlock) {
                m_errorBlock(errorCode);
            }
            delete this;
        });
    }

    virtual ~IMGeneralDataCallback() {
        m_successBlock = nil;
        m_errorBlock = nil;
    }
};

- (void)postMomentsRequest:(NSString *)path data:(NSData *)data success:(void(^)(NSData *responseData))successBlock error:(void(^)(int error_code))errorBlock {
    std::string strData((const char*)data.bytes, data.length);
    mars::stn::sendMomentsRequest([path UTF8String], strData, new IMGeneralDataCallback(successBlock, errorBlock));
}

- (BOOL)onReceiveMessage:(WFCCMessage *)message {
    if([message.content isKindOfClass:[WFCCMarkUnreadMessageContent class]] && [message.fromUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        WFCCMarkUnreadMessageContent *markMsg = (WFCCMarkUnreadMessageContent*)message.content;
        WFCCConversation *conversation = message.conversation;
        mars::stn::MessageDB::Instance()->SetLastReceivedMessageUnRead((int)conversation.type, [conversation.target UTF8String], conversation.line, markMsg.messageUid, markMsg.timestamp);
        WFCCMessage *msg = [self getMessageByUid:markMsg.messageUid];
        NSLog(@"timestamp is %lld", msg.serverTime);
    }
    return NO;
}

- (void)putUseOnlineStates:(NSArray<WFCCUserOnlineState *> *)states {
    [states enumerateObjectsUsingBlock:^(WFCCUserOnlineState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.useOnlineCacheMap setObject:obj forKey:obj.userId];
    }];
}
@end
