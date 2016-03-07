//
//  AttachmentSObjectData.m
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/9/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "AttachmentSObjectData.h"
#import "AttachmentSObjectDataSpec.h"
#import "SObjectData+Internal.h"
#import <SmartSync/SFSmartSyncConstants.h>


@implementation AttachmentSObjectData

+ (SObjectDataSpec *)dataSpec {
    static AttachmentSObjectDataSpec *sDataSpec = nil;
    if (sDataSpec == nil) {
        sDataSpec = [[AttachmentSObjectDataSpec alloc] init];
    }
    return sDataSpec;
}

#pragma mark - Property getters / setters

- (NSString *)name {
    return [self nonNullFieldValue:kAttachmentNameField];
}

- (void)setName:(NSString *)name {
    [self updateSoupForFieldName:kAttachmentNameField fieldValue:name];
}

- (NSString *)body {
    return [self nonNullFieldValue:kAttachmentBodyField];
}

- (void)setBody:(NSString *)body {
    [self updateSoupForFieldName:kAttachmentBodyField fieldValue:body];
}

- (NSString *)parentId {
    return [self nonNullFieldValue:kAttachmentParentIdField];
}

- (void)setParentId:(NSString *)parentId {
    [self updateSoupForFieldName:kAttachmentParentIdField fieldValue:parentId];
}

@end
