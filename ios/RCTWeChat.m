//
//  RCTWeChat.m
//  RCTWeChat
//
//  Created by Koren Liu on 5/14/20.
//  Copyright © 2020 Wechat. All rights reserved.
//


#import "RCTWeChat.h"
#import "WXApiObject.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTImageLoader.h>

// Define error messages
#define NOT_REGISTERED (@"registerApp required.")
#define INVOKE_FAILED (@"WeChat API invoke returns false.")

@interface RCTWeChat ()

@property BOOL shouldEmit;

@end

@implementation RCTWeChat

RCT_EXPORT_MODULE()

- (instancetype)init
{
    self = [super init];
    if (self) {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenURL:) name:RCTOpenURLNotification object:nil];
    }
    return self;
}

- (void)dealloc{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents{
    return @[RCTWXEventNameWeChatReq,RCTWXEventName];
}

- (void)startObserving{
    _shouldEmit = YES;
}

- (void)stopObserving{
    _shouldEmit = NO;
}

- (BOOL)handleOpenURL:(NSNotification *)aNotification
{
    NSString * aURLString = [aNotification userInfo][@"url"];
    NSURL * aURL = [NSURL URLWithString:aURLString];

    if ([WXApi handleOpenURL:aURL delegate:self]){
        return YES;
    } else {
        return NO;
    }
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_METHOD(registerApp:(NSString *)appid universalLink:(NSString *)universalLink
                  :(RCTResponseSenderBlock)callback)
{
    self.appId = appid;
    BOOL result = [WXApi registerApp:appid universalLink:universalLink];
    callback(@[result ? [NSNull null] : INVOKE_FAILED]);
}

RCT_EXPORT_METHOD(isWXAppInstalled:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppInstalled])]);
}

RCT_EXPORT_METHOD(isWXAppSupportApi:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], @([WXApi isWXAppSupportApi])]);
}

RCT_EXPORT_METHOD(getWXAppInstallUrl:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getWXAppInstallUrl]]);
}

RCT_EXPORT_METHOD(getApiVersion:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNull null], [WXApi getApiVersion]]);
}

RCT_EXPORT_METHOD(openWXApp:(RCTResponseSenderBlock)callback)
{
    callback(@[([WXApi openWXApp] ? [NSNull null] : INVOKE_FAILED)]);
}

RCT_EXPORT_METHOD(sendRequest:(NSString *)openid
                  :(RCTResponseSenderBlock)callback)
{
    BaseReq* req = [[BaseReq alloc] init];
    req.openID = openid;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:req completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}

RCT_EXPORT_METHOD(sendAuthRequest:(NSString *)scope
                  :(NSString *)state
                  :(RCTResponseSenderBlock)callback)
{
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = scope;
    req.state = state;
     UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendAuthReq:req viewController:rootViewController delegate:self completion:^( BOOL success )
        {
            callback(@[success ? [NSNull null] : INVOKE_FAILED]);
            return;
        }];
    });
    

}

RCT_EXPORT_METHOD(sendSuccessResponse:(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXSuccess;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendResp:resp completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
}

RCT_EXPORT_METHOD(sendErrorCommonResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeCommon;
    resp.errStr = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendResp:resp completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}

RCT_EXPORT_METHOD(sendErrorUserCancelResponse:(NSString *)message
                  :(RCTResponseSenderBlock)callback)
{
    BaseResp* resp = [[BaseResp alloc] init];
    resp.errCode = WXErrCodeUserCancel;
    resp.errStr = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendResp:resp completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}

RCT_EXPORT_METHOD(shareToTimeline:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneTimeline callback:callback];
}

RCT_EXPORT_METHOD(shareToSession:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneSession callback:callback];
}

