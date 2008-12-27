//
//  NSString+TDParseKitAdditions.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 11/5/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "NSString+TDParseKitAdditions.h"

@implementation NSString (TDParseKitAdditions)

- (NSString *)stringByRemovingFirstAndLastCharacters {
    if (self.length < 2) {
        return self;
    } else {
        return [self substringWithRange:NSMakeRange(1, self.length - 2)];
    }
}

@end
