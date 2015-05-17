//
//  YSMRequestManager.m
//  STHouse
//
//  Created by ysmeng on 15/5/14.
//  Copyright (c) 2015年 广州七升网络科技有限公司. All rights reserved.
//

#import "YSMRequestManager.h"
#import "AFHTTPRequestOperationManager.h"

///内部使用线程的标识符
#define YSM_REQUEST_QUEUE_DATA "ysm.request.queue.data"
#define YSM_REQUEST_QUEUE_TASK "ysm.request.queue.task"
#define YSM_REQUEST_QUEUE_GROUP "ysm.request.queue.group"

///自定义错误参数
#define LOCAL_ERROR_DOMAIN @"task_check_error"

#define LOCAL_ERROR_INFO_NETWORKERROR @"当前网络不可用"

#define LOCAL_ERROR_INFO_HTTPTYPE @"http请求类型错误"

#define LOCAL_ERROR_INFO_URLERROR @"无法拼装合法有效的URL地址"

#define LOCAL_ERROR_INFO_MAPPINGCLASSERROR @"给定的mapping类错误"

#define LOCAL_ERROR_INFO_FILEERROR @"无法查找到给定的文件"

#define LOCAL_ERROR_INFO_MAPPINGFAIL @"无法mapping数据"

@interface YSMRequestManager ()

///AFNetworking网络请求管理器
@property (nonatomic,strong) AFHTTPRequestOperationManager *httpRequestManager;

///网络状态监控
@property (nonatomic,strong) AFHTTPRequestOperationManager *netReachManager;

///请求任务池
@property (atomic,retain) NSMutableArray *requestTaskPool;

///网络请求的任务线程安全操作线程
@property (nonatomic,strong) dispatch_queue_t requestDataOperationQueue;

///请求任务处理使用的线程
@property (nonatomic,strong) dispatch_queue_t requestTaskQueue;

///网络请求的并发队列
@property (nonatomic,strong) dispatch_group_t requestGroup;

///网络请求的并发队列使用线程
@property (nonatomic,strong) dispatch_queue_t requestGroupQueue;

/**
 *  @author yangshengmeng, 15-05-14 21:05:51
 *
 *  @brief  请求相关的设置
 *
 *  @since  1.0.0
 */

///普通http请求的根地址
@property (nonatomic,copy) NSString *httpRequestRootURLString;

///文件上传的根地址
@property (nonatomic,copy) NSString *uploadFileRootURLString;

@end

static YSMRequestManager *_requestManager;      //!<网络请求的单例对象
static REQUEST_RESULT_STATUS _currentStatus;    //!<全局网络状态
@implementation YSMRequestManager

#pragma mark - 网络请求任务管理器单例
///网络请求任务管理器单例
+ (instancetype)shareRequestManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        ///对象初始化
        _requestManager = [[YSMRequestManager alloc] init];
        _currentStatus = rRequestResultStatusHaveNetworking;
        
        ///成员变量、属性、其他初始化
        [_requestManager initRequestManagerProperty];
        
    });
    
    return _requestManager;
    
}

#pragma mark - 网络请求相关的属性/变量等初始化
///网络请求相关的属性/变量等初始化
- (void)initRequestManagerProperty
{
    
    ///网络请求管理器初始化
    self.httpRequestManager = [AFHTTPRequestOperationManager manager];
    self.httpRequestManager.responseSerializer.acceptableContentTypes = [self.httpRequestManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    ///任务池初始化
    self.requestTaskPool = [NSMutableArray array];
    
    ///请求任务操作线程初始化
    self.requestDataOperationQueue = dispatch_queue_create(YSM_REQUEST_QUEUE_DATA,  DISPATCH_QUEUE_SERIAL);
    self.requestTaskQueue = dispatch_queue_create(YSM_REQUEST_QUEUE_TASK, DISPATCH_QUEUE_CONCURRENT);
    
    ///请求队列
    self.requestGroup = dispatch_group_create();
    self.requestGroupQueue = dispatch_queue_create(YSM_REQUEST_QUEUE_GROUP, DISPATCH_QUEUE_CONCURRENT);
    
    ///添加任务池观察
    [self addObserver:self forKeyPath:@"requestTaskPool" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    dispatch_async(self.requestTaskQueue, ^{
        
        ///开始监测网络状态
        [self starNetworkingStatusCheck];
        
    });
    
}

- (void)starNetworkingStatusCheck
{

    NSURL *baseURL = [NSURL URLWithString:@"http://www.baidu.com"];
    self.netReachManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    NSOperationQueue *operationQueue = self.netReachManager.operationQueue;
    
    __weak YSMRequestManager *weakSelf = self;
    
    [self.netReachManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                
                [operationQueue setSuspended:NO];
                [weakSelf handleRequestNetworkingFail:rRequestResultStatusHaveNetworking];
                
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
                
            default:
                
                [operationQueue setSuspended:YES];
                [weakSelf handleRequestNetworkingFail:rRequestResultStatusNoNetworking];
                
                break;
        }
        
    }];
    
    //开始监控
    [self.netReachManager.reachabilityManager startMonitoring];

}

