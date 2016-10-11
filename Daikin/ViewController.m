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

static NSString *kCellIdentify = @"cell";

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,AddTerminalDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *datasource;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"设备列表";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    [self tableView];
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

    // 记得刷新完成后结束刷新的UI哦，需要完成任务后手动调用哦
    [self.tableView.mj_header endRefreshing];
}

#pragma mark - AddTermainalDelegate
- (void)addTermainal:(TerminalModel *)terminal {
    if (terminal && [terminal isKindOfClass:[TerminalModel class]]) {
        [self.datasource addObject:terminal];
        [self.tableView reloadData];
    }
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
    }
    return _datasource;
}


@end
