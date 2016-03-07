//
//  AttachmentSObjectDataSpec.m
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/9/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "AttachmentSObjectDataSpec.h"
#import "AttachmentSObjectData.h"

NSString * const kAttachmentNameField = @"Name";
NSString * const kAttachmentBodyField = @"Body";
NSString * const kAttachmentParentIdField = @"ParentId";

@implementation AttachmentSObjectDataSpec

/**
 *  desginated initializer
 */
- (id)init {
    NSString *objectType = @"Attachment";
    NSArray *objectFieldSpecs = @[ [[SObjectDataFieldSpec alloc] initWithFieldName:kObjectIdField searchable:NO],
                                   [[SObjectDataFieldSpec alloc] initWithFieldName:kObjectOwnerIdField searchable:NO],
                                   [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentNameField searchable:NO],
                                   [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentBodyField searchable:NO],
                                   [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentParentIdField searchable:YES],
                                   ];
    NSArray *updateObjectFieldSpecs = @[ [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentNameField searchable:NO],
                                         [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentBodyField searchable:NO],
                                         [[SObjectDataFieldSpec alloc] initWithFieldName:kAttachmentParentIdField searchable:YES],
                                         ];
    
    // Any searchable fields would likely require index specs, if you're searching directly against SmartStore.
    NSArray *indexSpecs = @[ [[SFSoupIndex alloc] initWithPath:kAttachmentParentIdField indexType:kSoupIndexTypeString columnName:kAttachmentParentIdField]
                             ];
    
    self.whereClause = nil;
    
    NSString *soupName = @"Attachments";
    NSString *orderByFieldName = kAttachmentParentIdField;
    return [self initWithObjectType:objectType objectFieldSpecs:objectFieldSpecs updateObjectFieldSpecs:updateObjectFieldSpecs
                         indexSpecs:indexSpecs soupName:soupName orderByFieldName:orderByFieldName];
}

#pragma mark - Abstract overrides

+ (SObjectData *)createSObjectData:(NSDictionary *)soupDict {
    return [[AttachmentSObjectData alloc] initWithSoupDict:soupDict];
}

@end