#pragma mark - 请求任务的添加、删除和获取
- (void)addRequestTaskToPool:(YSMRequestTaskDataModel *)taskModel
{

    ///判断任务是否有效
    if (nil == taskModel) {
        
        return;
        
    }
    
    ///判断当前网络状态
    if (rRequestResultStatusNoNetworking == _currentStatus) {
        
        if (taskModel.requestResultCallBack) {
            
            taskModel.requestResultCallBack(rRequestResultStatusNoNetworking,nil,[[self class] createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusNoNetworking andErrorInfo:LOCAL_ERROR_INFO_NETWORKERROR]);
            
        }
        return;
        
    }
    
    dispatch_barrier_async(self.requestDataOperationQueue, ^{
        
        ///查询原来是否已存在消息
        int i = 0;
        NSInteger sumTaskCount = _requestTaskPool.count;
        for (i = 0; i < sumTaskCount; i++) {
            
            YSMRequestTaskDataModel *tempTaskModel = _requestTaskPool[i];
            
            ///如果原来已有对应的消息，则不再添加
            if ((tempTaskModel.httpType == taskModel.httpType) &&
                ([tempTaskModel.requestURLString isEqualToString:taskModel.requestURLString]) &&
                ([tempTaskModel.mappingClass isEqualToString:taskModel.mappingClass]) &&
                (tempTaskModel.target == taskModel.target)) {
                
                ///判断参数
                if (rRequestHttpTypeUPLoadFile == taskModel.httpType) {
                    
                    if ([tempTaskModel.filePath isEqualToString:taskModel.filePath]) {
                        
                        ///判断时间戳:超过一分钟，注销原请求
                        if (taskModel.timeStamp - tempTaskModel.timeStamp > 60.0f) {
                            
                            tempTaskModel.requestStatus = rRequestCurrentStatusCancel;
                            
                            ///没有重复的，添加
                            [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                            
                            ///结束循环
                            break;
                            
                        } else {
                            
                            ///替换原回调block和时间戳
                            tempTaskModel.timeStamp = taskModel.timeStamp;
                            tempTaskModel.requestResultCallBack = taskModel.requestResultCallBack;
                            break;
                            
                        }
                        
                    }
                    
                } else if (rRequestHttpTypeUPLoadFiles == taskModel.httpType) {
                    
                    if (![tempTaskModel.filePaths count] == [taskModel.filePaths count]) {
                        
                        ///没有重复的，添加
                        [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                        
                        ///结束循环
                        break;
                        
                    } else {
                        
                        int k = 0;
                        for (k = 0; k < [tempTaskModel.filePaths count]; k++) {
                            
                            int j = 0;
                            for (j = 0; j < [taskModel.filePaths count]; j++) {
                                
                                if ([tempTaskModel.filePaths[k] isEqualToString:taskModel.filePaths[j]]) {
                                    
                                    break;
                                    
                                }
                                
                            }
                            
                            ///如果在请求任务中没有找到相同的结果，直接认为是不同请求
                            if (j == [taskModel.filePaths count]) {
                                
                                ///没有重复的，添加
                                [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                                
                                ///结束循环
                                break;
                                
                            }
                            
                        }
                        
                        ///如果查找完所有上传文件的路径，全部相同，则注销原请求
                        if (k == [tempTaskModel.filePaths count]) {
                            
                            ///判断时间戳:超过一分钟，注销原请求
                            if (taskModel.timeStamp - tempTaskModel.timeStamp > 60.0f) {
                                
                                tempTaskModel.requestStatus = rRequestCurrentStatusCancel;
                                
                                ///没有重复的，添加
                                [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                                
                                ///结束循环
                                break;
                                
                            } else {
                                
                                ///替换原回调block和时间戳
                                tempTaskModel.timeStamp = taskModel.timeStamp;
                                tempTaskModel.requestResultCallBack = taskModel.requestResultCallBack;
                                break;
                                
                            }
                            
                        }
                        
                    }
                
                } else {
                
                    int m = 0;
                    for (m = 0; m < [tempTaskModel.requestParams count]; m++) {
                        
                        int n = 0;
                        for (n = 0; n < [taskModel.requestParams count]; n++) {
                            
                            NSString *localKey = [tempTaskModel.requestParams allKeys][m];
                            NSString *newKey = [taskModel.requestParams allKeys][n];
                            
                            ///对象
                            NSObject *localObject = [tempTaskModel valueForKey:localKey];
                            NSObject *newObject = [taskModel valueForKey:newKey];
                            
                            ///区别类型对比
                            if ([[[localObject class] description] isEqualToString:[[newObject class] description]]) {
                                
                                if ([localObject isKindOfClass:[NSString class]] ||
                                    [localObject isKindOfClass:[NSMutableString class]]) {
                                    
                                    ///字符类型
                                    NSString *localString = (NSString *)localObject;
                                    NSString *newString = (NSString *)newObject;
                                    if ([localString isEqualToString:newString]) {
                                        
                                        break;
                                        
                                    }
                                    
                                } else if ([localObject isKindOfClass:[NSNumber class]]) {
                                
                                    ///基本数字类型
                                    NSNumber *localNumber = (NSNumber *)localObject;
                                    NSNumber *newNumber = (NSNumber *)newObject;
                                    if (0.001 >= [localNumber floatValue] - [newNumber floatValue]) {
                                        
                                        break;
                                        
                                    }
                                
                                } else if ([localObject isKindOfClass:[NSArray class]] ||
                                           [localObject isKindOfClass:[NSMutableArray class]]) {
                                
                                    ///数组类型
                                    NSArray *localArray = (NSArray *)localObject;
                                    NSArray *newArray = (NSArray *)newObject;
                                    if ([localArray count] == [newArray count]) {
                                        
                                        break;
                                        
                                    }
                                
                                } else if ([localObject isKindOfClass:[NSDictionary class]] ||
                                           [localObject isKindOfClass:[NSMutableDictionary class]]) {
                                
                                    ///字典类型
                                    NSDictionary *localDict = (NSDictionary *)localObject;
                                    NSDictionary *newDict = (NSDictionary *)newObject;
                                    if ([localDict count] == [newDict count]) {
                                        
                                        break;
                                        
                                    }
                                
                                }
                                
                            }
                            
                        }
                        
                        ///只要有一个不相同，则认为是新网络请求
                        if (n == [taskModel.requestParams count]) {
                            
                            [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                            
                            ///结束循环
                            break;
                            
                        }
                        
                    }
                    
                    ///如果参数完成相同，判断时间戳
                    if (m == [tempTaskModel.requestParams count]) {
                        
                        ///判断时间戳:超过一分钟，注销原请求
                        if (taskModel.timeStamp - tempTaskModel.timeStamp > 60.0f) {
                            
                            tempTaskModel.requestStatus = rRequestCurrentStatusCancel;
                            
                            ///没有重复的，添加
                            [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
                            
                            ///结束循环
                            break;
                            
                        } else {
                            
                            ///替换原回调block和时间戳
                            tempTaskModel.timeStamp = taskModel.timeStamp;
                            tempTaskModel.requestResultCallBack = taskModel.requestResultCallBack;
                            break;
                            
                        }
                        
                    }
                
                }
                
            }
            
        }
        
        ///如果遍历完没有重复项，则添加
        if (i == sumTaskCount) {
            
            ///没有重复的，添加
            [[self mutableArrayValueForKey:@"requestTaskPool"] addObject:taskModel];
            
        }
        
    });

}

///删除完成或者已注销的请求任务
- (void)removeFinishRequestTaskFromTaskPool
{
    
    ///如果任务池已为空，则不再删除
    if (0 >= [_requestTaskPool count]) {
        
        return;
        
    }
    
    ///在指定线程中删除元素
    dispatch_barrier_async(self.requestDataOperationQueue, ^{
        
        for (int i = (int)[_requestTaskPool count]; i > 0; i--) {
            
            YSMRequestTaskDataModel *tempModel = _requestTaskPool[i - 1];
            if (tempModel.requestStatus == rRequestCurrentStatusFinishSuccess ||
                tempModel.requestStatus == rRequestCurrentStatusFinishFail ||
                tempModel.requestStatus == rRequestCurrentStatusCancel) {
                
                [[self mutableArrayValueForKey:@"requestTaskPool"] removeObjectAtIndex:i - 1];
                
            }
            
        }
        
    });
    
}

///返回当前的任务池
- (NSArray *)getRequestTaskPoolsArray
{
    
    __block NSArray *tempArray = nil;
    
    dispatch_sync(self.requestDataOperationQueue, ^{
        
        tempArray = [NSArray arrayWithArray:_requestTaskPool];
        
    });
    
    return tempArray;
    
}

#pragma mark - 任务池变动时发起请求
///任务池观察者回调：当任务池有数据变动时，此方法捕抓
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    ///在任务处理线程处理请求任务
    dispatch_async(self.requestTaskQueue, ^{
        
        ///观察是否清空
        if (0 >= [self.requestTaskPool count]) {
            
            return;
            
        }
        
        ///判断当前网络状态
        if (rRequestResultStatusNoNetworking == _currentStatus) {
            
            return;
            
        }
        
        ///开启并发队列
        NSArray *taskList = [self getRequestTaskPoolsArray];
        dispatch_apply([taskList count], self.requestGroupQueue, ^(size_t i){
            
            ///进入队列
            dispatch_group_enter(self.requestGroup);
            
            ///如若还有请求任务，取第一个任务执行
            YSMRequestTaskDataModel *requestTask = taskList[i];
            switch (requestTask.requestStatus) {
                    ///新添加的请求任务
                case rRequestCurrentStatusDefault:
                {
                    
                    requestTask.requestStatus = rRequestCurrentStatusRequesting;
                    [self startRequestDataWithRequestTaskModel:requestTask];
                    
                }
                    break;
                    
                    ///请求任务正在进行中
                case rRequestCurrentStatusRequesting:
                {
                    
                    NSLog(@"====================网络请求任务日志====================");
                    NSLog(@"当前任务正在请求中，不再重复发起请求");
                    NSLog(@"====================网络请求任务日志====================");
                    
                }
                    break;
                    
                    ///请求任务已完成
                case rRequestCurrentStatusFinishSuccess:
                {
                    
                    NSLog(@"====================网络请求任务日志====================");
                    NSLog(@"当前任务已完成->成功");
                    NSLog(@"====================网络请求任务日志====================");
                    
                }
                    break;
                    
                    ///请求任务已完成
                case rRequestCurrentStatusFinishFail:
                {
                    
                    NSLog(@"====================网络请求任务日志====================");
                    NSLog(@"当前任务已完成->失败");
                    NSLog(@"====================网络请求任务日志====================");
                    
                }
                    break;
                    
                    ///请求任务已取消
                case rRequestCurrentStatusCancel:
                {
                    
                    NSLog(@"====================网络请求任务日志====================");
                    NSLog(@"当前任务已取消");
                    NSLog(@"====================网络请求任务日志====================");
                    
                }
                    break;
                    
                default:
                    break;
            }
            
        });
        
    });
    
}

///开始请求数据
- (void)startRequestDataWithRequestTaskModel:(YSMRequestTaskDataModel *)taskModel
{
    
    ///根据请求任务中的请求类型，使用不同的请求
    if (rRequestHttpTypeGet == taskModel.httpType) {
        
        [self.httpRequestManager GET:taskModel.requestURLString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            taskModel.requestStatus = rRequestCurrentStatusFinishSuccess;
            [self handleRequestSuccess:responseObject andRespondData:operation.responseData andTaskModel:taskModel];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            ///请求失败时处理失败回调
            taskModel.requestStatus = rRequestCurrentStatusFinishFail;
            [self handleRequestFail:error andFailCallBack:taskModel.requestResultCallBack];
            
        }];
        
        return;
        
    }
    
    ///POST请求
    if (rRequestHttpTypePost == taskModel.httpType) {
        
        ///请求参数
        NSDictionary *postParams = taskModel.requestParams ? taskModel.requestParams : nil;
        
        [self.httpRequestManager POST:taskModel.requestURLString parameters:postParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            ///请求成功
            taskModel.requestStatus = rRequestCurrentStatusFinishSuccess;
            [self handleRequestSuccess:responseObject andRespondData:operation.responseData andTaskModel:taskModel];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            ///请求失败
            taskModel.requestStatus = rRequestCurrentStatusFinishFail;
            [self handleRequestFail:error andFailCallBack:taskModel.requestResultCallBack];
            
        }];
        
        return;
        
    }
    
    ///单文件上传
    if (rRequestHttpTypeUPLoadFile == taskModel.httpType) {
        
        ///获取图片
        NSString *imagePath = [taskModel.requestParams valueForKey:@"attach_file"];
        __block NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
        if (nil == imageData || 0 >= [imageData length] ||
            [taskModel.fileName length] <= 0 ||
            [taskModel.fileType length] <= 0) {
            
            taskModel.requestStatus = rRequestCurrentStatusFinishFail;
            [self handleRequestFail:[[self class] createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusFileError andErrorInfo:@"文件获取失败/文件名无效/文件类型无效"] andFailCallBack:taskModel.requestResultCallBack];
            return;
            
        }
        
        ///封装图片上传的post参数
        NSMutableDictionary *tempParams = [taskModel.requestParams mutableCopy];
        if ([taskModel.fileParamsName length] > 0) {
            
            [tempParams removeObjectForKey:taskModel.fileParamsName];
            
        }
        
        [self.httpRequestManager POST:taskModel.requestURLString parameters:tempParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            [formData appendPartWithFileData:imageData name:taskModel.fileParamsName fileName:taskModel.fileName mimeType:taskModel.fileType];
            
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            ///请求成功
            taskModel.requestStatus = rRequestCurrentStatusFinishSuccess;
            [self handleRequestSuccess:responseObject andRespondData:operation.responseData andTaskModel:taskModel];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            ///请求失败时处理失败回调
            taskModel.requestStatus = rRequestCurrentStatusFinishFail;
            [self handleRequestFail:error andFailCallBack:taskModel.requestResultCallBack];
            
        }];
        
        return;
        
    }
    
}

///处理请求成功时的回调
- (void)handleRequestSuccess:(id)responseObject andRespondData:(NSData *)respondData andTaskModel:(YSMRequestTaskDataModel *)tempTaskModel
{
    
    ///解析数据
    [YSMMappingManager mappingDataWithData:respondData mappingClass:tempTaskModel.mappingClass mappingCallBack:^(BOOL isSuccess, id<QSDataMappingProtocol> mappingResult, NSString *info) {
        
        if (isSuccess) {
            
            if (tempTaskModel.requestResultCallBack) {
                
                tempTaskModel.requestResultCallBack(rRequestResultStatusSuccess,mappingResult,nil);
                
            }
            
            ///开启下一次的请求
            tempTaskModel.requestStatus = rRequestCurrentStatusFinishSuccess;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), self.requestTaskQueue, ^{
                
                [self removeFinishRequestTaskFromTaskPool];
                
            });
            
        } else {
        
            ///回调失败
            if (tempTaskModel.requestResultCallBack) {
                
                tempTaskModel.requestResultCallBack(rRequestResultStatusMappingFail,nil,[[self class] createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusMappingFail andErrorInfo:LOCAL_ERROR_INFO_MAPPINGFAIL]);
                
            }
            
            ///开启下一次的请求
            tempTaskModel.requestStatus = rRequestCurrentStatusFinishFail;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), self.requestTaskQueue, ^{
                
                [self removeFinishRequestTaskFromTaskPool];
                
            });
        
        }
        
    }];
    
}

