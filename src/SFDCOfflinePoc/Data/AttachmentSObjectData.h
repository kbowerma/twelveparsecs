//
//  AttachmentSObjectData.h
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/9/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObjectData.h"

/**
 @discussion attachment data model
 
 @author TCCODER
 
 @version 1.0
 */
@interface AttachmentSObjectData : SObjectData

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *parentId;
@property (nonatomic, copy) NSString *body;

@end
