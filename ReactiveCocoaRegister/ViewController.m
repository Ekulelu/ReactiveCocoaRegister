//
//  ViewController.m
//  ReactiveCocoaTest
//
//  Created by aahu on 16/11/25.
//  Copyright © 2016年 ekulelu. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"
#import "RACmetamacros.h"
typedef NS_ENUM(int, AccountStatus) {
    AccountStatusAvailable = 0,
    AccountStatusChecking = 1,
    AccountStatusUnavailable = 2,
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *accountTV;
@property (weak, nonatomic) IBOutlet UITextField *passwordTV;
@property (weak, nonatomic) IBOutlet UIButton *registerBtn;
@property (weak, nonatomic) IBOutlet UIImageView *accountAvailableImgView;
@property (strong, nonatomic) NSString *account;
@property (strong, nonatomic) NSString *password;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.registerBtn.enabled = NO;
    @weakify(self)
    RACSignal *accountValidSignal = [self.accountTV.rac_textSignal map:^id(id value) {
        @strongify(self)
        return @(self.accountTV.text.length > 5);
    }];
    
    RACSignal *passwordVaildSignal = [self.passwordTV.rac_textSignal map:^id(id value) {
        @strongify(self)
        return @(self.passwordTV.text.length >5);
    }];
    
    RAC(self.accountTV, backgroundColor) = [accountValidSignal map:^id(NSNumber *accountVaild) {
        return accountVaild.boolValue ? [UIColor whiteColor] : [UIColor redColor];
    }];
    
    RAC(self.passwordTV, backgroundColor) = [passwordVaildSignal map:^id(NSNumber *passwordVaild) {
        return passwordVaild.boolValue ? [UIColor whiteColor] : [UIColor redColor];
    }];
    
    
    
    [[[self.registerBtn rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^RACStream *(id value) {
        @strongify(self)
        return [self registerSignal];
    }] subscribeNext:^(NSNumber *success) {
        if (success.boolValue) {
            NSLog(@"register!");
        }
    }];
    
    RAC(self.accountAvailableImgView, hidden) = [accountValidSignal map:^id(NSNumber *value) {
        return @(!value.boolValue);
    }];
    
    RACSubject *isAccountAvailableSubject = [RACSubject subject];
    
    
    [[[accountValidSignal sample:[self.accountTV.rac_textSignal distinctUntilChanged]] //如果不加distinctUntilChanged，那么焦点离开也会调用
      filter:^BOOL(NSNumber *value) {
         return value.boolValue;
    }]
    subscribeNext:^(id x) {
        @strongify(self)
        [isAccountAvailableSubject sendNext:@(AccountStatusChecking)];
        [self checkAccount:self.accountTV.text complete:^(Boolean success) {
            if (success) {
                [isAccountAvailableSubject sendNext:@(AccountStatusAvailable)];
                NSLog(@"can use accout");
            } else {
                [isAccountAvailableSubject sendNext:@(AccountStatusUnavailable)];
                NSLog(@"can not use accout");
            }
        }];
    }];

    

    
    RAC(self.registerBtn, enabled) = [RACSignal combineLatest:@[isAccountAvailableSubject, accountValidSignal,passwordVaildSignal]
                      reduce:^id(NSNumber *accountUse, NSNumber* accountValid, NSNumber* passwordVaild){
                          return @(accountUse.intValue == AccountStatusAvailable && accountValid.boolValue && passwordVaild.boolValue);
    }];
    
    RAC(self.accountAvailableImgView, backgroundColor) = [isAccountAvailableSubject
     map:^id(NSNumber *value) {
         switch (value.intValue) {
             case AccountStatusAvailable:
                 return [UIColor greenColor];
                 break;
             case AccountStatusChecking:
                 return [UIColor blueColor];
                 break;
             case AccountStatusUnavailable:
             default:
                 return [UIColor yellowColor];
                 break;
         }
     }];
    
}


//有个问题，连续输入的时候，第一个请求没有销毁，第二个请求又发送了，然后立马回来第一个请求的结果。
- (void)checkAccount:(NSString*)account complete:(void(^)(Boolean success))complete{
    NSParameterAssert(complete != nil);
    @weakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self)
        if ([self.accountTV.text isEqualToString:@"aahuang"]) {
            complete(NO);
        } else {
            complete(YES);
        }
    });
}

- (RACSignal*)registerSignal{
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self)
        [self registerAccount:self.accountTV.text password:self.passwordTV.text complete:^(Boolean success) {
            if (success) {
                [subscriber sendNext:@(YES)];
            } else {
                [subscriber sendNext:@(NO)];
            }
            [subscriber sendCompleted];
        }];
        
        return nil;
    }];
}

- (void)registerAccount:(NSString*)account password:(NSString*)password complete:(void(^)(Boolean success))complete{
    NSParameterAssert(complete != nil);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        complete(YES);
        
    });
}


- (void)dealloc{
    NSLog(@"ViewController dealloc");
}
@end