RCT_EXPORT_METHOD(shareToFavorite:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    [self shareToWeixinWithData:data scene:WXSceneFavorite callback:callback];
}
RCT_EXPORT_METHOD(pay:(NSDictionary *)data
                  :(RCTResponseSenderBlock)callback)
{
    PayReq* req             = [PayReq new];
    req.partnerId           = data[@"partnerId"];
    req.prepayId            = data[@"prepayId"];
    req.nonceStr            = data[@"nonceStr"];
    req.timeStamp           = [data[@"timeStamp"] unsignedIntValue];
    req.package             = data[@"package"];
    req.sign                = data[@"sign"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:req completion:^(BOOL success) {
            callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}


- (void)shareToWeixinWithData:(NSDictionary *)aData
                   thumbImage:(UIImage *)aThumbImage
                        scene:(int)aScene
                     callBack:(RCTResponseSenderBlock)callback
{
    NSString *type = aData[RCTWXShareType];

    if ([type isEqualToString:RCTWXShareTypeText]) {
        NSString *text = aData[RCTWXShareDescription];
        [self shareToWeixinWithTextMessage:aScene Text:text callBack:callback];
    } else {
        NSString * title = aData[RCTWXShareTitle];
        NSString * description = aData[RCTWXShareDescription];
        NSString * mediaTagName = aData[@"mediaTagName"];
        NSString * messageAction = aData[@"messageAction"];
        NSString * messageExt = aData[@"messageExt"];

        if (type.length <= 0 || [type isEqualToString:RCTWXShareTypeNews]) {
            NSString * webpageUrl = aData[RCTWXShareWebpageUrl];
            if (webpageUrl.length <= 0) {
                callback(@[@"webpageUrl required"]);
                return;
            }

            WXWebpageObject* webpageObject = [WXWebpageObject object];
            webpageObject.webpageUrl = webpageUrl;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:webpageObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeAudio]) {
            WXMusicObject *musicObject = [WXMusicObject new];
            musicObject.musicUrl = aData[@"musicUrl"];
            musicObject.musicLowBandUrl = aData[@"musicLowBandUrl"];
            musicObject.musicDataUrl = aData[@"musicDataUrl"];
            musicObject.musicLowBandDataUrl = aData[@"musicLowBandDataUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:musicObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeVideo]) {
            WXVideoObject *videoObject = [WXVideoObject new];
            videoObject.videoUrl = aData[@"videoUrl"];
            videoObject.videoLowBandUrl = aData[@"videoLowBandUrl"];

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:videoObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else if ([type isEqualToString:RCTWXShareTypeImageUrl] ||
                   [type isEqualToString:RCTWXShareTypeImageFile] ||
                   [type isEqualToString:RCTWXShareTypeImageResource]) {
            NSURL *url = [NSURL URLWithString:aData[RCTWXShareImageUrl]];
            NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
           [[self.bridge moduleForClass:[RCTImageLoader class]] loadImageWithURLRequest:imageRequest callback:^(NSError *error, UIImage *image) {
                if (image == nil){
                    callback(@[@"fail to load image resource"]);
                } else {
                    WXImageObject *imageObject = [WXImageObject object];
                    imageObject.imageData = UIImagePNGRepresentation(image);
                    
                    [self shareToWeixinWithMediaMessage:aScene
                                                  Title:title
                                            Description:description
                                                 Object:imageObject
                                             MessageExt:messageExt
                                          MessageAction:messageAction
                                             ThumbImage:aThumbImage
                                               MediaTag:mediaTagName
                                               callBack:callback];
                    
                }
            }];
        } else if ([type isEqualToString:RCTWXShareTypeFile]) {
            NSString * filePath = aData[@"filePath"];
            NSString * fileExtension = aData[@"fileExtension"];

            WXFileObject *fileObject = [WXFileObject object];
            fileObject.fileData = [NSData dataWithContentsOfFile:filePath];
            fileObject.fileExtension = fileExtension;

            [self shareToWeixinWithMediaMessage:aScene
                                          Title:title
                                    Description:description
                                         Object:fileObject
                                     MessageExt:messageExt
                                  MessageAction:messageAction
                                     ThumbImage:aThumbImage
                                       MediaTag:mediaTagName
                                       callBack:callback];

        } else {
            callback(@[@"message type unsupported"]);
        }
    }
}


- (void)shareToWeixinWithData:(NSDictionary *)aData scene:(int)aScene callback:(RCTResponseSenderBlock)aCallBack
{
    NSString *imageUrl = aData[RCTWXShareTypeThumbImageUrl];
    if (imageUrl.length && self.bridge) {
        NSURL *url = [NSURL URLWithString:imageUrl];
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
        [[self.bridge moduleForClass:[RCTImageLoader class]] loadImageWithURLRequest:imageRequest size:CGSizeMake(100, 100) scale:1 clipped:FALSE resizeMode:RCTResizeModeStretch progressBlock:nil partialLoadBlock:nil completionBlock:^(NSError *error, UIImage *image) {
            [self shareToWeixinWithData:aData thumbImage:image scene:aScene callBack:aCallBack];
        }];
    } else {
        [self shareToWeixinWithData:aData thumbImage:nil scene:aScene callBack:aCallBack];
    }

}

- (void)shareToWeixinWithTextMessage:(int)aScene
                                Text:(NSString *)text
                                callBack:(RCTResponseSenderBlock)callback
{
    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = YES;
    req.scene = aScene;
    req.text = text;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:req completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}

- (void)shareToWeixinWithMediaMessage:(int)aScene
                                Title:(NSString *)title
                          Description:(NSString *)description
                               Object:(id)mediaObject
                           MessageExt:(NSString *)messageExt
                        MessageAction:(NSString *)action
                           ThumbImage:(UIImage *)thumbImage
                             MediaTag:(NSString *)tagName
                             callBack:(RCTResponseSenderBlock)callback
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    message.mediaObject = mediaObject;
    message.messageExt = messageExt;
    message.messageAction = action;
    message.mediaTagName = tagName;
    [message setThumbImage:thumbImage];

    SendMessageToWXReq* req = [SendMessageToWXReq new];
    req.bText = NO;
    req.scene = aScene;
    req.message = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        [WXApi sendReq:req completion:^(BOOL success) {
          callback(@[success ? [NSNull null] : INVOKE_FAILED]);
        }];
    });
    
}


