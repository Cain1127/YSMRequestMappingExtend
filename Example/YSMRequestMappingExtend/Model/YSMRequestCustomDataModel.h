//
//  YSMRequestCustomDataModel.h
//  YSMRequestMappingModel
//
//  Created by ysmeng on 15/5/16.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMMappingBaseDataModel.h"

@class YSMNewsDataModel;
@interface YSMRequestCustomDataModel : YSMMappingBaseDataModel

YSMProperty_Array(YSMNewsDataModel, T1348648517839);//!<news list

@end

@interface YSMNewsDataModel : YSMMappingBaseDataModel

YSMProperty_String(title);  //!<news title
YSMProperty_String(digest); //!<news description

@end