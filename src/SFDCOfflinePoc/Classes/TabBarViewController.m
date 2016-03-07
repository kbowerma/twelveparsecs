//
//  TabBarViewController.m
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/23/16.
//  Updated by TCCODER on 2/22/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "TabBarViewController.h"
#import "Reachability.h"
#import "BaseListViewController.h"
#import "Configurations.h"

static Reachability* reach;
static NSString* reachHostName = @"login.salesforce.com";

@interface TabBarViewController ()

/**
 *  current pin
 */
@property (nonatomic, strong) NSString* pin;

/**
 *  failed attempts
 */
@property (nonatomic, assign) NSInteger attempts;

@end

@implementation TabBarViewController {
    UIView *dimView;
    UIAlertController *alertView;
    BOOL noConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    dimView.userInteractionEnabled = NO;

    noConnection = NO;

    // Allocate a reachability object
    reach = [Reachability reachabilityWithHostname:reachHostName];

    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA
    reach.reachableOnWWAN = YES;

    // Reachable
    reach.reachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (noConnection) {
                noConnection = NO;
                for (UINavigationController* navc in self.viewControllers) {
                    BaseListViewController* vc = navc.viewControllers[0];
                    [vc showOnline];
                }
                
                if (alertView) {
                    [alertView dismissViewControllerAnimated:YES completion:nil];
                    alertView = nil;
                }
                if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    [dimView removeFromSuperview];
                }
            }
        });
    };

    // Unreachable
    reach.unreachableBlock = ^(Reachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!noConnection) {
                noConnection = YES;
                for (UINavigationController* navc in self.viewControllers) {
                    BaseListViewController* vc = navc.viewControllers[0];
                    [vc showOffline];
                }
                self.attempts = 0;
                [self showAlert];
            }
        });
    };

    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];

    if (![reach isReachable]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            noConnection = YES;
            for (UINavigationController* navc in self.viewControllers) {
                BaseListViewController* vc = navc.viewControllers[0];
                [vc showOffline];
            }
            [self showAlert];
        });
    }
}

#pragma mark - private methods

/**
 *  shows pin check alert
 */
- (void)showAlert {
    if (!alertView) {
        alertView = [UIAlertController alertControllerWithTitle:@"No connection" message:@"Enter pin"
                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alertView addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Enter pin";
            textField.secureTextEntry = YES;
        }];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Pin" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UITextField *pinTextField = alertView.textFields.firstObject;
            alertView = nil;
            if ((self.pin && ![pinTextField.text isEqual:self.pin]) || (!self.pin && pinTextField.text.length)) {
                ++self.attempts;
                if (self.attempts < [Configurations maxAttempts])
                    [self showAlert];
                else
                {
                    // block interactions
                    [self.view addSubview:dimView];
                    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                }
            }
        }];

        [alertView addAction:action];

        [self presentViewController:alertView animated:YES completion:nil];
    }
}

/**
 *  starts pin configuration
 */
- (void)configurePin {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No connection" message:@"Enter pin"
                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Old pin";
        textField.secureTextEntry = YES;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Enter pin";
        textField.secureTextEntry = YES;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Confirm pin";
        textField.secureTextEntry = YES;
    }];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *oldPinTextField = alert.textFields[0];
        UITextField *pinTextField = alert.textFields[1];
        UITextField *confirmPinTextField = alert.textFields[2];
        if ((self.pin && ![oldPinTextField.text isEqual:self.pin]) || (!self.pin && oldPinTextField.text.length)) {
            [self showAlert:@"Error" message:@"Wrong pin" completion:^{
                [self configurePin];
            }];
        } else if (![pinTextField.text isEqual:confirmPinTextField.text]) {
            [self showAlert:@"Error" message:@"Pins do not match" completion:^{
                [self configurePin];
            }];
        } else
        { // all good
            self.pin = pinTextField.text;
        }
            
    }];
    
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 *  shows alert with title & message
 *
 *  @param title      title
 *  @param message    message
 *  @param completion completion handler
 */
- (void)showAlert:(NSString*)title message:(NSString*)message completion:(void (^)())completion {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (completion)
            completion();
    }];
    
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setPin:(NSString *)pin {
    [[NSUserDefaults standardUserDefaults] setObject:pin forKey:@"USER_PIN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)pin {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"USER_PIN"];
}

@end