///处理请求失败时的回调
- (void)handleRequestFail:(NSError *)error andFailCallBack:(void(^)(REQUEST_RESULT_STATUS resultStaus,id<QSDataMappingProtocol>,NSError *error))callBack
{
    
    if (callBack) {
        
        ///回调
        callBack(rRequestResultStatusFail,nil,error);
        
    }
    
    ///开启下一次的请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), self.requestTaskQueue, ^{
        
        [self removeFinishRequestTaskFromTaskPool];
        
    });
    
}

///处理网络异常
- (void)handleRequestNetworkingFail:(REQUEST_RESULT_STATUS)networkStatus
{
    
    ///开启/停止网络请求
    if (rRequestResultStatusHaveNetworking == networkStatus) {
        
        ///更新当前网络状态
        _currentStatus = networkStatus;
        
        ///开启队列
        dispatch_group_wait(self.requestGroup, DISPATCH_TIME_NOW);
        
    }
    
    if (rRequestResultStatusNoNetworking == networkStatus) {
        
        ///更新当前网络状态
        _currentStatus = networkStatus;
        
        ///沉睡队列线程
        dispatch_group_wait(self.requestGroup, DISPATCH_TIME_FOREVER);
        
        ///回调通知
        NSArray *tempTaskArray = [self getRequestTaskPoolsArray];
        for (int i = 0; i < [tempTaskArray count]; i++) {
            
            YSMRequestTaskDataModel *requestModel = tempTaskArray[i];
            if (requestModel.requestResultCallBack) {
                
                requestModel.requestResultCallBack(rRequestResultStatusNoNetworking,nil,[[self class] createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusNoNetworking andErrorInfo:LOCAL_ERROR_INFO_NETWORKERROR]);
                
            }
            
        }
        
    }

}

