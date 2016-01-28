//
//  SampleRequestDetailViewController.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "ProductDetailViewController.h"
#import "ProductSObjectDataSpec.h"

@interface ProductDetailViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) ProductSObjectData *product;
@property (nonatomic, strong) SObjectDataManager *dataMgr;
@property (nonatomic, copy) void (^saveBlock)(void);
@property (nonatomic, strong) NSArray *dataRows;
@property (nonatomic, strong) NSArray *productDataRows;
@property (nonatomic, strong) NSArray *deleteButtonDataRow;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL productUpdated;
@property (nonatomic, assign) BOOL isNewProduct;

@end

@implementation ProductDetailViewController

- (id)initForNewProductWithDataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock {
    return [self initWithProduct:nil dataManager:dataMgr saveBlock:saveBlock];
}

- (id)initWithProduct:(ProductSObjectData *)product dataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (product == nil) {
            self.isNewProduct = YES;
            self.product = [[ProductSObjectData alloc] init];
        } else {
            self.isNewProduct = NO;
            self.product = product;
        }
        self.dataMgr = dataMgr;
        self.saveBlock = saveBlock;
        self.isEditing = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.dataRows = [self dataRowsFromProduct];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self configureInitialBarButtonItems];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (self.isNewProduct) {
        [self editProduct];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.productUpdated && self.saveBlock != NULL) {
        dispatch_async(dispatch_get_main_queue(), self.saveBlock);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataRows count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ProductDetailCellIdentifier";
    
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section < [self.productDataRows count]) {
        if (self.isEditing) {
            cell.textLabel.text = nil;
            UITextField *editField = self.dataRows[indexPath.section][3];
            editField.frame = cell.contentView.bounds;
            [self productTextFieldAddLeftMargin:editField];
            [cell.contentView addSubview:editField];
        } else {
            UITextField *editField = self.dataRows[indexPath.section][3];
            [editField removeFromSuperview];
            NSString *rowValueData = self.dataRows[indexPath.section][2];
            cell.textLabel.text = rowValueData;
        }
    } else {
        UIButton *deleteButton = self.dataRows[indexPath.section][1];
        deleteButton.frame = cell.contentView.bounds;
        [cell.contentView addSubview:deleteButton];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.dataRows[section][0];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self deleteProduct];
    }
}

#pragma mark - Private methods

- (void)configureInitialBarButtonItems {
    if (self.isNewProduct) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProduct)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editProduct)];
    }
    self.navigationItem.leftBarButtonItem = nil;
}

- (NSArray *)dataRowsFromProduct {
    
    self.productDataRows = @[ @[ @"Name",
                                 kProductNameField,
                                 [[self class] emptyStringForNullValue:self.product.name],
                                 [self productTextField:self.product.name] ],
                              @[ @"Description",
                                 kProductDescriptionField,
                                 [[self class] emptyStringForNullValue:self.product.productDescription],
                                 [self productTextField:self.product.productDescription] ],
                              @[ @"Sku",
                                 kProductSKUField,
                                 [[self class] emptyStringForNullValue:self.product.sku],
                                 [self productTextField:self.product.sku] ]
                              ];
    self.deleteButtonDataRow = @[ @"", [self deleteButtonView] ];
    
    NSMutableArray *workingDataRows = [NSMutableArray array];
    [workingDataRows addObjectsFromArray:self.productDataRows];
    if (!self.isNewProduct) {
        [workingDataRows addObject:self.deleteButtonDataRow];
    }
    return workingDataRows;
}

- (void)editProduct {
    self.isEditing = YES;
    if (!self.isNewProduct) {
        // Buttons will already be set for new product case.
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditProduct)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProduct)];
    }
    [self.tableView reloadData];
    __weak ProductDetailViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.dataRows[0][3] becomeFirstResponder];
    });
}

- (void)cancelEditProduct {
    self.isEditing = NO;
    [self configureInitialBarButtonItems];
    [self.tableView reloadData];
}

- (void)saveProduct {
    [self configureInitialBarButtonItems];
    
    self.productUpdated = NO;
    for (NSArray *fieldArray in self.productDataRows) {
        NSString *fieldName = fieldArray[1];
        NSString *origFieldData = fieldArray[2];
        NSString *newFieldData = ((UITextField *)fieldArray[3]).text;
        if (![newFieldData isEqualToString:origFieldData]) {
            [self.product updateSoupForFieldName:fieldName fieldValue:newFieldData];
            self.productUpdated = YES;
        }
    }
    
    if (self.productUpdated) {
        if (self.isNewProduct) {
            [self.dataMgr createLocalData:self.product];
        } else {
            [self.dataMgr updateLocalData:self.product];
        }
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.tableView reloadData];
    }
    
}

- (void)deleteProductConfirm {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm Delete" message:@"Are you sure you want to delete this product?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)deleteProduct {
    [self.dataMgr deleteLocalData:self.product];
    self.productUpdated = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (UITextField *)productTextField:(NSString *)propertyValue {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.text = propertyValue;
    return textField;
}

- (UIButton *)deleteButtonView {
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteButton setTitle:@"Delete Product" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
    deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    deleteButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    [deleteButton addTarget:self action:@selector(deleteProductConfirm) forControlEvents:UIControlEventTouchUpInside];
    return deleteButton;
}

- (void)productTextFieldAddLeftMargin:(UITextField *)textField {
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

@end
