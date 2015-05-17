//
//  YSMMappingBaseDataModel.h
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

///基本类型属性的前缀
#define YSMProperty_String_Prefix @"ysm_s_"
#define YSMProperty_MString_Prefix @"ysm_ms_"
#define YSMProperty_Array_Prefix @"ysm_a_"
#define YSMProperty_MArray_Prefix @"ysm_ma_"
#define YSMProperty_Base_Prefix @"ysm_b_"
#define YSMProperty_Class_Prefix @"ysm_c_"
#define YSMProperty_Seperation_string @"_0000_"

///C数据类型属性
#define YSMProperty_Base(propertyType,propertyName) @property (nonatomic,assign,setter = propertyName:,getter = propertyName) propertyType ysm_b_##propertyName##_

///不可变字符串mapping属性
#define YSMProperty_String(propertyName) @property (nonatomic,copy,setter = propertyName:,getter = propertyName) NSString *ysm_s_##propertyName##_

///可变字符串mapping属性
#define YSMProperty_MString(propertyName) @property (nonatomic,copy,setter = propertyName:,getter = propertyName) NSMutableString *ysm_ms_##propertyName##_

///不可变数组mapping属性
#define YSMProperty_Array(propertyClass,propertyName) @property (nonatomic,retain,setter = propertyName:,getter = propertyName) NSArray *ysm_a_##propertyClass##_0000_##propertyName##_

///可变数组mapping属性
#define YSMProperty_MArray(propertyClass,propertyName) @property (nonatomic,retain,setter = propertyName:,getter = propertyName) NSMutableArray *ysm_ma_##propertyClass##_0000_##propertyName##_

///子对象mapping属性
#define YSMProperty_Class(propertyClass,propertyName) @property (nonatomic,retain,setter = propertyName:,getter = propertyName) propertyClass *ysm_c_##propertyClass##_0000_##propertyName##_

@class RKObjectMapping;
@protocol QSDataMappingProtocol <NSObject>

@required
+ (RKObjectMapping *)objectMapping;//!<每个传给解析器的对象都必须实现mapping的方法

@end

@interface YSMMappingBaseDataModel : NSObject <QSDataMappingProtocol>

@end
