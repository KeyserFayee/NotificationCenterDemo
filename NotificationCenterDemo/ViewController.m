//
//  ViewController.m
//  NotificationCenterDemo
//
//  Created by keyser_soz on 2020/3/2.
//  Copyright © 2020 keyser_soz. All rights reserved.
//
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSObject *obj = [NSObject new];
    [KSNotificationCenter.defaultCenter addObserver:self selector:@selector(respondsToNotice:) name:@"test0" object:obj];
    
    [KSNotificationCenter.defaultCenter postNotificationName:@"test0" object:obj userInfo:@{@"key":@"value"}];

}

- (void)respondsToNotice:(KSNotification *)noti {
    id obj = noti.object;
    NSDictionary *dic = noti.userInfo;
    NSLog(@"\n- self:%@ \n- obj:%@ \n- notificationInfo:%@", self, obj, dic);
}


@end
