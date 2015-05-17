//
//  YSMMappingBaseDataModel.m
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMMappingBaseDataModel.h"
#import "RestKit.h"

#import <objc/runtime.h>

@implementation YSMMappingBaseDataModel

+ (RKObjectMapping *)objectMapping
{
    
    ///获取当前类的属性
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    
    ///判断是否有属性
    if (0 >= propertyCount) {
        
        return nil;
        
    }
    
    RKObjectMapping *shared_mapping = nil;
    shared_mapping = [RKObjectMapping mappingForClass:[self class]];
    
    ///遍历添加mapping规则
    NSMutableDictionary *mappingDictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < propertyCount; i++) {
        
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)  encoding:NSUTF8StringEncoding];
        
        ///基本数据类型属性
        if ([propertyName hasPrefix:YSMProperty_Base_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_Base_Prefix length];
            [mappingDictionary setValue:propertyName forKey:[propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)]];
            continue;
            
        }
        
        ///字符串类型属性
        if ([propertyName hasPrefix:YSMProperty_String_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_String_Prefix length];
            [mappingDictionary setValue:propertyName forKey:[propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)]];
            continue;
            
        }
        
        if ([propertyName hasPrefix:YSMProperty_MString_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_MString_Prefix length];
            [mappingDictionary setValue:propertyName forKey:[propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)]];
            continue;
            
        }
        
        ///数组类型
        if ([propertyName hasPrefix:YSMProperty_Array_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_Array_Prefix length];
            NSString *mainString = [propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)];
            NSArray *mainArray = [mainString componentsSeparatedByString:YSMProperty_Seperation_string];
            NSString *mappingClassName = mainArray[0];
            NSString *realName = mainArray[1];
            
            ///判断给定的类型是否是当前类的子类
            if (![NSClassFromString(mappingClassName) isSubclassOfClass:[YSMMappingBaseDataModel class]]) {
                
                continue;
                
            }
            
            [shared_mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:realName toKeyPath:propertyName withMapping:[NSClassFromString(mappingClassName) objectMapping]]];
            
            continue;
            
        }
        
        if ([propertyName hasPrefix:YSMProperty_MArray_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_MArray_Prefix length];
            NSString *mainString = [propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)];
            NSArray *mainArray = [mainString componentsSeparatedByString:YSMProperty_Seperation_string];
            NSString *mappingClassName = mainArray[0];
            NSString *realName = mainArray[1];
            
            ///判断给定的类型是否是当前类的子类
            if (![NSClassFromString(mappingClassName) isSubclassOfClass:[YSMMappingBaseDataModel class]]) {
                
                continue;
                
            }
            
            [shared_mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:realName toKeyPath:propertyName withMapping:[NSClassFromString(mappingClassName) objectMapping]]];
            
            continue;
            
        }
        
        ///子类
        if ([propertyName hasPrefix:YSMProperty_Class_Prefix]) {
            
            NSInteger prefixLenght = [YSMProperty_Class_Prefix length];
            NSString *mainString = [propertyName substringWithRange:NSMakeRange(prefixLenght, [propertyName length] - prefixLenght - 1)];
            NSArray *mainArray = [mainString componentsSeparatedByString:YSMProperty_Seperation_string];
            NSString *mappingClassName = mainArray[0];
            NSString *realName = mainArray[1];
            
            ///判断给定的类型是否是当前类的子类
            if (![NSClassFromString(mappingClassName) isSubclassOfClass:[self class]]) {
                
                continue;
                
            }
            
            [shared_mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:realName toKeyPath:propertyName withMapping:[NSClassFromString(mappingClassName) objectMapping]]];
            
            continue;
            
        }
        
    }
    
    ///添加字典
    [shared_mapping addAttributeMappingsFromDictionary:mappingDictionary];
    
    return shared_mapping;

}

@end
