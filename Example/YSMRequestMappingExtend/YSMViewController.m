//
//  YSMViewController.m
//  YSMRequestMappingExtend
//
//  Created by ysmeng on 05/17/2015.
//  Copyright (c) 2014 ysmeng. All rights reserved.
//

#import "YSMViewController.h"

#import "YSMRequestManager.h"
#import "YSMRequestCustomDataModel.h"

@interface YSMViewController () <UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *listView;

@property (nonatomic,retain) YSMRequestCustomDataModel *dataSource;

@end

@implementation YSMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    ///1、custom data model : YSMRequestCustomDataModel, it's subClass of YSMMappingBaseDataModel.
    
    ///2、add property for custom data model by macro define on YSMMappingBaseDataModel.h file.
    
    ///3、property name is server json value name.
    /// ep:{type : 1;
    ///     info : "hello worlk";
    ///     }
    ///     YSMProperty_Base(BOOL,type);
    ///     YSMProperty_String(info);
    /// using : customDataModel.type
    
    ///4、import "YSMRequestManager.h"
    
    ///5、add request task
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
    
    ///6、start request data
    [YSMRequestManager requestDataWithRequestTask:requestTask];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [self.dataSource.T1348648517839 count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *confCellName = @"confCellName";
    UITableViewCell *cellNormal = [tableView dequeueReusableCellWithIdentifier:confCellName];
    if (nil == cellNormal) {
        
        cellNormal = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:confCellName];
        
    }
    
    ///show request info
    YSMNewsDataModel *datamodel = self.dataSource.T1348648517839[indexPath.row];
    cellNormal.textLabel.text = datamodel.title;
    cellNormal.detailTextLabel.text = datamodel.digest;
    
    return cellNormal;
    
}

@end