#pragma mark - wx callback

-(void)onReq:(BaseReq*)req
{
  if ([req isKindOfClass:[LaunchFromWXReq class]]) {
      LaunchFromWXReq *launchReq = (LaunchFromWXReq *)req;
      NSString *appParameter = launchReq.message.messageExt;
      NSMutableDictionary *body = @{@"errCode":@0}.mutableCopy;
      body[@"type"] = @"LaunchFromWX.Req";
      body[@"lang"] =  launchReq.lang;
      body[@"country"] = launchReq.country;
      body[@"extMsg"] = appParameter;
      if (_shouldEmit) {
          [self sendEventWithName:RCTWXEventNameWeChatReq body:body];
      }
  }
}

-(void)onResp:(BaseResp*)resp
{
  if([resp isKindOfClass:[SendMessageToWXResp class]])
  {
      SendMessageToWXResp *r = (SendMessageToWXResp *)resp;
    
      NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
      body[@"errStr"] = r.errStr;
      body[@"lang"] = r.lang;
      body[@"country"] =r.country;
      body[@"type"] = @"SendMessageToWX.Resp";
      if (_shouldEmit) {
          [self sendEventWithName:RCTWXEventName body:body];
      }
  } else if ([resp isKindOfClass:[SendAuthResp class]]) {
      SendAuthResp *r = (SendAuthResp *)resp;
      NSMutableDictionary *body = @{@"errCode":@(r.errCode)}.mutableCopy;
      body[@"errStr"] = r.errStr;
      body[@"state"] = r.state;
      body[@"lang"] = r.lang;
      body[@"country"] =r.country;
      body[@"type"] = @"SendAuth.Resp";
    
      if (resp.errCode == WXSuccess) {
          if (self.appId && r) {
        // ios第一次获取不到appid会卡死，加个判断OK
        [body addEntriesFromDictionary:@{@"appid":self.appId, @"code":r.code}];
            if (_shouldEmit) {
                [self sendEventWithName:RCTWXEventName body:body];
            }
        }
      }
      else {
        if (_shouldEmit) {
            [self sendEventWithName:RCTWXEventName body:body];
        }
      }
  }
}


@end
