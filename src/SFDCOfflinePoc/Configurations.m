//
//  Configurations.m
//
//  Created by TCCODER on 1/31/16.
//  Copyright (c) 2016 Topcoder. All rights reserved.
//

#import "Configurations.h"

/**
 *  configuration data
 */
static NSDictionary *config;

@implementation Configurations

+ (void)initialize {
    config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"]];
}

+ (NSString*)pdfName {
    return config[@"pdfName"];
}

+ (CGFloat)pdfHeight {
    return [config[@"pdfHeight"] floatValue];
}

+ (CGFloat)pdfWidth {
    return [config[@"pdfWidth"] floatValue];
}

+ (CGFloat)pdfPadding{
    return [config[@"pdfPadding"] floatValue];
}

+ (CGFloat)pdfRowHeight{
    return [config[@"pdfRowHeight"] floatValue];
}

+ (CGFloat)pdfHeaderHeight{
    return [config[@"pdfHeaderHeight"] floatValue];
}

+ (CGFloat)pdfFontSize {
    return [config[@"pdfFontSize"] floatValue];
}

+ (NSInteger)maxAttempts {
    return [config[@"maxAttempts"] integerValue];
}

@end
