//
//  ViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 smile.zhang. All rights reserved.
//

#import "ViewController.h"
#import "TerminalModel.h"
#import "MJRefresh.h"
#import "AddViewController.h"
#import "ControlViewController.h"
#import "ESPUDPSocketServer.h"

static NSString *kCellIdentify = @"cell";

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,AddTerminalDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *datasource;
@property (nonatomic, strong) NSMutableArray *dataname;

@property (atomic,assign) BOOL stop;
@property (nonatomic,strong) ESPUDPSocketServer *DiscoveryServer;
@property (nonatomic, retain) NSTimer *aTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"设备列表";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    [self tableView];
    self.stop = true;
    if (self.DiscoveryServer == nil) {
        NSLog(@"Discovery server is created");
        self.DiscoveryServer = [[ESPUDPSocketServer alloc]initWithPort:6666 AndSocketTimeout:15000];
       [self createUDPdiscoveryTask];
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private
- (void)add {
    AddViewController *addController = [[AddViewController alloc] initWithNibName:@"AddViewController" bundle:nil];
    addController.delegate = self;
    [self.navigationController pushViewController:addController animated:YES];
}

- (void)refresh {
    // 这里是下拉刷新执行的方法，可以做一些事情
    [self.tableView reloadData];
    NSLog(@"Drag to refresh");
    
    if([self.aTimer isValid]) {
        [self.aTimer invalidate], self.aTimer = nil;
    }
    self.stop = false;
    
    self.aTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(runScheduledTask) userInfo:nil repeats:NO];
    // 记得刷新完成后结束刷新的UI哦，需要完成任务后手动调用哦
    [self.tableView.mj_header endRefreshing];
}

- (void)runScheduledTask{
    self.stop = true;
    self.aTimer = nil;
}

#pragma mark - AddTermainalDelegate
- (void)addTermainal:(TerminalModel *)terminal {
    if (terminal && [terminal isKindOfClass:[TerminalModel class]]) {
        
        [self.datasource addObject:terminal];
        [self.tableView reloadData];
    }
}
//用于判断是否已经包含
- (BOOL) isIncludedByDatasource:(TerminalModel *)terminal{
    //遍历比较，相等的话直接返回
    for (int i=0;i<[self.datasource count];i++)
    {
        TerminalModel *term = (TerminalModel *)[self.datasource objectAtIndex:i];
        if([term.name isEqualToString:terminal.name])
            return true;
    }
      return false;
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentify];
    }
    TerminalModel *terminal = (TerminalModel *)[self.datasource objectAtIndex:indexPath.row];
    cell.textLabel.text = terminal.name;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //离开之前停掉udp服务
    self.stop = true;
    [self.DiscoveryServer interrupt];
    
    TerminalModel *terminal = (TerminalModel *)[self.datasource objectAtIndex:indexPath.row];
    ControlViewController *controller = [[ControlViewController alloc] initWithNibName:@"ControlViewController" bundle:nil terminal:terminal];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - Getter
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [self.view addSubview:_tableView];
        _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
        _tableView.rowHeight = 44;
    }
    return _tableView;
}

- (NSMutableArray *)datasource {
    if (!_datasource) {
        _datasource = @[].mutableCopy;
#warning 下面一行为测试代码哦
        [_datasource addObject:[[TerminalModel alloc] init]];
    }
    return _datasource;
}

- (void) createUDPdiscoveryTask {
    NSLog(@"Start UDP discoveryTask");
    dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSTimeInterval startTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *receiveData = nil;
        while(true){
        if(!self.stop)
        {
            receiveData = [self.DiscoveryServer recvfromClient];//1+6+4 resultlen+ maclen+iplen
            NSLog(@"receive:%@", receiveData);
            //receive:<5ccf7f21 e8af>+192.168.9.111
            TerminalModel *terminal = [[TerminalModel alloc] init];
            // 给模型赋值
            NSString *symbol = @">+";
            NSRange iStart = [receiveData rangeOfString: symbol options:NSCaseInsensitiveSearch];
         
            terminal.ip = [receiveData  substringFromIndex:iStart.location + 2]; ;
            terminal.name = [receiveData  substringToIndex:iStart.location + 1];
            NSLog(@"IP=%@", terminal.ip);
            NSLog(@"NAME=%@", terminal.name);
            if(![self isIncludedByDatasource:terminal]
               && terminal.ip != nil){
                NSLog(@"need to add");
                [self addTermainal:terminal];
            } else {
                NSLog(@"Whether need to release....need to check");
            }
            //terminal.ssid = @"SDKJSUIJKLJSDGXVKJLDSFJLKJGKLSDGKL";
            //terminal.isOn = NO;
            // 模型回传，直接传至上一个界面
            // if (self.delegate) {
            //    [self.delegate addTermainal:terminal];
            //}

        }
        }
    });
}

@end