#pragma mark -  网络请求相关设置
//************************************************
//
//              网络请求相关设置
//
//************************************************

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:19
 *
 *  @brief                  上传文件时的根地址
 *
 *  @param rootURLString    根地址
 *
 *  @since                  1.0.0
 */
+ (void)requestLoadFileRootURL:(NSString *)rootURLString
{

    if ([rootURLString hasPrefix:@"http"]) {
        
        [YSMRequestManager shareRequestManager].uploadFileRootURLString = rootURLString;
        
    } else {
    
        [YSMRequestManager shareRequestManager].uploadFileRootURLString = nil;
    
    }

}

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:58
 *
 *  @brief                  设置网络请求的根地址
 *
 *  @param rootURLString    根地址
 *
 *  @since                  1.0.0
 */
+ (void)requestRootURL:(NSString *)rootURLString
{

    if ([rootURLString hasPrefix:@"http"]) {
        
        [YSMRequestManager shareRequestManager].httpRequestRootURLString = rootURLString;
        
    } else {
        
        [YSMRequestManager shareRequestManager].httpRequestRootURLString = nil;
        
    }

}

#pragma mark -  添加网络请求任务
//************************************************
//
//              添加网络请求任务
//
//************************************************

/**
 *  @author                 yangshengmeng, 15-05-14 18:05:47
 *
 *  @brief                  根据请求数据任务模型，进行数据请求
 *
 *  @param taskModel        请求任务数据模型
 *
 *  @since                  1.0.0
 */
