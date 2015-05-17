//
//  YSMMappingManager.m
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMMappingManager.h"
#import "RestKit.h"
#import "RKMapperOperation.h"

@implementation YSMMappingManager

#pragma mark - 进入mapping接口
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
+ (void)mappingDataWithData:(NSData *)data mappingClass:(NSString *)mappingClass mappingCallBack:(void(^)(BOOL isSuccess,id<QSDataMappingProtocol> mappingResult,NSString *info))mappingCallBack
{

    ///查找类
    Class mappingTempObject = NSClassFromString(mappingClass);
    
    ///查找失败
    if (nil == mappingTempObject) {
        
        mappingCallBack(NO,nil,@"无法查找到对应的mapping类");
        return;
        
    }
    
    ///判断类型
    if (![mappingTempObject isSubclassOfClass:[YSMMappingBaseDataModel class]]) {
        
        mappingCallBack(NO,nil,@"给定的mappingClass无效：非YSMMappingBaseDataModel的子类");
        return;
        
    }
    
    ///获取属性的mapping规则
    RKObjectMapping *objectMapping = [mappingTempObject objectMapping];
    if (nil == objectMapping ||
        0 >= objectMapping.propertyMappings.count) {
        
        mappingCallBack(NO,nil,@"给定的mappingClass无效：无mapping属性");
        return;
        
    }
    
    [self analyzeDataWithMapping:objectMapping andData:data mappingCallBack:mappingCallBack];

}

+ (void)analyzeDataWithMapping:(RKObjectMapping *)mapping andData:(NSData *)data mappingCallBack:(void(^)(BOOL isSuccess,id<QSDataMappingProtocol> mappingResult,NSString *info))mappingCallBack
{
    
    ///数据检测
    NSParameterAssert(data);
    NSParameterAssert(mapping);
    
    NSDictionary *mappingDictionary = @{[NSNull null] : mapping};
    
    ///数据序列化错信息
    NSError *error = nil;
    
    ///数据序列化:application/json
    id parsedData = [RKMIMETypeSerialization objectFromData:data MIMEType:@"application/json" error:&error];
    
    ///判断是否序列化成功
    if (error) {
        
        NSLog(@"==================maping日志==================");
        mappingCallBack(NO,nil,[NSString stringWithFormat:@"data序列化出错： %@",error]);
        NSLog(@"==================maping日志==================");
        return;
        
    }
    
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:parsedData mappingsDictionary:mappingDictionary];
    [mapperOperation execute:&error];
    [mapperOperation waitUntilFinished];
    
    ///回调mapping结果
    mappingCallBack(YES,mapperOperation.mappingResult.dictionary[[NSNull null]],@"mapping成功");
    
}

@end
