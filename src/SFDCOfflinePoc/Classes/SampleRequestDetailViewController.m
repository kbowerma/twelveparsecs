//
//  SampleRequestDetailViewController.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Updated by TCCODER on 1/31/16.
//  -- added signature view & appropriate logic
//  Updated by TCCODER on 2/09/16.
//  -- removed image storing; implemented SmartStore sync
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "SampleRequestDetailViewController.h"
#import "SampleRequestSObjectDataSpec.h"
#import "SampleRequestSObjectData.h"
#import "ProductSObjectData.h"
#import "ContactSObjectData.h"
#import "AttachmentSObjectData.h"
#import "PaintingView.h"
#import "MBProgressHUD.h"
#import "Configurations.h"
#import "SFSDKReachability.h"

#define kTagContact 1000
#define kTagProduct 1001
#define kTagStatus 1002

// signature view height
#define kSignatureViewHeight 160
// signature view border
#define kSignatureViewBorderOffset (IS_IPAD ? 90 : 15)



@interface SampleRequestDetailViewController () <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) SampleRequestSObjectData *sampleRequest;
@property (nonatomic, strong) SObjectDataManager *dataMgr;
@property (nonatomic, copy) void (^saveBlock)(void);
@property (nonatomic, strong) NSArray *dataRows;
@property (nonatomic, strong) NSArray *sampleRequestDataRows;
@property (nonatomic, strong) NSArray *signDataRow;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL sampleRequestUpdated;
@property (nonatomic, assign) BOOL isNewSampleRequest;

@property (nonatomic, assign) NSInteger editTextTag;
@property (nonatomic, strong) NSArray *statusArray;
@property (nonatomic, strong) ContactSObjectData *contactObject;
@property (nonatomic, strong) ProductSObjectData *productObject;

// View / UI properties
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) PaintingView *paintingView;
@property (nonatomic, strong) UIButton *signEraseButton;
@property (nonatomic, strong) UIButton *signConfirmButton;
@property (nonatomic, strong) UILabel *signHeaderLabel;

@end

@implementation SampleRequestDetailViewController {
    BOOL isCurrentUser;
}

@synthesize contactMgr;
@synthesize productMgr;

- (id)initForNewSampleRequestWithDataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock {
    return [self initWithSampleRequest:nil dataManager:dataMgr saveBlock:saveBlock];
}

- (id)initWithSampleRequest:(SampleRequestSObjectData *)sampleRequest dataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (sampleRequest == nil) {
            self.isNewSampleRequest = YES;
            self.sampleRequest = [[SampleRequestSObjectData alloc] init];
        } else {
            self.isNewSampleRequest = NO;
            self.sampleRequest = sampleRequest;
        }
        self.dataMgr = dataMgr;
        self.saveBlock = saveBlock;
        self.isEditing = NO;

        self.statusArray = @[ @"Requested", @"Scheduled", @"Delivered" ];

        self.pickerView = [[UIPickerView alloc] init];
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        self.pickerView.showsSelectionIndicator = YES;
    }
    return self;
}

- (void)loadView {
    [super loadView];

    self.contactObject = self.isNewSampleRequest ? [self.contactMgr.dataRows firstObject] : [self.contactMgr findById:self.sampleRequest.contactId];
    self.productObject = self.isNewSampleRequest ? [self.productMgr.dataRows firstObject] : [self.productMgr findById:self.sampleRequest.productId];

    self.dataRows = [self dataRowsFromSampleRequest];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self configureInitialBarButtonItems];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 44;

    isCurrentUser = self.isNewSampleRequest || [self.sampleRequest.ownerId isEqualToString:[SObjectDataSpec currentUserID]];
}

/**
 *  cleanup
 */
- (void)dealloc {
    [self.paintingView clearMemory];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isNewSampleRequest) {
        [self editSampleRequest];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.sampleRequestUpdated && self.saveBlock != NULL) {
        dispatch_async(dispatch_get_main_queue(), self.saveBlock);
    }
}