+ (void)requestDataWithRequestTask:(YSMRequestTaskDataModel *)taskModel
{
    
    ///判断当前网络状态
    if (rRequestResultStatusNoNetworking == _currentStatus) {
        
        if (taskModel.requestResultCallBack) {
            
            taskModel.requestResultCallBack(rRequestResultStatusNoNetworking,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusNoNetworking andErrorInfo:LOCAL_ERROR_INFO_NETWORKERROR]);
            
        }
        return;
        
    }

    ///http请求类型判断
    if (rRequestHttpTypeGet > taskModel.httpType ||
        rRequestHttpTypeUPLoadFiles < taskModel.httpType) {
        
        if (taskModel.requestResultCallBack) {
            
            taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusHTTPTypeError andErrorInfo:LOCAL_ERROR_INFO_HTTPTYPE]);
            
        }
        return;
        
    }
    
    ///请求状态过滤
    if (rRequestCurrentStatusDefault > taskModel.requestStatus ||
        rRequestCurrentStatusCancel < taskModel.requestStatus) {
        
        taskModel.requestStatus = rRequestCurrentStatusDefault;
        
    }
    
    ///请求URL判断
    if (![taskModel.requestURLString hasPrefix:@"http"]) {
        
        switch (taskModel.httpType) {
                ///get请求
            case rRequestHttpTypeGet:
                
                ///post请求
            case rRequestHttpTypePost:
            {
                
                ///本地的根地址
                NSString *httpRootString = [YSMRequestManager shareRequestManager].httpRequestRootURLString;
            
                ///判断是否已设置请求根地址
                if ([httpRootString hasPrefix:@"http"]) {
                    
                    ///判断是否存在/分隔符
                    if ([taskModel.requestURLString hasPrefix:@"/"] ||
                        [httpRootString hasSuffix:@"/"]) {
                        
                        taskModel.requestURLString = [httpRootString stringByAppendingString:taskModel.requestURLString];
                        
                    } else {
                    
                        taskModel.requestURLString = [httpRootString stringByAppendingPathComponent:taskModel.requestURLString];
                    
                    }
                    
                } else {
                
                    if (taskModel.requestResultCallBack) {
                        
                        taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusURLError andErrorInfo:LOCAL_ERROR_INFO_URLERROR]);
                        
                    }
                    return;
                
                }
            
            }
                break;
                
                ///上传单文件
            case rRequestHttpTypeUPLoadFile:
                
                ///上传多文件
            case rRequestHttpTypeUPLoadFiles:
            {
            
                ///本地的根地址
                NSString *loadRootString = [YSMRequestManager shareRequestManager].uploadFileRootURLString;
                
                ///判断是否已设置请求根地址
                if ([loadRootString hasPrefix:@"http"]) {
                    
                    ///判断是否存在/分隔符
                    if ([taskModel.requestURLString hasPrefix:@"/"] ||
                        [loadRootString hasSuffix:@"/"]) {
                        
                        taskModel.requestURLString = [loadRootString stringByAppendingString:taskModel.requestURLString];
                        
                    } else {
                        
                        taskModel.requestURLString = [loadRootString stringByAppendingPathComponent:taskModel.requestURLString];
                        
                    }
                    
                } else {
                    
                    if (taskModel.requestResultCallBack) {
                        
                        taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusURLError andErrorInfo:LOCAL_ERROR_INFO_URLERROR]);
                        
                    }
                    return;
                    
                }
            
            }
                break;
                
            default:
                break;
        }
        
    }
    
    ///解析类校验
    if (![NSClassFromString(taskModel.mappingClass) isSubclassOfClass:[YSMMappingBaseDataModel class]]) {
        
        if (taskModel.requestResultCallBack) {
            
            taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusMappingClassError andErrorInfo:LOCAL_ERROR_INFO_MAPPINGCLASSERROR]);
            
        }
        return;
        
    }
    
    ///上传文件时，判断本地是否存在文件
    if (rRequestHttpTypeUPLoadFile == taskModel.httpType) {
        
        if ([taskModel.filePath length] <= 0 ||
            !([[NSFileManager defaultManager] fileExistsAtPath:taskModel.filePath])) {
            
            if (taskModel.requestResultCallBack) {
                
                taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusFileError andErrorInfo:LOCAL_ERROR_INFO_FILEERROR]);
                
            }
            return;
            
        }
        
    }
    
    if (rRequestHttpTypeUPLoadFiles == taskModel.httpType) {
        
        if ([taskModel.filePaths count] <= 0 ||
            !([taskModel.filePaths[0] isKindOfClass:[NSString class]]) ||
            !([[NSFileManager defaultManager] fileExistsAtPath:taskModel.filePaths[0]])) {
            
            if (taskModel.requestResultCallBack) {
                
                taskModel.requestResultCallBack(rRequestResultStatusHTTPTypeError,nil,[self createCustomLocalError:LOCAL_ERROR_DOMAIN andErrorCode:rRequestResultStatusFilesError andErrorInfo:LOCAL_ERROR_INFO_FILEERROR]);
                
            }
            return;
            
        }
        
    }
    
    ///设置时间戳
    NSDate *currentData = [NSDate date];
    taskModel.timeStamp = [currentData timeIntervalSince1970];
    taskModel.requestStatus = rRequestCurrentStatusDefault;
    
    if ([NSThread isMainThread]) {
        
        ///添加请求任务
        [[YSMRequestManager shareRequestManager] addRequestTaskToPool:taskModel];
        
    } else {
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            ///添加请求任务
            [[YSMRequestManager shareRequestManager] addRequestTaskToPool:taskModel];
            
        });
    
    }

}

#pragma mark - 自定义NSError
+ (NSError *)createCustomLocalError:(NSString *)errorDomain andErrorCode:(REQUEST_RESULT_STATUS)errorCode andErrorInfo:(NSString *)errorInfo
{
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorInfo                                                                      forKey:NSLocalizedDescriptionKey];
    NSError *aError = [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo];
    return aError;
    
}

@end
