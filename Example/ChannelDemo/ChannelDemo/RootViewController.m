//
//  RootViewController.m
//  ChannelDemo
//
//  Created by Justin Schneck on 8/17/15.
//  Copyright (c) 2015 PhoenixFramework. All rights reserved.
//

#import "RootViewController.h"
#import <PhoenixClient/PhoenixClient.h>

@interface RootViewController ()

@property (nonatomic, retain) PhxSocket *socket;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.socket = [[PhxSocket alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:4000/socket/websocket"] params:@{@"this":@"that"} heartbeatInterval:20];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