#pragma mark - UITableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataRows count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section < [self.sampleRequestDataRows count]) ? 44 : kSignatureViewHeight+55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SampleRequestDetailCellIdentifier";

    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSArray *sampleRequestData = self.dataRows[indexPath.section];
    if (indexPath.section < [self.sampleRequestDataRows count]) {
        if (self.isEditing) {
            cell.textLabel.text = nil;
            UITextField *editField = sampleRequestData[3];
            editField.frame = cell.contentView.bounds;
            if (sampleRequestData[1] == kSampleRequestNameField ||
                sampleRequestData[1] == kSampleRequestAuthorizedUsersField) {
                editField.delegate = self; // will disable the text field
            }
            [self textFieldAddLeftMargin:editField];
            [cell.contentView addSubview:editField];
        } else {
            UITextField *editField = sampleRequestData[3];
            [editField removeFromSuperview];
            NSString *rowValueData = sampleRequestData[2];
            cell.textLabel.text = rowValueData;
        }
    } else {
        UIView *signView = sampleRequestData[1];
        signView.frame = cell.contentView.bounds;
        [cell.contentView addSubview:signView];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.dataRows[section][0];
}

#pragma mark - UIPickerView delegate methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *value = nil;

    if (self.editTextTag == kTagContact) {
        self.contactObject = [self.contactMgr.dataRows objectAtIndex:row];
        value = [self formatNameFromContact:self.contactObject];
    } else if (self.editTextTag == kTagProduct) {
        self.productObject = [self.productMgr.dataRows objectAtIndex:row];
        value = [self formatNameFromProduct:self.productObject];
    } else if (self.editTextTag == kTagStatus) {
        value = [self.statusArray objectAtIndex:row];
    }

    UITextField *textField = (UITextField *) [self.view viewWithTag:self.editTextTag];
    textField.text = value;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.editTextTag == kTagContact) {
        return self.contactMgr.dataRows.count;
    } else if (self.editTextTag == kTagProduct) {
        return self.productMgr.dataRows.count;
    } else if (self.editTextTag == kTagStatus) {
        return self.statusArray.count;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow: (NSInteger)row forComponent:(NSInteger)component {
    if (self.editTextTag == kTagContact) {
        ContactSObjectData *obj = [self.contactMgr.dataRows objectAtIndex:row];
        return [self formatNameFromContact:obj];
    } else if (self.editTextTag == kTagProduct) {
        return [[self.productMgr.dataRows objectAtIndex:row] name];
    } else if (self.editTextTag == kTagStatus) {
        return [self.statusArray objectAtIndex:row];
    }
    return nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return textField.tag == kTagStatus || ((textField.tag == kTagContact || textField.tag == kTagProduct) && isCurrentUser);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (![self textFieldShouldBeginEditing:textField]) {
        return;
    }

    self.editTextTag = textField.tag;
    NSInteger row = 0;

    [self.pickerView reloadAllComponents];
    [textField reloadInputViews];

    if (self.editTextTag == kTagContact) {
        row = [self.contactMgr.dataRows indexOfObject:self.contactObject];
    } else if (self.editTextTag == kTagProduct) {
        row = [self.productMgr.dataRows indexOfObject:self.productObject];
    } else if (self.editTextTag == kTagStatus) {
        row = [self.statusArray indexOfObject:textField.text];
    }
    row = row == NSNotFound ? 0 : row;

    [self.pickerView selectRow:row inComponent:0 animated:NO];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self deleteSampleRequest];
    }
}

#pragma mark - Private methods

- (void)configureInitialBarButtonItems {
    if (self.isNewSampleRequest) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveSampleRequest)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editSampleRequest)];
    }
    self.navigationItem.leftBarButtonItem = nil;
}

