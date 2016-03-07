//
//  SampleRequestListViewController.m
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Updated by TCCODER on 2/09/16.
//  -- implemented attachments sync
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "SampleRequestListViewController.h"

#import "ActionsPopupController.h"
#import "SObjectDataManager.h"
#import "SampleRequestDetailViewController.h"
#import "SampleRequestSObjectDataSpec.h"
#import "SampleRequestSObjectData.h"
#import "AttachmentSObjectData.h"
#import "AttachmentSObjectDataSpec.h"
#import "ContactSObjectData.h"
#import "ProductSObjectData.h"
#import "WYPopoverController.h"
#import "MBProgressHUD.h"
#import <SalesforceSDKCore/SFDefaultUserManagementViewController.h>
#import <SmartStore/SFSmartStoreInspectorViewController.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFSecurityLockout.h>
#import <SmartSync/SFSmartSyncSyncManager.h>
#import <SmartSync/SFSyncState.h>

static NSString * const kNavBarTitleText                = @"Sample Requests";
static NSUInteger const kNavBarTintColor                = 0xf10000;
static CGFloat    const kNavBarTitleFontSize            = 27.0;
static NSUInteger const kProductTitleTextColor          = 0x696969;
static CGFloat    const kProductTitleFontSize           = 15.0;
static CGFloat    const kProductDetailFontSize          = 13.0;


@interface SampleRequestListViewController () <UISearchBarDelegate>

@property (nonatomic, strong) WYPopoverController *popOverController;
@property (nonatomic, strong) UIActionSheet *logoutActionSheet;

// View / UI properties
@property (nonatomic, strong) UILabel *navBarLabel;
@property (nonatomic, strong) UIBarButtonItem *syncButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;

// Data properties
@property (nonatomic, strong) NSMutableArray *filtereDataRows;

// Data manager for attachments
@property (nonatomic, strong) SObjectDataManager *attachmentDataMgr;

@end

@implementation SampleRequestListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.filtereDataRows = [NSMutableArray array];

        self.dataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[SampleRequestSObjectData dataSpec]];
        self.attachmentDataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[AttachmentSObjectData dataSpec]];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.filtereDataRows = [NSMutableArray array];

        if (!self.dataMgr) {
            self.dataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[SampleRequestSObjectData dataSpec]];
        }
        if (!self.attachmentDataMgr) {
            self.attachmentDataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[AttachmentSObjectData dataSpec]];
        }
        [self.dataMgr refreshLocalData];
        if ([self.dataMgr.dataRows count] == 0)
            [self.dataMgr refreshRemoteData];
        [self.attachmentDataMgr refreshLocalData];
        if ([self.attachmentDataMgr.dataRows count] == 0)
            [self.attachmentDataMgr refreshRemoteData];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];

    self.navigationController.navigationBar.barTintColor = [[self class] colorFromRgbHexValue:kNavBarTintColor];

    // Nav bar label
    self.navBarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.navBarLabel.text = kNavBarTitleText;
    self.navBarLabel.textAlignment = NSTextAlignmentLeft;
    self.navBarLabel.textColor = [UIColor whiteColor];
    self.navBarLabel.backgroundColor = [UIColor clearColor];
    self.navBarLabel.font = [UIFont systemFontOfSize:kNavBarTitleFontSize];
    self.navigationItem.titleView = self.navBarLabel;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self reloadData];
}

#pragma mark - Overload methods

- (void)reloadData {
    [self.filtereDataRows removeAllObjects];
    [self.tableView reloadData];

    for (SampleRequestSObjectData *object in self.dataMgr.dataRows) {
        if (!object.ownerId || [object.ownerId isEqualToString:[SObjectDataSpec currentUserID]]) {
            [self.filtereDataRows addObject:object];
        } else {
            for (NSDictionary *user in object.userRecords) {
                NSString *userId = [user objectForKey:@"User__c"];
                if ([userId isEqualToString:[SObjectDataSpec currentUserID]]) {
                    [self.filtereDataRows addObject:object];
                    break;
                }
            }
        }
    }

    [super reloadData];
}

#pragma mark - UITableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filtereDataRows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SampleRequestListCellIdentifier";

    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    SampleRequestSObjectData *obj = [self.filtereDataRows objectAtIndex:indexPath.row];
    cell.textLabel.text = [self formatTitle:obj.name ? obj.name : @"Please sync"];
    cell.textLabel.font = [UIFont systemFontOfSize:kProductTitleFontSize];
    cell.detailTextLabel.text = [self formatSubtitle:obj];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:kProductDetailFontSize];
    cell.detailTextLabel.textColor = [[self class] colorFromRgbHexValue:kProductTitleTextColor];
    cell.imageView.image = nil;

    cell.accessoryView = [self accessoryViewForContact:obj];

    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SampleRequestSObjectData *contact = [self.filtereDataRows objectAtIndex:indexPath.row];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kNavBarTitleText style:UIBarButtonItemStylePlain target:nil action:nil];
    SampleRequestDetailViewController *detailVc = [[SampleRequestDetailViewController alloc] initWithSampleRequest:contact
                                                                                                       dataManager:self.dataMgr
                                                                                                         saveBlock:^{
                                                                                                           [self.tableView beginUpdates];
                                                                                                           [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                                                                                                           [self.tableView endUpdates];
                                                                                                       }];
    detailVc.contactMgr = self.contactDataMgr;
    detailVc.productMgr = self.productDataMgr;
    detailVc.attachmentMgr = self.attachmentDataMgr;

    [self.navigationController pushViewController:detailVc animated:YES];
}

