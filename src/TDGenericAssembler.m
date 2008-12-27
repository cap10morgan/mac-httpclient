//
//  TDGenericAssembler.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/22/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "TDGenericAssembler.h"
#import "NSArray+TDParseKitAdditions.h"
#import <TDParseKit/TDParseKit.h>

@interface TDGenericAssembler ()
- (void)workOnProductionNamed:(NSString *)name withAssembly:(TDAssembly *)a;
- (void)appendAttributedStringForObjects:(NSArray *)objs withAttrs:(id)attrs;
- (void)consumeWhitespaceFrom:(TDAssembly *)a;

@property (nonatomic, retain) NSString *prefix;
@property (nonatomic, retain) NSString *suffix;
@end

@implementation TDGenericAssembler

- (id)init {
    self = [super init];
    if (self) {
        self.displayString = [[[NSMutableAttributedString alloc] initWithString:@"" attributes:nil] autorelease];
        self.productionNames = [NSMutableDictionary dictionary];
        self.defaultProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSColor blackColor], NSForegroundColorAttributeName,
                                  [NSColor whiteColor], NSBackgroundColorAttributeName,
                                  [NSFont fontWithName:@"Monaco" size:11.0], NSFontAttributeName,
                                  nil];
        self.prefix = @"workOn";
        self.suffix = @"Assembly:";
    }
    return self;
}


- (void)dealloc {
    self.attributes = nil;
    self.defaultProperties = nil;
    self.productionNames = nil;
    self.displayString = nil;
    self.prefix = nil;
    self.suffix = nil;
    [super dealloc];
}


- (BOOL)respondsToSelector:(SEL)sel {
    return YES;
//    NSString *selName = NSStringFromSelector(sel);
//    if ([selName hasPrefix:@"workOn"]) {
//        return YES; //!parsing;
//    }
//    return [super respondsToSelector:sel];
}


- (id)performSelector:(SEL)sel withObject:(id)obj {
    NSString *selName = NSStringFromSelector(sel);
    
//    if ([selName hasPrefix:prefix] && [selName hasSuffix:suffix]) {
        
        NSString *productionName = [productionNames objectForKey:selName];
        if (!productionName) {
            NSUInteger prefixLen = prefix.length;
            NSInteger c = ((NSInteger)[selName characterAtIndex:prefixLen]) + 32; // lowercase
            NSRange r = NSMakeRange(prefixLen + 1, selName.length - (prefixLen + suffix.length + 1 /*:*/));
            productionName = [NSString stringWithFormat:@"%C%@", c, [selName substringWithRange:r]];
            [productionNames setObject:productionName forKey:selName];
        }
        
        [self workOnProductionNamed:productionName withAssembly:obj];
//    } else {
//        [super performSelector:sel withObject:obj];
//    }
    return nil;
}


- (void)workOnProductionNamed:(NSString *)name withAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    if (!tok) return;
    
    id props = [attributes objectForKey:name];
    if (!props) {
        props = defaultProperties;
    }

    [self consumeWhitespaceFrom:a];
    [self appendAttributedStringForObjects:[NSArray arrayWithObject:tok] withAttrs:props];
}


- (void)appendAttributedStringForObjects:(NSArray *)objs withAttrs:(id)attrs {
    for (id obj in objs) {
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:[obj stringValue] attributes:attrs];
        [displayString appendAttributedString:as];
        [as release];
    }
}


- (void)consumeWhitespaceFrom:(TDAssembly *)a {
    NSMutableArray *whitespaceToks = nil;
    TDToken *tok = nil;
    while (1) {
        tok = [a pop];
        if (TDTokenTypeWhitespace == tok.tokenType) {
            if (!whitespaceToks) {
                whitespaceToks = [NSMutableArray array];
            }
            [whitespaceToks addObject:tok];
        } else {
            [a push:tok];
            break;
        }
    }
    
    if (whitespaceToks) {
        whitespaceToks = [whitespaceToks reversedMutableArray];
        [self appendAttributedStringForObjects:whitespaceToks withAttrs:nil];
    }
}

@synthesize attributes;
@synthesize defaultProperties;
@synthesize productionNames;
@synthesize displayString;
@synthesize prefix;
@synthesize suffix;
@end