- (NSArray *)dataRowsFromSampleRequest {
    if (self.isNewSampleRequest) {
        self.sampleRequestDataRows = @[ @[ @"Contact",
                                     kSampleRequestContactField,
                                     [[self class] emptyStringForNullValue:[self formatNameFromContact:self.contactObject]],
                                     [self dataTextFieldPicker:[self formatNameFromContact:self.contactObject] tag:kTagContact] ],
                                  @[ @"Product",
                                     kSampleRequestProductField,
                                     [[self class] emptyStringForNullValue:[self formatNameFromProduct:self.productObject]],
                                     [self dataTextFieldPicker:[self formatNameFromProduct:self.productObject] tag:kTagProduct] ],
                                  @[ @"Quantity",
                                     kSampleRequestQuantityField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.quantity.stringValue],
                                     [self dataTextField:self.sampleRequest.quantity.stringValue] ],
                                  @[ @"Status",
                                     kSampleRequestStatusField,
                                     [[self class] emptyStringForNullValue:@"Requested"],
                                     [self dataTextFieldPicker:@"Requested" tag:kTagStatus] ],
                                  @[ @"Delivery Date",
                                     kSampleRequestDeliveryDateField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.deliveryDate],
                                    [self dataTextField:self.sampleRequest.deliveryDate] ]
                                  ];
    } else {
        self.sampleRequestDataRows = @[ @[ @"Name",
                                     kSampleRequestNameField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.name ? self.sampleRequest.name : @"Please sync"],
                                     [self dataTextField:self.sampleRequest.name ? self.sampleRequest.name : @"Please sync"] ],
                                  @[ @"Contact",
                                     kSampleRequestContactField,
                                     [[self class] emptyStringForNullValue:[self formatNameFromContact:self.contactObject]],
                                     [self dataTextFieldPicker:[self formatNameFromContact:self.contactObject] tag:kTagContact] ],
                                  @[ @"Product",
                                     kSampleRequestProductField,
                                     [[self class] emptyStringForNullValue:[self formatNameFromProduct:self.productObject]],
                                     [self dataTextFieldPicker:[self formatNameFromProduct:self.productObject] tag:kTagProduct] ],
                                  @[ @"Quantity",
                                     kSampleRequestQuantityField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.quantity.stringValue],
                                     [self dataTextField:self.sampleRequest.quantity.stringValue] ],
                                  @[ @"Status",
                                     kSampleRequestStatusField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.status],
                                     [self dataTextFieldPicker:self.sampleRequest.status tag:kTagStatus] ],
                                 @[ @"Delivery Date",
                                     kSampleRequestDeliveryDateField,
                                     [[self class] emptyStringForNullValue:self.sampleRequest.deliveryDate],
                                    [self dataTextField:self.sampleRequest.deliveryDate] ],
                                 @[ @"Authorized Users",
                                     kSampleRequestAuthorizedUsersField,
                                    [[self class] emptyStringForNullValue:[self formatAuthorizedUsers]],
                                    [self dataTextField:[self formatAuthorizedUsers]] ]

                                 ];
    }

    self.signDataRow = @[ @"", [self makePaintingView] ];

    NSMutableArray *workingDataRows = [NSMutableArray array];
    [workingDataRows addObjectsFromArray:self.sampleRequestDataRows];
    if (!self.isNewSampleRequest) {
        [workingDataRows addObject:self.signDataRow];
    }
    return workingDataRows;
}

- (void)editSampleRequest {
    self.isEditing = YES;
    if (!self.isNewSampleRequest) {
        // Buttons will already be set for new contact case.
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditSampleRequest)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveSampleRequest)];
        [self signatureErase];
    }
    [self.tableView reloadData];
    __weak SampleRequestDetailViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.dataRows[0][3] becomeFirstResponder];
    });
}

- (void)cancelEditSampleRequest {
    self.isEditing = NO;
    [self configureInitialBarButtonItems];
    [self.tableView reloadData];
}

- (void)saveSampleRequest {
    [self configureInitialBarButtonItems];

    self.sampleRequestUpdated = NO;
    for (NSArray *fieldArray in self.sampleRequestDataRows) {
        NSString *fieldName = fieldArray[1];
        NSString *origFieldData = fieldArray[2];
        id newFieldData = ((UITextField *)fieldArray[3]).text;
        if ((self.isNewSampleRequest && newFieldData) || ![newFieldData isEqualToString:origFieldData]) {
            if (fieldName == kSampleRequestContactField) {
                newFieldData = self.contactObject.objectId;
                if (!newFieldData) {
                    return;
                }
            } else if (fieldName == kSampleRequestProductField) {
                newFieldData = self.productObject.objectId;
                if (!newFieldData) {
                    return;
                }
            } else if (fieldName == kSampleRequestQuantityField) {
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                newFieldData = [f numberFromString:newFieldData];
                if (!newFieldData) {
                    return;
                }
            } else if (fieldName == kSampleRequestDeliveryDateField) {
                NSString *date = newFieldData;
                if (!date || date.length == 0) {
                    continue;
                }
            }
            [self.sampleRequest updateSoupForFieldName:fieldName fieldValue:newFieldData];
            self.sampleRequestUpdated = YES;
        }
    }

    if (self.sampleRequestUpdated) {
        if (self.isNewSampleRequest) {
            [self.dataMgr createLocalData:self.sampleRequest];
        } else {
            [self.dataMgr updateLocalData:self.sampleRequest];
        }
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.tableView reloadData];
    }
}

