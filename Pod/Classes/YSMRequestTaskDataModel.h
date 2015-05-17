//
//  YSMRequestTaskDataModel.h
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSMMappingManager.h"

///http请求的类型
typedef enum
{

    rRequestHttpTypeGet = 9999,                             //!<get请求
    rRequestHttpTypePost,                                   //!<post请求
    rRequestHttpTypeUPLoadFile,                             //!<上传单文件
    rRequestHttpTypeUPLoadFiles,                            //!<上传多文件

}REQUEST_HTTP_TYPE;

///网络请求任务的请求状态
typedef enum
{

    rRequestCurrentStatusDefault = 8888,                    //!<请求任务刚创建时的状态
    rRequestCurrentStatusRequesting,                        //!<请求任务正在请求中
    rRequestCurrentStatusFinishSuccess,                     //!<请求任务已完成-成功
    rRequestCurrentStatusFinishFail,                        //!<请求任务已完成-失败
    rRequestCurrentStatusCancel,                            //!<请求任务已取消

}REQUEST_CURRENT_STATUS;

///网络请求结果标识类型
typedef enum
{

    rRequestResultStatusSuccess = 7777,                     //!<网络请求成功
    rRequestResultStatusFail,                               //!<网络请求失败
    
    rRequestResultStatusMappingClassError,                  //!<给定的mapping类无效
    rRequestResultStatusMappingFail,                        //!<按给定的mapping类进行数据解析时不成功
    
    rRequestResultStatusHTTPTypeError,                      //!<http请求类型有误
    rRequestResultStatusURLError,                           //!<给定的URL无效
    
    rRequestResultStatusFileError,                          //!<上传文件时，无法查找到对应文件
    rRequestResultStatusFilesError,                         //!<上传文件时，无法查找到对应文件
    
    rRequestResultStatusHaveNetworking,                     //!<正在网络
    rRequestResultStatusNoNetworking,                       //!<当前无网络
    rRequestResultStatusBadNetworking,                      //!<当前网络不稳定

}REQUEST_RESULT_STATUS;

@interface YSMRequestTaskDataModel : NSObject

///http请求类型:默认post
@property (nonatomic,assign) REQUEST_HTTP_TYPE httpType;

///网络请求任务的当前状态：默认default->未开始请求
@property (nonatomic,assign) REQUEST_CURRENT_STATUS requestStatus;

@property (nonatomic,unsafe_unretained) NSObject *target;   //!<发起网络请求的对象
@property (nonatomic,copy) NSString *requestURLString;      //!<请求的路径：可以是相对路径

@property (nonatomic,copy) NSString *mappingClass;          //!<数据解析使用的类名
@property (nonatomic,copy) NSString *defaultMappingClass;   //!<最基本的数据解析模型

@property (nonatomic,retain) NSDictionary *requestParams;   //!<请求的参数
@property (nonatomic,assign) NSTimeInterval timeStamp;      //!<时间戳:一般是用来判断是否超时，不需要设置

@property (nonatomic,copy) NSString *filePath;              //!<上传单文件时的文件绝对路径
@property (nonatomic,retain) NSArray *filePaths;            //!<多文件上传时的绝对路径集合
@property (nonatomic,copy) NSString *fileParamsName;        //!<上传文件到服务端的属性名
@property (nonatomic,copy) NSString *fileName;              //!<上传文件到服务端的文件名
@property (nonatomic,copy) NSString *fileType;              //!<上传文件到服务端的文件类型

/**
 *  @author yangshengmeng, 15-05-14 18:05:54
 *
 *  @brief  请求结果的回调
 *
 *  @since  1.0.0
 */
@property (nonatomic,copy) void(^requestResultCallBack)(REQUEST_RESULT_STATUS resultStatus,id<QSDataMappingProtocol> resultData,NSError *error);

@end
