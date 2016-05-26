//
//  GJGCChatGroupDataSourceManager.m
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-29.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatGroupDataSourceManager.h"
#import "GJGCChatFriendDataSourceManager.h"


@implementation GJGCChatGroupDataSourceManager

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id<GJGCChatDetailDataSourceManagerDelegate>)aDelegate
{
    if (self = [super initWithTalk:talk withDelegate:aDelegate]) {

        self.title = talk.toUserName;
                
        [self readLastMessagesFromDB];
        
    }
    return self;
}

#pragma mark - 观察收到的消息，自己发送的消息也会当成一条收到的消息来处理插入

- (GJGCChatFriendContentModel *)addEaseMessage:(EMMessage *)aMessage
{
    /* 格式化消息 */
    GJGCChatFriendContentModel *chatContentModel = [[GJGCChatFriendContentModel alloc]init];
    chatContentModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
    chatContentModel.toId = self.talkInfo.toId;
    chatContentModel.toUserName = self.talkInfo.toUserName;
    chatContentModel.isFromSelf = [aMessage.from isEqualToString:[ZYUserCenter shareCenter].currentLoginUser.mobile]? YES:NO;
    chatContentModel.sendStatus = [[self easeMessageStateRleations][@(aMessage.status)]integerValue];
    chatContentModel.sendTime = (NSInteger)(aMessage.timestamp/1000);
    chatContentModel.localMsgId = aMessage.messageId;
    chatContentModel.senderId = aMessage.from;
    chatContentModel.isGroupChat = YES;
    GJGCMessageExtendModel *extendModel = [[GJGCMessageExtendModel alloc]initWithDictionary:aMessage.ext];
    chatContentModel.senderName = [GJGCChatFriendCellStyle formateGroupChatSenderName:extendModel.userInfo.nickName];
    chatContentModel.faildReason = @"";
    chatContentModel.faildType = 0;
    chatContentModel.talkType = self.talkInfo.talkType;
    chatContentModel.contentHeight = 0.f;
    chatContentModel.contentSize = CGSizeZero;

    /* 格式内容字段 */
    GJGCChatFriendContentType contentType = [self formateChatFriendContent:chatContentModel withMsgModel:aMessage];
    
    if (contentType != GJGCChatFriendContentTypeNotFound) {
        [self addChatContentModel:chatContentModel];
        
        //置为已读
        [self.talkInfo.conversation markMessageAsReadWithId:aMessage.messageId];
    }

    return chatContentModel;
}

#pragma mark - 读取最近历史消息

- (void)readLastMessagesFromDB
{
    //如果会话不存在
    if (!self.talkInfo.conversation) {
        self.isFinishFirstHistoryLoad = YES;
        self.isFinishLoadAllHistoryMsg = YES;
        return;
    }
    
   //读取最近20条消息
    NSArray *messages = [self.talkInfo.conversation loadMoreMessagesFromId:nil limit:20 direction:EMMessageSearchDirectionUp];
    
    for (EMMessage *theMessage in messages) {
        
        [self addEaseMessage:theMessage];
    }
    
    /* 更新时间 */
    [self updateAllMsgTimeShowString];
    
    /* 设置加载完后第一条消息和最后一条消息 */
    [self resetFirstAndLastMsgId];
    
    self.isFinishFirstHistoryLoad = YES;
    self.isFinishLoadAllHistoryMsg = NO;

}

- (void)pushAddMoreMsg:(NSArray *)array
{
    /* 分发到UI层，添加一组消息 */
    for (EMMessage *aMessage in array) {
        [self addEaseMessage:aMessage];
    }
    
    /* 重排时间顺序 */
    [self resortAllChatContentBySendTime];
    
    /* 上一次悬停的第一个cell的索引 */    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.delegate dataSourceManagerRequireFinishRefresh:weakSelf];
        });
    }
}

- (void)updateAudioFinishRead:(NSString *)localMsgId
{
    
}

#pragma mark - 更新数据库中消息得高度

- (void)updateMsgContentHeightWithContentModel:(GJGCChatContentBaseModel *)contentModel
{

}

@end
