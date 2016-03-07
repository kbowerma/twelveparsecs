//
//  AttachmentSObjectDataSpec.h
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/9/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SObjectDataSpec.h"
// fields
extern NSString * const kAttachmentNameField;
extern NSString * const kAttachmentBodyField;
extern NSString * const kAttachmentParentIdField;

/**
 @discussion attachment data spec
 
 @author TCCODER
 
 @version 1.0
 */
@interface AttachmentSObjectDataSpec : SObjectDataSpec

@end