- (void)deleteSampleRequestConfirm {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Delete" message:@"Are you sure you want to delete this sample request?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)deleteSampleRequest {
    [self.dataMgr deleteLocalData:self.sampleRequest];
    self.sampleRequestUpdated = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (UITextField *)dataTextField:(NSString *)propertyValue {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.text = propertyValue;
    return textField;
}

- (UITextField *)dataTextFieldPicker:(NSString *)propertyValue tag:(NSInteger) tag {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.delegate = self;
    textField.tag = tag;
    textField.text = propertyValue;

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                   target:self action:@selector(pickerDone:)];
    UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:
                          CGRectMake(0, self.view.frame.size.height-
                                     self.pickerView.frame.size.height-50, 320, 50)];
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    NSArray *toolbarItems = [NSArray arrayWithObjects:
                             doneButton, nil];
    [toolBar setItems:toolbarItems];
    textField.inputView = self.pickerView;
    textField.inputAccessoryView = toolBar;

    return textField;
}

/**
 *  creates a painting view inside a view container
 *
 *  @return container view
 */
- (UIView*)makePaintingView {
    // conatiner
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kSignatureViewHeight+100)];
    
    // header
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(kSignatureViewBorderOffset, -1, 160, 15)];
    label.font = [UIFont systemFontOfSize:14];
    label.text = @"Please sign here:";
    [containerView addSubview:label];
    self.signHeaderLabel = label;
    
    // GLPaint view
    self.paintingView = [[PaintingView alloc] initWithFrame:CGRectMake(kSignatureViewBorderOffset, 15, containerView.bounds.size.width-kSignatureViewBorderOffset*2, kSignatureViewHeight)];
    [containerView addSubview:_paintingView];
    [_paintingView setBrushColorWithRed:0 green:0 blue:0];
    _paintingView.backgroundColor = [UIColor clearColor];
    _paintingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    // old signature
    UIImageView* borderView = [[UIImageView alloc] initWithFrame:_paintingView.frame];
    borderView.backgroundColor = [UIColor clearColor];
    borderView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    borderView.layer.borderWidth = 2;
    borderView.userInteractionEnabled = NO;
    borderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [containerView addSubview:borderView];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // block table panning when user draws
    UIPanGestureRecognizer* panGesture = [UIPanGestureRecognizer new];
    panGesture.cancelsTouchesInView = NO;
    panGesture.delaysTouchesEnded = NO;
    [self.tableView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    [containerView addGestureRecognizer:panGesture];
    
    // confirm button
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    confirmButton.frame = CGRectMake(containerView.bounds.size.width-100-kSignatureViewBorderOffset, CGRectGetMaxY(_paintingView.frame), 100, 44);
    [confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
    confirmButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [confirmButton addTarget:self action:@selector(signatureConfirm) forControlEvents:UIControlEventTouchUpInside];
    confirmButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [containerView addSubview:confirmButton];
    self.signConfirmButton = confirmButton;
    
    // erase button
    UIButton *eraseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    eraseButton.frame = CGRectMake(kSignatureViewBorderOffset, CGRectGetMaxY(_paintingView.frame), 100, 44);
    [eraseButton setTitle:@"Erase" forState:UIControlStateNormal];
    [eraseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    eraseButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
    eraseButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [eraseButton addTarget:self action:@selector(signatureErase) forControlEvents:UIControlEventTouchUpInside];
    eraseButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [containerView addSubview:eraseButton];
    self.signEraseButton = eraseButton;
    
    return containerView;
}

/**
 *  sign confirm button tapped
 */
- (void)signatureConfirm {
    if (![self.paintingView hasSignature]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please, sign first" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    [self generatePDF:^(NSData *data) {
        [self sendPDF:data];
    }];
}

/**
 *  sign erase button tapped
 */
- (void)signatureErase {
    [self.paintingView erase];
}

/**
 *  generates PDF
 *
 *  @param onComplete completion handler
 */
- (void)generatePDF:(void (^)(NSData* data))onComplete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // prepare signature
        UIImage* signature = [self createSignImage];
        
        // setup pdf context
        NSMutableData* data = [NSMutableData new];
        CGRect bounds = CGRectMake(0, 0, [Configurations pdfWidth], [Configurations pdfHeight]);
        UIGraphicsBeginPDFContextToData(data, bounds, nil);
        UIGraphicsBeginPDFPage();
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        UIColor* bgColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
        
        // draw table
        CGFloat padding = [Configurations pdfPadding];
        NSDictionary* textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:[Configurations pdfFontSize]],
                                         NSForegroundColorAttributeName: [UIColor blackColor]};
        CGFloat yOffset = padding;
        for (NSArray* row in _sampleRequestDataRows) {
            NSString *rowHeader = row[0];
            NSString *rowValueData = row[2];
            // header
            [bgColor setFill];
            CGRect headerRect = CGRectMake(0, yOffset, bounds.size.width, [Configurations pdfHeaderHeight]);
            CGContextFillRect(c, headerRect);
            headerRect.origin.x = padding;
            headerRect.size.width -= padding*2;
            headerRect.origin.y = yOffset + [Configurations pdfHeaderHeight]/2 - [rowHeader sizeWithAttributes:textAttributes].height/2;
            [rowHeader drawInRect:headerRect withAttributes:textAttributes];
            yOffset += headerRect.size.height;
            // value
            CGRect textRect = CGRectMake(padding, yOffset + [Configurations pdfRowHeight]/2-[rowValueData sizeWithAttributes:textAttributes].height/2, bounds.size.width-padding*2, [Configurations pdfRowHeight]);
            [rowValueData drawInRect:textRect withAttributes:textAttributes];
            yOffset += textRect.size.height;
        }
        
        // draw signature
        [signature drawAtPoint:CGPointMake(padding, MIN(bounds.size.height-signature.size.height, yOffset))];
        
        UIGraphicsEndPDFContext();
        
        if (onComplete)
            onComplete(data);
    });
}

