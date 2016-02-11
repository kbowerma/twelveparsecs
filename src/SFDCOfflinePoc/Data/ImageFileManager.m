//
//  ImageFileManager.m
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/2/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "ImageFileManager.h"

@implementation ImageFileManager

+ (void)storeImage:(UIImage *)image withID:(NSString *)imageID {
    [UIImagePNGRepresentation(image) writeToFile:[self pathForImageID:imageID] atomically:YES];
}

+ (void)deleteImageWithID:(NSString *)imageID {
    [[NSFileManager defaultManager] removeItemAtPath:[self pathForImageID:imageID] error:nil];
}

+ (UIImage*)loadImageWithID:(NSString *)imageID {
    return [UIImage imageWithContentsOfFile:[self pathForImageID:imageID]];
}

#pragma mark + private

/**
 *  application documents directory
 *
 *  @return application documents directory path
 */
+ (NSString*)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

/**
 *  image path for ID
 *
 *  @param imageID image ID
 *
 *  @return image path
 */
+ (NSString*)pathForImageID:(NSString*)imageID {
    NSString* path = [[[self documentsDirectory] stringByAppendingPathComponent:imageID] stringByAppendingPathExtension:@"png"];
    return path;
}


@end
