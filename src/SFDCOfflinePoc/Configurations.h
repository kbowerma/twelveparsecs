//
//  Configurations.h
//
//  Created by TCCODER on 1/31/16.
//  Copyright (c) 2016 Topcoder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 @class Configurations
 @discussion This class loads configurable constants from a config.plist
 
 @author TCCODER
 @version 1.0
 */

@interface Configurations : NSObject

/**
 *  pdf name
 *
 *  @return pdf name
 */
+ (NSString*)pdfName;

/**
 *  pdf height
 *
 *  @return pdf height
 */
+ (CGFloat)pdfHeight;

/**
 *  pdf width
 *
 *  @return pdf width
 */
+ (CGFloat)pdfWidth;

/**
 *  pdf content padding 
 *
 *  @return pdf padding
 */
+ (CGFloat)pdfPadding;

/**
 *  pdf row height
 *
 *  @return pdf row height
 */
+ (CGFloat)pdfRowHeight;

/**
 *  pdf row header height
 *
 *  @return pdf row header height
 */
+ (CGFloat)pdfHeaderHeight;

/**
 *  pdf font size for text
 *
 *  @return pdf font size
 */
+ (CGFloat)pdfFontSize;

/**
 *  max number of failed pin attempts
 *
 *  @return max number of failed pin attempts
 */
+ (NSInteger)maxAttempts;


@end
