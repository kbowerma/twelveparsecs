//
//  SampleRequestDetailViewController.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductSObjectData.h"
#import "SObjectDataManager.h"

@interface ProductDetailViewController : UITableViewController <UITableViewDataSource>

- (id)initForNewProductWithDataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock;
- (id)initWithProduct:(ProductSObjectData *)product dataManager:(SObjectDataManager *)dataMgr saveBlock:(void (^)(void))saveBlock;

@end
