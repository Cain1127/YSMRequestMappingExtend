//
//  YSMMappingManager.h
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSMMappingBaseDataModel.h"

@interface YSMMappingManager : NSObject

/**
 *  @author                 yangshengmeng, 15-05-14 14:05:36
 *
 *  @brief                  将给定的网络请求data，转换为对定类名的数据模型
 *
 *  @param data             数据流
 *  @param mappingClass     需要转换的数据模型名字
 *  @param mappingCallBack  转换结果回调
 *
 *  @since                  1.0.0
 */
+ (void)mappingDataWithData:(NSData *)data mappingClass:(NSString *)mappingClass mappingCallBack:(void(^)(BOOL isSuccess,id<QSDataMappingProtocol> mappingResult,NSString *info))mappingCallBack;

@end
