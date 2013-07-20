//
//  UIFont+Graph.m
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//
#import "UIFont+Graph.h"

#define WM_DEF_FONT_NAME @"HelveticaNeue-UltraLight"

@implementation UIFont (Graph)

+ (UIFont *)wmDefaultFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:WM_DEF_FONT_NAME size:size];
}

+ (UIFont *)wmDefaultItalicFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:WM_DEF_FONT_NAME"Italic" size:size];
}

@end