#pragma mark - Private methods

- (void)add {
    [self addSampleRequest];
}

- (void)addSampleRequest {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kNavBarTitleText style:UIBarButtonItemStylePlain target:nil action:nil];
    SampleRequestDetailViewController *detailVc = [[SampleRequestDetailViewController alloc] initForNewSampleRequestWithDataManager:self.dataMgr saveBlock:^{
        [self.dataMgr refreshLocalData];
    }];
    detailVc.contactMgr = self.contactDataMgr;
    detailVc.productMgr = self.productDataMgr;
    detailVc.attachmentMgr = self.attachmentDataMgr;

    [self.navigationController pushViewController:detailVc animated:YES];
}

- (NSString *)formatSubtitle:(SampleRequestSObjectData *)sampleRequest {
    NSString *quantity = [sampleRequest.quantity stringValue];
    NSString *deliveryDate = [sampleRequest.deliveryDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    NSString *status = [sampleRequest.status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (deliveryDate == nil) {
        return [NSString stringWithFormat:@"Contact: %@ / Product: %@ / Qty: %@ / Status: %@ / Date: -",
                [self formatContact:sampleRequest], [self formatProduct:sampleRequest], quantity, status];
    } else {
        return [NSString stringWithFormat:@"Contact: %@ / Product: %@ / Qty: %@ / Status: %@ / Date: %@",
                [self formatContact:sampleRequest], [self formatProduct:sampleRequest], quantity, status, deliveryDate];
    }
}

- (NSString *)formatProduct:(SampleRequestSObjectData *) sampleRequest {
    ProductSObjectData *product = (ProductSObjectData *) [self.productDataMgr findById:sampleRequest.productId];
    return product ? product.name : (sampleRequest.productName ? sampleRequest.productName : @"");
}

- (NSString *)formatContact:(SampleRequestSObjectData *) sampleRequest {
    ContactSObjectData *contact = (ContactSObjectData *) [self.contactDataMgr findById:sampleRequest.contactId];
    if (!contact) {
        return sampleRequest.contactName ? sampleRequest.contactName : @"";
    }

    NSString *firstName = [contact.firstName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lastName = [contact.lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (firstName == nil && lastName == nil) {
        return @"";
    } else if (firstName == nil && lastName != nil) {
        return lastName;
    } else if (firstName != nil && lastName == nil) {
        return firstName;
    } else {
        return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    }
}

// override to sync attachments as well
- (void)syncUpDown {
    [self showToast:@"Syncing with Salesforce"];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // count changed attachments
    [self.attachmentDataMgr refreshLocalData];
    NSUInteger count = 0;
    for (SObjectData* data in self.attachmentDataMgr.dataRows)
        if ([self.attachmentDataMgr dataHasLocalChanges:data])
            ++count;
    
    NSMutableDictionary* addedRequestsEntryIDs = [NSMutableDictionary new];
    for (SampleRequestSObjectData* data in self.dataMgr.dataRows)
        if ([self.dataMgr dataLocallyCreated:data]) {
            addedRequestsEntryIDs[data.objectId] = data.soupEntryId;
        }
    
    // sync requests
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    typeof(self) __weak weakSelf = self;
    [self.dataMgr updateRemoteData:^(SFSyncState *syncProgressDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([syncProgressDetails isDone]) {
                
                [weakSelf.dataMgr refreshLocalData];
                // update attachments parentIds
                for (AttachmentSObjectData* data in self.attachmentDataMgr.dataRows)
                    if ([self.attachmentDataMgr dataHasLocalChanges:data] && addedRequestsEntryIDs[data.parentId]) {
                        for (SampleRequestSObjectData* req in weakSelf.dataMgr.dataRows) {
                            if ([req.soupEntryId isEqual:addedRequestsEntryIDs[data.parentId]]) {
                                data.parentId = req.objectId;
                                [self.attachmentDataMgr updateLocalData:data];
                                break;
                            }
                        }
                    }
                
                [weakSelf.dataMgr refreshRemoteData];
                
                // sync attachments after we synced the parent sample requests
                [weakSelf.attachmentDataMgr updateRemoteData:^(SFSyncState *sync) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                        if ([sync isDone]) {
                            [weakSelf.attachmentDataMgr refreshLocalData];
                            [weakSelf showToast:@"Sync complete!"];
                            [weakSelf.attachmentDataMgr refreshRemoteData];
                            // show uploaded attachments if any
                            if (count > 0) {
                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Success" message:[NSString stringWithFormat:@"Uploaded %d attachment(s)", (int)count] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];
                            }
                            [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
                        } else if ([syncProgressDetails hasFailed]) {
                            [weakSelf showToast:@"Sync failed."];
                            [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
                        } else {
                            [weakSelf showToast:sync.syncError.code == 400 ? @"Deleted 1 attachment" : [NSString stringWithFormat:@"Unexpected status: %@", [SFSyncState syncStatusToString:syncProgressDetails.status]]];
                            [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
                        }
                    });
                }];
                
            } else if ([syncProgressDetails hasFailed]) {
                [weakSelf showToast:@"Sync failed."];
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
            } else {
                [weakSelf showToast:[NSString stringWithFormat:@"Unexpected status: %@", [SFSyncState syncStatusToString:syncProgressDetails.status]]];
                weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                [MBProgressHUD hideHUDForView:weakSelf.navigationController.view animated:YES];
            }
        });
    }];
}

@end