/**
 *  sends PDF to salesforce
 *
 *  @param data PDF data
 */
- (void)sendPDF:(NSData*)data {
    // prepare attachment
    NSString *b64 = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    AttachmentSObjectData* att = [[AttachmentSObjectData alloc] init];
    
    self.sampleRequestUpdated = YES;
    [self.dataMgr dataLocallyCreated:_sampleRequest] ? [self.dataMgr createLocalData:_sampleRequest] : [self.dataMgr updateLocalData:_sampleRequest];
    
    NSString* parentID = _sampleRequest.objectId;
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"YYYY-MM-dd'T'HH:mm:ss";
    att.name = [[[Configurations pdfName] stringByAppendingFormat:@"_%@", [dateFormatter stringFromDate:[NSDate date]]] stringByAppendingPathExtension:@"pdf"];
    att.body = b64;
    att.parentId = parentID;
    
    [self.attachmentMgr createLocalData:att];
    
    
    // check if connected
    if ([[SFSDKReachability reachabilityForInternetConnection] currentReachabilityStatus] == SFSDKReachabilityNotReachable) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Please sync when Internet connection is available" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [self.navigationController popViewControllerAnimated:YES];
        });
        return;
    }

    // count changes
    [self.attachmentMgr refreshLocalData];
    NSUInteger count = 0;
    for (SObjectData* data in self.attachmentMgr.dataRows)
        if ([self.attachmentMgr dataHasLocalChanges:data])
            ++count;

    // prepare IDs for mapping after requests synced
    NSMutableDictionary* addedRequestsEntryIDs = [NSMutableDictionary new];
    for (SampleRequestSObjectData* data in self.dataMgr.dataRows)
        if ([self.dataMgr dataLocallyCreated:data]) {
            addedRequestsEntryIDs[data.objectId] = data.soupEntryId;
        }
    
    // sync requests
    typeof(self) __weak weakSelf = self;
    [self.dataMgr updateRemoteData:^(SFSyncState *syncProgressDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([syncProgressDetails isDone]) {
                
                [weakSelf.dataMgr refreshLocalData];
                // updated IDs for created requests
                for (AttachmentSObjectData* data in self.attachmentMgr.dataRows)
                    if ([self.attachmentMgr dataHasLocalChanges:data] && addedRequestsEntryIDs[data.parentId]) {
                        for (SampleRequestSObjectData* req in weakSelf.dataMgr.dataRows) {
                            if ([req.soupEntryId isEqual:addedRequestsEntryIDs[data.parentId]]) {
                                data.parentId = req.objectId;
                                [self.attachmentMgr updateLocalData:data];
                                break;
                            }
                        }
                    }
                
                [weakSelf.dataMgr refreshRemoteData];
                // upload attachments
                [weakSelf.attachmentMgr updateRemoteData:^(SFSyncState *sync) {
                    if ([sync isDone]) {
                        [weakSelf.attachmentMgr refreshLocalData];
                        [weakSelf.attachmentMgr refreshRemoteData];
                        [weakSelf.dataMgr refreshLocalData];
                        [weakSelf.dataMgr refreshRemoteData];
                        NSString* msg = [NSString stringWithFormat:@"Uploaded %d attachment(s)", (int)count];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                            [weakSelf showAlert:msg title:@"Success"];
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    } else if ([sync hasFailed]) {
                        NSString* msg = sync.syncError.code == 400 ? @"Signed sample request has been remotely deleted" : @"Sync failed, try again later";
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                            [weakSelf showAlert:msg title:@"Error"];
                        });
                    } else {
                        NSString* msg = [NSString stringWithFormat:@"Unexpected status: %@", [SFSyncState syncStatusToString:sync.status]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                            [weakSelf showAlert:msg title:@"Error"];
                        });
                    }
                    
                }];
                
            } else if ([syncProgressDetails hasFailed]) {
                NSString* msg = @"Sync failed, try again later";
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    [weakSelf showAlert:msg title:@"Error"];
                });
            } else {
                NSString* msg = [NSString stringWithFormat:@"Unexpected status: %@", [SFSyncState syncStatusToString:syncProgressDetails.status]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    [weakSelf showAlert:msg title:@"Error"];
                });
            }
        });
    }];
    

}

