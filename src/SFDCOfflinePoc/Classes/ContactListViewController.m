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

#import "ContactListViewController.h"
#import "SObjectDataManager.h"
#import "ContactSObjectDataSpec.h"
#import "ContactSObjectData.h"
#import "ContactDetailViewController.h"
#import "WYPopoverController.h"
#import <SalesforceSDKCore/SFDefaultUserManagementViewController.h>
#import <SmartStore/SFSmartStoreInspectorViewController.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFSecurityLockout.h>
#import <SmartSync/SFSmartSyncSyncManager.h>
#import <SmartSync/SFSyncState.h>

static NSString * const kNavBarTitleText                = @"Contacts";
static NSUInteger const kNavBarTintColor                = 0xf10000;
static CGFloat    const kNavBarTitleFontSize            = 27.0;
static NSUInteger const kContactTitleTextColor          = 0x696969;
static CGFloat    const kContactTitleFontSize           = 15.0;
static CGFloat    const kContactDetailFontSize          = 13.0;
static CGFloat    const kInitialsCircleDiameter         = 50.0;
static CGFloat    const kInitialsFontSize               = 19.0;

static NSUInteger const kColorCodesList[] = { 0x1abc9c,  0x2ecc71,  0x3498db,  0x9b59b6,  0x34495e,  0x16a085,  0x27ae60,  0x2980b9,  0x8e44ad,  0x2c3e50,  0xf1c40f,  0xe67e22,  0xe74c3c,  0x95a5a6,  0xf39c12,  0xd35400,  0xc0392b,  0xbdc3c7,  0x7f8c8d };

@interface ContactListViewController () <UISearchBarDelegate>

@property (nonatomic, strong) WYPopoverController *popOverController;
@property (nonatomic, strong) UIActionSheet *logoutActionSheet;

// View / UI properties
@property (nonatomic, strong) UILabel *navBarLabel;
@property (nonatomic, strong) UIBarButtonItem *syncButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, strong) UIBarButtonItem *moreButton;

@end

@implementation ContactListViewController

#pragma mark - init/setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.dataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[ContactSObjectData dataSpec]];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        if (!self.dataMgr) {
            self.dataMgr = [[SObjectDataManager alloc] initWithViewController:self dataSpec:[ContactSObjectData dataSpec]];
        }
        [self.dataMgr refreshLocalData];
        if ([self.dataMgr.dataRows count] == 0)
            [self.dataMgr refreshRemoteData];
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

#pragma mark - UITableView delegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ContactListCellIdentifier";
    
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    ContactSObjectData *obj = [self.dataMgr.dataRows objectAtIndex:indexPath.row];
    cell.textLabel.text = [self formatNameFromContact:obj];
    cell.textLabel.font = [UIFont systemFontOfSize:kContactTitleFontSize];
    cell.detailTextLabel.text = [self formatTitle:obj.title];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:kContactDetailFontSize];
    cell.detailTextLabel.textColor = [[self class] colorFromRgbHexValue:kContactTitleTextColor];
    cell.imageView.image = [self initialsBackgroundImageWithColor:[self colorFromContact:obj] initials:[self formatInitialsFromContact:obj]];
    
    cell.accessoryView = [self accessoryViewForContact:obj];
    
    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactSObjectData *contact = [self.dataMgr.dataRows objectAtIndex:indexPath.row];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kNavBarTitleText style:UIBarButtonItemStylePlain target:nil action:nil];
    ContactDetailViewController *detailVc = [[ContactDetailViewController alloc] initWithContact:contact
                                                                                     dataManager:self.dataMgr
                                                                                       saveBlock:^{
                                                                                           [self.tableView beginUpdates];
                                                                                           [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                                                                                           [self.tableView endUpdates];
                                                                                       }];
    [self.navigationController pushViewController:detailVc animated:YES];
}

#pragma mark - Private methods

- (void)add {
    [self addContact];
}

- (void)addContact {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kNavBarTitleText style:UIBarButtonItemStylePlain target:nil action:nil];
    ContactDetailViewController *detailVc = [[ContactDetailViewController alloc] initForNewContactWithDataManager:self.dataMgr saveBlock:^{
        [self.dataMgr refreshLocalData];
    }];
    [self.navigationController pushViewController:detailVc animated:YES];
}

- (NSString *)formatNameFromContact:(ContactSObjectData *)contact {
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

- (NSString *)formatInitialsFromContact:(ContactSObjectData *)contact {
    NSString *firstName = [contact.firstName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lastName = [contact.lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableString *initialsString = [NSMutableString stringWithString:@""];
    if ([firstName length] > 0) {
        unichar firstChar = [firstName characterAtIndex:0];
        NSString *firstCharString = [NSString stringWithCharacters:&firstChar length:1];
        [initialsString appendFormat:@"%@", firstCharString];
    }
    if ([lastName length] > 0) {
        unichar firstChar = [lastName characterAtIndex:0];
        NSString *firstCharString = [NSString stringWithCharacters:&firstChar length:1];
        [initialsString appendFormat:@"%@", firstCharString];
    }
    
    return initialsString;
}

- (UIColor *)colorFromContact:(ContactSObjectData *)contact {
    
    NSString *lastName = [contact.lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger codeSeedFromName = 0;
    for (NSUInteger i = 0; i < [lastName length]; i++) {
        codeSeedFromName += [lastName characterAtIndex:i];
    }
    
    static NSUInteger colorCodesListCount = sizeof(kColorCodesList) / sizeof(NSUInteger);
    NSUInteger colorCodesListIndex = codeSeedFromName % colorCodesListCount;
    NSUInteger colorCodeHexValue = kColorCodesList[colorCodesListIndex];
    return [[self class] colorFromRgbHexValue:colorCodeHexValue];
}

+ (UIColor *)colorFromRgbHexValue:(NSUInteger)rgbHexColorValue {
    return [UIColor colorWithRed:((CGFloat)((rgbHexColorValue & 0xFF0000) >> 16)) / 255.0
                           green:((CGFloat)((rgbHexColorValue & 0xFF00) >> 8)) / 255.0
                            blue:((CGFloat)(rgbHexColorValue & 0xFF)) / 255.0
                           alpha:1.0];
}

- (UIImage *)initialsBackgroundImageWithColor:(UIColor *)circleColor initials:(NSString *)initials {
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kInitialsCircleDiameter, kInitialsCircleDiameter), NO, [UIScreen mainScreen].scale);
    
    // Draw the circle.
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGPoint circleCenter = CGPointMake(kInitialsCircleDiameter / 2.0, kInitialsCircleDiameter / 2.0);
    CGContextSetFillColorWithColor(context, [circleColor CGColor]);
    CGContextBeginPath(context);
    CGContextAddArc(context, circleCenter.x, circleCenter.y, kInitialsCircleDiameter / 2.0, 0, 2*M_PI, 0);
    CGContextFillPath(context);
    
    // Draw the initials.
    NSDictionary *initialsAttrs = @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:kInitialsFontSize] };
    CGSize initialsTextSize = [initials sizeWithAttributes:initialsAttrs];
    CGRect initialsRect = CGRectMake(circleCenter.x - (initialsTextSize.width / 2.0), circleCenter.y - (initialsTextSize.height / 2.0), initialsTextSize.width, initialsTextSize.height);
    [initials drawInRect:initialsRect withAttributes:initialsAttrs];
    
    UIGraphicsPopContext();
    
    UIImage *imageFromGraphicsContext = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageFromGraphicsContext;
}

@end
