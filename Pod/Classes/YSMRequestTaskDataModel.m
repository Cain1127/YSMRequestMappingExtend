//
//  YSMRequestTaskDataModel.m
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMRequestTaskDataModel.h"

@implementation YSMRequestTaskDataModel

#pragma mark - 初始化时设置http类型和状态
- (instancetype)init
{

    if (self = [super init]) {
        
        self.httpType = rRequestHttpTypePost;
        self.requestStatus = rRequestCurrentStatusDefault;
        
    }
    
    return self;

}

#pragma mark - 返回请求路径
- (NSString *)requestURLString
{

    if (rRequestHttpTypeGet == self.httpType) {
        
        ///拼装get参数
        if ([self.requestParams count] > 0) {
            
            NSString *tempString;
            if ([_requestURLString hasSuffix:@"?"]) {
                
                tempString = [NSString stringWithString:_requestURLString];
                
            } else {
            
                tempString = [_requestURLString stringByAppendingString:@"?"];
                
            }
            
            for (NSString *keyString in [self.requestParams allKeys]) {
                
                [tempString stringByAppendingString:keyString];
                [tempString stringByAppendingString:@"="];
                [tempString stringByAppendingString:[self.requestParams valueForKey:keyString]];
                [tempString stringByAppendingString:@"&"];
                
            }
            
            ///取消最后的字符
            return [tempString substringToIndex:([tempString length] - 1)];
            
        }
        
    }
    
    return _requestURLString;

}

@end
