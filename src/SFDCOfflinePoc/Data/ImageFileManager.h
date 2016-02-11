//
//  ImageFileManager.h
//  SFDCOfflinePoc
//
//  Created by TCCODER on 2/2/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Helper class for images storing
 */
@interface ImageFileManager : UIView

/**
 *  stores image with specified ID
 *
 *  @param image   image
 *  @param imageID image ID
 */
+ (void)storeImage:(UIImage*)image withID:(NSString*)imageID;

/**
 *  loads image with specified ID
 *
 *  @param imageID image ID
 *
 *  @return image
 */
+ (UIImage*)loadImageWithID:(NSString*)imageID;

/**
 *  deletes image with specified ID
 *
 *  @param imageID image ID
 */
+ (void)deleteImageWithID:(NSString*)imageID;

@end
