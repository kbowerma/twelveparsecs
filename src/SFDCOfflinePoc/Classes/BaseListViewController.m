/*
 Copyright (c) 2014, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BaseListViewController.h"
#import "ActionsPopupController.h"
#import "SObjectDataManager.h"
#import "WYPopoverController.h"
#import "TabBarViewController.h"
#import <SalesforceSDKCore/SFDefaultUserManagementViewController.h>
#import <SmartStore/SFSmartStoreInspectorViewController.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFSecurityLockout.h>
#import <SmartSync/SFSmartSyncSyncManager.h>
#import <SmartSync/SFSyncState.h>

static NSUInteger const kSearchHeaderBackgroundColor    = 0xafb6bb;
static CGFloat    const kControlBuffer                  = 5.0;
static CGFloat    const kSearchHeaderHeight             = 50.0;
static CGFloat    const kTableViewRowHeight             = 60.0;
static CGFloat    const kToastMessageFontSize           = 16.0;

@interface BaseListViewController () <UISearchBarDelegate>

@property (nonatomic, strong) WYPopoverController *popOverController;
@property (nonatomic, strong) UIActionSheet *logoutActionSheet;


// View / UI properties
@property (nonatomic, strong) UILabel *navBarLabel;
@property (nonatomic, strong) UIView *searchHeader;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *syncButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, strong) UIBarButtonItem *moreButton;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UILabel *toastViewMessageLabel;
@property (nonatomic, copy) NSString *toastMessage;

@property (nonatomic, assign) BOOL isSearching;

@end

@implementation BaseListViewController

@synthesize dataMgr;
@synthesize contactDataMgr;
@synthesize productDataMgr;
@synthesize sampleRequestDataMgr;

#pragma mark - init/setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.isSearching = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isSearching = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearPopovers:)
                                                 name:kSFPasscodeFlowWillBegin
                                               object:nil];
}

- (void)loadView {
    [super loadView];

    [self addTapGestureRecognizers];
    
    // Search header
    self.searchHeader = [[UIView alloc] initWithFrame:CGRectZero];
    self.searchHeader.backgroundColor = [[self class] colorFromRgbHexValue:kSearchHeaderBackgroundColor];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.barTintColor = [[self class] colorFromRgbHexValue:kSearchHeaderBackgroundColor];
    self.searchBar.placeholder = @"Search";
    self.searchBar.delegate = self;
    [self.searchHeader addSubview:self.searchBar];
    
    // Toast view
    self.toastView = [[UIView alloc] initWithFrame:CGRectZero];
    self.toastView.backgroundColor = [UIColor colorWithRed:(38.0 / 255.0) green:(38.0 / 255.0) blue:(38.0 / 255.0) alpha:0.7];
    self.toastView.layer.cornerRadius = 10.0;
    self.toastView.alpha = 0.0;
    
    self.toastViewMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.toastViewMessageLabel.font = [UIFont systemFontOfSize:kToastMessageFontSize];
    self.toastViewMessageLabel.textColor = [UIColor whiteColor];
    [self.toastView addSubview:self.toastViewMessageLabel];
    [self.view addSubview:self.toastView];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Navigation bar buttons
    self.addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    self.syncButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sync"] style:UIBarButtonItemStylePlain target:self action:@selector(syncUpDown)];
    self.moreButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showOtherActions)];
    self.navigationItem.rightBarButtonItems = @[ self.moreButton, self.syncButton, self.addButton ];
    for (UIBarButtonItem *bbi in self.navigationItem.rightBarButtonItems) {
        bbi.tintColor = [UIColor whiteColor];
    }

}

- (void)viewWillLayoutSubviews {
    CGRect navBarFrame = self.navigationController.navigationBar.frame;
    UIImage *rightButtonImage = self.navigationItem.rightBarButtonItem.image;
    CGRect navBarLabelFrame = CGRectMake(0,
                                         0,
                                         navBarFrame.size.width - rightButtonImage.size.width,
                                         navBarFrame.size.height);
    self.navBarLabel.frame = navBarLabelFrame;
    [self layoutSearchHeader];
    
    [self layoutToastView];
}

#pragma mark - UITableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataMgr.dataRows count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0) return nil;
    
    [self layoutSearchHeader];
    
    return self.searchHeader;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return kSearchHeaderHeight;
    else
        return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTableViewRowHeight;
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self log:SFLogLevelDebug format:@"searching with text: %@", searchText];
    __weak BaseListViewController *weakSelf = self;
    [self.dataMgr filterOnSearchTerm:searchText completion:^{
        [weakSelf.tableView reloadData];
        if (weakSelf.isSearching && ![weakSelf.searchBar isFirstResponder]) {
            [weakSelf.searchBar becomeFirstResponder];
        }
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.isSearching = YES;
}

#pragma mark - Public methods

+ (UIColor *)colorFromRgbHexValue:(NSUInteger)rgbHexColorValue {
    return [UIColor colorWithRed:((CGFloat)((rgbHexColorValue & 0xFF0000) >> 16)) / 255.0
                           green:((CGFloat)((rgbHexColorValue & 0xFF00) >> 8)) / 255.0
                            blue:((CGFloat)(rgbHexColorValue & 0xFF)) / 255.0
                           alpha:1.0];
}

- (NSString *)formatTitle:(NSString *)title {
    title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (title != nil ? title : @"");
}

- (UIView *)accessoryViewForContact:(SObjectData *)contact {
    static UIImage *sLocalAddImage = nil;
    static UIImage *sLocalUpdateImage = nil;
    static UIImage *sLocalDeleteImage = nil;
    static UIImage *sChevronRightImage = nil;

    if (sLocalAddImage == nil) {
        sLocalAddImage = [UIImage imageNamed:@"local-add"];
    }
    if (sLocalUpdateImage == nil) {
        sLocalUpdateImage = [UIImage imageNamed:@"local-update"];
    }
    if (sLocalDeleteImage == nil) {
        sLocalDeleteImage = [UIImage imageNamed:@"local-delete"];
    }
    if (sChevronRightImage == nil) {
        sChevronRightImage = [UIImage imageNamed:@"chevron-right"];
    }

    if ([self.dataMgr dataHasLocalChanges:contact]) {
        UIImage *localImage;
        if ([self.dataMgr dataLocallyCreated:contact])
            localImage = sLocalAddImage;
        else if ([self.dataMgr dataLocallyUpdated:contact])
            localImage = sLocalUpdateImage;
        else
            localImage = sLocalDeleteImage;

        //
        // Uber view
        //
        CGFloat accessoryViewWidth = localImage.size.width + kControlBuffer + sChevronRightImage.size.width;
        CGRect accessoryViewRect = CGRectMake(0, 0, accessoryViewWidth, self.tableView.rowHeight);
        UIView *accessoryView = [[UIView alloc] initWithFrame:accessoryViewRect];
        //
        // "local" view
        //
        CGRect localImageViewRect = CGRectMake(0,
                                               CGRectGetMidY(accessoryView.bounds) - (localImage.size.height / 2.0),
                                               localImage.size.width,
                                               localImage.size.height);
        UIImageView *localImageView = [[UIImageView alloc] initWithFrame:localImageViewRect];
        localImageView.image = localImage;
        [accessoryView addSubview:localImageView];
        //
        // spacer view
        //
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(localImageView.frame.size.width, 0, kControlBuffer, self.tableView.rowHeight)];
        [accessoryView addSubview:spacerView];
        //
        // chevron view
        //
        CGRect chevronViewRect = CGRectMake(localImageView.frame.size.width + spacerView.frame.size.width,
                                            CGRectGetMidY(accessoryView.bounds) - (sChevronRightImage.size.height / 2.0),
                                            sChevronRightImage.size.width,
                                            sChevronRightImage.size.height);
        UIImageView *chevronView = [[UIImageView alloc] initWithFrame:chevronViewRect];
        chevronView.image = sChevronRightImage;
        [accessoryView addSubview:chevronView];

        return accessoryView;
    } else {
        //
        // Uber view
        //
        CGRect accessoryViewRect = CGRectMake(0, 0, sChevronRightImage.size.width, self.tableView.rowHeight);
        UIView *accessoryView = [[UIView alloc] initWithFrame:accessoryViewRect];
        //
        // chevron view
        //
        CGRect chevronViewRect = CGRectMake(0,
                                            CGRectGetMidY(accessoryView.bounds) - (sChevronRightImage.size.height / 2.0),
                                            sChevronRightImage.size.width,
                                            sChevronRightImage.size.height);
        UIImageView *chevronView = [[UIImageView alloc] initWithFrame:chevronViewRect];
        chevronView.image = sChevronRightImage;
        [accessoryView addSubview:chevronView];

        return accessoryView;
    }
}

- (void)add {
    // override
}

- (void)syncUpDown {
    [self showToast:@"Syncing with Salesforce"];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    __weak BaseListViewController *weakSelf = self;
    [self.dataMgr updateRemoteData:^(SFSyncState *syncProgressDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
            if ([syncProgressDetails isDone]) {
                [weakSelf.dataMgr refreshLocalData];
                [weakSelf showToast:@"Sync complete!"];
                [weakSelf.dataMgr refreshRemoteData];
            } else if ([syncProgressDetails hasFailed]) {
                [weakSelf showToast:@"Sync failed."];
            } else {
                [weakSelf showToast:[NSString stringWithFormat:@"Unexpected status: %@", [SFSyncState syncStatusToString:syncProgressDetails.status]]];
            }
        });
    }];
}

- (void)showOtherActions {
    if([self.popOverController isPopoverVisible]){
        [self.popOverController dismissPopoverAnimated:YES];
        return;
    }
    
    ActionsPopupController *popoverContent = [[ActionsPopupController alloc] initWithAppViewController:self];
    popoverContent.preferredContentSize = CGSizeMake(260,130);
    self.popOverController = [[WYPopoverController alloc] initWithContentViewController:popoverContent];
    
    
    [self.popOverController presentPopoverFromBarButtonItem:self.moreButton
                                   permittedArrowDirections:WYPopoverArrowDirectionAny
                                                   animated:YES];
}

- (void)reloadData {
    [self.tableView reloadData];
}

#pragma mark - Private methods

- (void)addTapGestureRecognizers {
    UITapGestureRecognizer* navBarTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(searchResignFirstResponder)];
    navBarTapGesture.cancelsTouchesInView = NO;
    [self.navigationController.navigationBar addGestureRecognizer:navBarTapGesture];
    
    UITapGestureRecognizer* tableViewTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(searchResignFirstResponder)];
    tableViewTapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tableViewTapGesture];
}

- (void)popoverOptionSelected:(NSString *)text {
    [self.popOverController dismissPopoverAnimated:YES];
    
    if ([text isEqualToString:kActionLogout]) {
        self.logoutActionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to log out?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Confirm Logout"
                                                    otherButtonTitles:nil];
        [self.logoutActionSheet showFromBarButtonItem:self.moreButton animated:YES];
        return;
    } else if ([text isEqualToString:kActionSwitchUser]) {
        SFDefaultUserManagementViewController *umvc = [[SFDefaultUserManagementViewController alloc] initWithCompletionBlock:^(SFUserManagementAction action) {
            [self dismissViewControllerAnimated:YES completion:NULL];
        }];
        [self presentViewController:umvc animated:YES completion:NULL];
    } else if ([text isEqualToString:kActionDbInspector]) {
        [[[SFSmartStoreInspectorViewController alloc] initWithStore:self.dataMgr.store] present:self];
    } else if ([text isEqualToString:kActionChangePin]) {
        [(TabBarViewController*)self.tabBarController configurePin];
    }
}


- (void)layoutToastView {
    CGFloat toastWidth = 250.0;
    CGFloat toastHeight = 50.0;
    CGFloat bottomScreenPadding = 60.0;
    
    self.toastView.frame = CGRectMake(CGRectGetMidX([self.toastView superview].bounds) - (toastWidth / 2.0),
                                      CGRectGetMaxY([self.toastView superview].bounds) - bottomScreenPadding - toastHeight,
                                      toastWidth,
                                      toastHeight);
    
    //
    // messageLabel
    //
    NSDictionary *messageAttrs = @{ NSForegroundColorAttributeName: self.toastViewMessageLabel.textColor, NSFontAttributeName: self.toastViewMessageLabel.font };
    if (self.toastMessage == nil) {
        self.toastMessage = @" ";
    }
    CGSize messageTextSize = [self.toastMessage sizeWithAttributes:messageAttrs];
    CGRect messageRect = CGRectMake(CGRectGetMidX(self.toastView.bounds) - (messageTextSize.width / 2.0),
                                    CGRectGetMidY(self.toastView.bounds) - (messageTextSize.height / 2.0),
                                    messageTextSize.width, messageTextSize.height);
    self.toastViewMessageLabel.frame = messageRect;
    self.toastViewMessageLabel.text = self.toastMessage;
}

- (void)showToast:(NSString *)message {
    NSTimeInterval const toastDisplayTimeSecs = 2.0;
    
    self.toastMessage = message;
    [self layoutToastView];
    self.toastView.alpha = 0.0;
    [UIView beginAnimations:@"toastFadeIn" context:NULL];
    [UIView setAnimationDuration:0.3];
    self.toastView.alpha = 1.0;
    [UIView commitAnimations];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, toastDisplayTimeSecs * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [UIView beginAnimations:@"toastFadeOut" context:NULL];
        [UIView setAnimationDuration:0.3];
        self.toastView.alpha = 0.0;
        [UIView commitAnimations];
    });
}

- (void)searchResignFirstResponder {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
        self.isSearching = NO;
    }
}

- (void)layoutSearchHeader {
    
    //
    // searchHeader
    //
    CGRect searchHeaderFrame = CGRectMake(0, 0, self.navigationController.navigationBar.frame.size.width, kSearchHeaderHeight);
    self.searchHeader.frame = searchHeaderFrame;
    
    //
    // searchBar
    //
    CGRect searchBarFrame = CGRectMake(0,
                                       0,
                                       self.searchHeader.frame.size.width,
                                       self.searchHeader.frame.size.height);
    self.searchBar.frame = searchBarFrame;
}

#pragma mark - Passcode handling

- (void)clearPopovers:(NSNotification *)note
{
    [self log:SFLogLevelDebug msg:@"Passcode screen loading.  Clearing popovers."];
    if (self.popOverController) {
        [self.popOverController dismissPopoverAnimated:NO];
    }
    if (self.logoutActionSheet) {
        [self.logoutActionSheet dismissWithClickedButtonIndex:-100 animated:NO];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([actionSheet isEqual:self.logoutActionSheet]) {
        self.logoutActionSheet = nil;
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [[SFAuthenticationManager sharedManager] logout];
        }
    }
}

#pragma mark - offline/online

- (void)showOffline {
    self.syncButton.image = [UIImage imageNamed:@"no-internet"];
    self.syncButton.enabled = NO;
}

- (void)showOnline {
    self.syncButton.image = [UIImage imageNamed:@"sync"];
    self.syncButton.enabled = YES;
    [self syncUpDown];
}


@end
