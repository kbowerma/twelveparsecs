//
//  SampleRequestSObjectData.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import "SObjectData.h"

@interface SampleRequestSObjectData : SObjectData

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *contactId;
@property (nonatomic, copy) NSString *contactName;
@property (nonatomic, copy) NSString *productId;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *deliveryDate;
@property (nonatomic, copy) NSNumber *quantity;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSDictionary *authorizedUsers;
@property (nonatomic, copy) NSArray *userRecords;
@property (nonatomic, copy) NSArray *attachments;
@property (nonatomic, readonly) NSNumber *soupEntryId;

@end
