//
//  ProductSObjectData.h
//  SFDCOfflinePoc
//
//  Created by PAULO VITOR MAGACHO DA SILVA on 1/24/16.
//  Copyright © 2016 Topcoder Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObjectData.h"

@interface ProductSObjectData : SObjectData

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *productDescription;
@property (nonatomic, copy) NSString *sku;

@end