- (void)showAlert:(NSString*)msg title:(NSString*)title {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

/**
 *  gets current signature image
 *
 *  @return sign image
 */
- (UIImage*)createSignImage {
    UIGraphicsBeginImageContext(self.paintingView.frame.size);
    [self.paintingView drawViewHierarchyInRect:self.paintingView.bounds afterScreenUpdates:NO];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)pickerDone:(id) sender {
    [[self.view viewWithTag:self.editTextTag] resignFirstResponder];
}

- (void)textFieldAddLeftMargin:(UITextField *)textField {
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, textField.frame.size.height)];
    leftView.backgroundColor = textField.backgroundColor;
    textField.leftView = leftView;
    textField.leftViewMode = UITextFieldViewModeAlways;
}

+ (NSString *)emptyStringForNullValue:(id)origValue {
    if (origValue == nil || origValue == [NSNull null]) {
        return @"";
    } else {
        return origValue;
    }
}

- (NSString *)formatAuthorizedUsers {
    NSArray *userRecords = self.sampleRequest.userRecords;
    if (!userRecords) return @"";

    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < userRecords.count; i++) {
        NSDictionary *userDict = [[userRecords objectAtIndex:i] objectForKey:@"User__r"];
        [string appendString:[userDict objectForKey:@"Name"]];
        if (i < userRecords.count - 1) {
            [string appendString:@", "];
        }
    }
    return string;
}

- (NSString *)formatNameFromProduct:(ProductSObjectData *)product {
    return product ? product.name : (self.sampleRequest.productName ? self.sampleRequest.productName : @"");
}

- (NSString *)formatNameFromContact:(ContactSObjectData *)contact {
    if (!contact) {
        return self.sampleRequest.contactName ? self.sampleRequest.contactName : @"";
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

@end
