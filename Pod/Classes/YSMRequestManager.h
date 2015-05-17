//
//  YSMRequestManager.h
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSMRequestTaskDataModel.h"

@interface YSMRequestManager : NSObject

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:19
 *
 *  @brief                  上传文件时的根地址
 *
 *  @param rootURLString    根地址
 *
 *  @since                  1.0.0
 */
+ (void)requestLoadFileRootURL:(NSString *)rootURLString;

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:58
 *
 *  @brief                  设置网络请求的根地址
 *
 *  @param rootURLString    根地址
 *
 *  @since                  1.0.0
 */
+ (void)requestRootURL:(NSString *)rootURLString;

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:47
 *
 *  @brief                  根据请求数据任务模型，进行数据请求
 *
 *  @param taskModel        请求任务数据模型
 *
 *  @since                  1.0.0
 */
+ (void)requestDataWithRequestTask:(YSMRequestTaskDataModel *)taskModel;

@end
