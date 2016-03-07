//
//  SampleRequestDetailViewController.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SampleRequestSObjectData.h"
#import "SObjectDataManager.h"

@interface SampleRequestDetailViewController : UITableViewController <UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) SObjectDataManager *contactMgr;
@property (nonatomic, strong) SObjectDataManager *productMgr;
@property (nonatomic, strong) SObjectDataManager *attachmentMgr;

- (id)initForNewSampleRequestWithDataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock;
- (id)initWithSampleRequest:(SampleRequestSObjectData *)sampleRequest dataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock;

@end
