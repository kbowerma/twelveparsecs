//
//  TabBarViewController.m
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/23/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "TabBarViewController.h"
#import "Reachability.h"

static Reachability* reach;
static NSString* reachHostName = @"login.salesforce.com";
static NSString* pin = @"012016";

@implementation TabBarViewController {
    UIView *pinView;
    UIAlertController *alertView;
    BOOL noConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    pinView = [[UIView alloc] initWithFrame:self.view.bounds];
    pinView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    pinView.userInteractionEnabled = NO;

    noConnection = NO;

    // Allocate a reachability object
    reach = [Reachability reachabilityWithHostname:reachHostName];

    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA
    reach.reachableOnWWAN = YES;

    // Reachable
    reach.reachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            noConnection = NO;
            [pinView removeFromSuperview];
            if (alertView) {
                [alertView dismissViewControllerAnimated:YES completion:nil];
            }
        });
    };

    // Unreachable
    reach.unreachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            noConnection = YES;
            [self.view addSubview:pinView];
            [self showAlert];
        });
    };

    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];

    if (![reach isReachable]) {
        [self showAlert];
    }
}

#pragma mark - private methods

- (void)showAlert {
    if (noConnection) {
        alertView = [UIAlertController alertControllerWithTitle:@"No connection" message:@"Enter ping"
                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter pin";
            textField.secureTextEntry = YES;
        }];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Pin" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *pinTextField = alertView.textFields.firstObject;
            if ([pinTextField.text isEqual:pin] && !noConnection) {
                [alertView dismissViewControllerAnimated:YES completion:^{
                    alertView = nil;
                }];
            }
        }];

        [alertView addAction:action];

        [self presentViewController:alertView animated:YES completion:nil];
    }
}

@end
