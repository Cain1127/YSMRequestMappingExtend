# YSMRequestMappingExtend

[![CI Status](http://img.shields.io/travis/ysmeng/YSMRequestMappingExtend.svg?style=flat)](https://travis-ci.org/ysmeng/YSMRequestMappingExtend)
[![Version](https://img.shields.io/cocoapods/v/YSMRequestMappingExtend.svg?style=flat)](http://cocoapods.org/pods/YSMRequestMappingExtend)
[![License](https://img.shields.io/cocoapods/l/YSMRequestMappingExtend.svg?style=flat)](http://cocoapods.org/pods/YSMRequestMappingExtend)
[![Platform](https://img.shields.io/cocoapods/p/YSMRequestMappingExtend.svg?style=flat)](http://cocoapods.org/pods/YSMRequestMappingExtend)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.
pod 'YSMRequestMappingExtend', '~> 0.1.0'

## Requirements
iOS 7.1

## Installation

YSMRequestMappingExtend is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

## How to use.
1、custom data model : YSMRequestCustomDataModel, it's subClass of YSMMappingBaseDataModel.

2、add property for custom data model by macro define on YSMMappingBaseDataModel.h file.

3、property name is server json value name.
    ep:{type : 1;
            info : "hello worlk";
        }
        YSMProperty_Base(BOOL,type);
        YSMProperty_String(info);
    using : customDataModel.type

4、import "YSMRequestManager.h"

5、add request task
self.listView.dataSource = self;
self.listView.delegate = self;
YSMRequestTaskDataModel *requestTask = [[YSMRequestTaskDataModel alloc] init];
requestTask.target = self;
requestTask.httpType = rRequestHttpTypeGet;
requestTask.requestURLString = @"http://c.m.163.com/nc/article/list/T1348648517839/0-20.html";
requestTask.mappingClass = @"YSMRequestCustomDataModel";
requestTask.requestParams = nil;
requestTask.requestResultCallBack = ^(REQUEST_RESULT_STATUS resultStatus,id<QSDataMappingProtocol> resultData,NSError *error){

if (rRequestResultStatusSuccess == resultStatus) {

self.dataSource = resultData;
[self.listView reloadData];

} else {

NSLog(@"request fail:%@",error);

}

};

6、start request data
[YSMRequestManager requestDataWithRequestTask:requestTask];


```ruby
pod "YSMRequestMappingExtend"
```

## Author

ysmeng, 49427823@163.com

## License

YSMRequestMappingExtend is available under the MIT license. See the LICENSE file for more info.
