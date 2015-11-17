//
//  HomePageViewController.m
//  DaZhonDemo
//
//  Created by doubleJJ on 15/11/4.
//  Copyright © 2015年 qingdaonews. All rights reserved.
//

#import "HomePageViewController.h"
#import "HomePageHeaderView.h"
#import "DianpingApi.h"
#import "BusinessTableViewCell.h"
#import "BusinessViewController.h"
#import "WebViewController.h"
#import <MBProgressHUD.h>
#import "MJRefresh.h"
@interface HomePageViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic)NSMutableArray *businesses;
@property (nonatomic,strong) NSMutableDictionary *params;
@property (nonatomic) int currentPage;
@property (weak, nonatomic) IBOutlet UILabel *cityNameLabel;
@property (nonatomic,strong) MBProgressHUD* hud;

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置导航栏和headerView
    self.navigationController.navigationBar.barTintColor = TOPIC_COLOR_ORANGE;
    HomePageHeaderView *headerView = [[HomePageHeaderView alloc]init];
    self.tableView.tableHeaderView = headerView;
    //下拉刷新
    [self getCurrentData];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        //进入刷新状态后会自动调用这个block
        [self getCurrentData];
    }];
    //添加监听，用户点击headView时响应
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(clickCategory:) name:@"clickCategory" object:nil];
}

- (void)clickCategory:(NSNotification*)notification{
    NSString *category = [notification.userInfo objectForKey:@"category"];
    [self performSegueWithIdentifier:@"businessvc" sender:category];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *cityName = [ud objectForKey:@"cityName"];
    if (cityName == nil) {
        cityName = @"北京";
        [ud setObject:cityName forKey:@"cityName"];
        [ud synchronize];
    }
    self.cityNameLabel.text = cityName;
}

- (void)getCurrentData{
    //设置请求参数
    self.params = [NSMutableDictionary dictionary];
    self.currentPage = 1;
    [self.params setObject:@(self.currentPage) forKey:@"page"];
    [self.params setObject:@(20) forKey:@"limit"];
    //初始化指示器
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeText;
    self.hud.labelText = @"正在加载....";
    self.hud.labelFont = [UIFont fontWithName:@"Arial" size:13];
    //发送请求
    [DianpingApi requestBusinessWithParams:self.params AndCallback:^(id obj) {
        self.businesses = obj;
        [self.tableView reloadData];
        if (self.businesses == nil) {
            self.hud.labelText = @"加载失败";
            [self.hud hide:YES afterDelay:1];
            [self.tableView.mj_header endRefreshing];
        }else{
            self.hud.labelText = @"加载成功";
            [self.hud hide:YES afterDelay:1];
            [self.tableView.mj_header endRefreshing];
        }
    }];
}

#pragma mark - TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.businesses.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BusinessTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BusinessTableViewCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle]loadNibNamed:@"BusinessTableViewCell" owner:self options:nil]firstObject];
    }
    BusinessInfo *business = self.businesses[indexPath.row];
    cell.business = business;
    //
    if (self.businesses.count - 1 == indexPath.row) {
        [self.params setObject:@(++self.currentPage) forKey:@"page"];
        [DianpingApi requestBusinessWithParams:self.params AndCallback:^(id obj) {
            [self.businesses addObjectsFromArray:obj];
            [self.tableView reloadData];
        }];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 90;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *titie =  @"猜你喜欢";
    return titie;
}

#pragma tableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BusinessInfo *business = self.businesses[indexPath.row];
    WebViewController *webVC = [[WebViewController alloc]init];
    webVC.urlString = business.business_url;
    //跳转的
    webVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webVC animated:YES];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"businessvc"]) {
        BusinessViewController *businessVC = segue.destinationViewController;
        businessVC.category = sender;
    }
}


@end
