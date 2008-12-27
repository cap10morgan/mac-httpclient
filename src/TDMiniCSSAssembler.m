//
//  TDMiniCSSAssembler.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/23/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "TDMiniCSSAssembler.h"
#import "NSString+TDParseKitAdditions.h"
#import <TDParseKit/TDParseKit.h>

@interface TDMiniCSSAssembler ()
- (void)gatherPropertiesIn:(id)props;
@end

@implementation TDMiniCSSAssembler

- (id)init {
    self = [super init];
    if (self) {
        self.attributes = [NSMutableDictionary dictionary];
        self.paren = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"(" floatValue:0.0];
        self.curly = [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:@"{" floatValue:0.0];
    }
    return self;
}


- (void)dealloc {
    self.attributes = nil;
    self.paren = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Assembler Callbacks

//    @start      = ruleset*;
//    ruleset     = selector '{' decls '}'.discard;
//    selector    = LowercaseWord;            // forcing selectors to be lowercase words for use in a future syntax-highlight framework where i want that
//    decls       = Empty | actualDecls;
//    actualDecls = decl decl*;
//    decl        = property ':'.discard expr ';'.discard?;
//    property    = 'color' | 'background-color' | 'font-family' | 'font-size';
//    expr        = pixelValue | rgb | string | constants;
//    pixelValue  = Num 'px'.discard;
//    rgb         = 'rgb'.discard '(' Num ','.discard Num ','.discard Num ')'.discard;
//    string      = QuotedString;
//    constants   = 'bold' | 'normal' | 'italic';

- (void)workOnPropertyAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    [a push:tok.stringValue];
}


- (void)workOnStringAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    [a push:[tok.stringValue stringByRemovingFirstAndLastCharacters]];
}


- (void)workOnConstantAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    [a push:tok.stringValue];
}


- (void)workOnNumAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)workOnPixelValueAssembly:(TDAssembly *)a {
    TDToken *tok = [a pop];
    [a push:[NSNumber numberWithFloat:tok.floatValue]];
}


- (void)workOnRgbAssembly:(TDAssembly *)a {
    NSArray *objs = [a objectsAbove:paren];
    [a pop]; // discard '('
    CGFloat blue  = [[objs objectAtIndex:0] floatValue]/255.0;
    CGFloat green = [[objs objectAtIndex:1] floatValue]/255.0;
    CGFloat red   = [[objs objectAtIndex:2] floatValue]/255.0;
    [a push:[NSColor colorWithDeviceRed:red green:green blue:blue alpha:1.0]];
}


- (void)workOnActualDeclsAssembly:(TDAssembly *)a {
    id d = [NSMutableDictionary dictionary];
    NSArray *objs = [a objectsAbove:curly];
    [a pop]; // discard curly

    NSInteger i = 0;
    NSInteger count = objs.count;
    for ( ; i < count - 1; i++) {
        id propVal = [objs objectAtIndex:i];
        id propName = [objs objectAtIndex:++i];
        [d setObject:propVal forKey:propName];
    }
    
    [a push:d];
}


- (void)workOnRulesetAssembly:(TDAssembly *)a {
    id props = [a pop];
    [self gatherPropertiesIn:props];

    for (TDToken *selectorTok in [a objectsAbove:nil]) {
        NSString *selector = selectorTok.stringValue;
        [attributes setObject:props forKey:selector];
    }
}


- (void)gatherPropertiesIn:(id)props {
    NSColor *color = [props objectForKey:@"color"];
    if (!color) {
        color = [NSColor blackColor];
    }
    [props setObject:color forKey:NSForegroundColorAttributeName];
    [props removeObjectForKey:@"color"];

    color = [props objectForKey:@"background-color"];
    if (!color) {
        color = [NSColor whiteColor];
    }
    [props setObject:color forKey:NSBackgroundColorAttributeName];
    [props removeObjectForKey:@"background-color"];
    
    NSString *fontFamily = [props objectForKey:@"font-family"];
    if (!fontFamily.length) {
        fontFamily = @"Monaco";
    }
    
    CGFloat fontSize = [[props objectForKey:@"font-size"] doubleValue];
    if (fontSize < 9.0) {
        fontSize = 9.0;
    }
    
    NSFont *font = [NSFont fontWithName:fontFamily size:fontSize];
    [props setObject:font forKey:NSFontAttributeName];
    [props removeObjectForKey:@"font-family"];
    [props removeObjectForKey:@"font-size"];
}

@synthesize attributes;
@synthesize paren;
@synthesize curly;
@end


//- (NSUInteger)hexValueFor:(NSString *)inStr {
//    NSUInteger i = [[inStr substringWithRange:NSMakeRange(0, 1)] integerValue];
//    i = i *= 16;
//    i += [[inStr substringWithRange:NSMakeRange(1, 1)] integerValue];
//    return i;
//}
//
//- (void)workOnHexcolorAssembly:(TDAssembly *)a {
//    TDToken *tok = [a pop];
//    NSString *s = tok.stringValue;
//    NSColor *color = nil;
//    
//    if (6 == s.length) {
//        NSString *redStr   = [s substringWithRange:NSMakeRange(0, 2)];
//        NSString *greenStr = [s substringWithRange:NSMakeRange(2, 2)];
//        NSString *blueStr  = [s substringWithRange:NSMakeRange(4, 2)];
//        
//        NSUInteger red   = [self hexValueFor:redStr];
//        NSUInteger green = [self hexValueFor:greenStr];
//        NSUInteger blue  = [self hexValueFor:blueStr];
//        
//        color = [NSColor colorWithDeviceRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
//    } else {
//        color = [NSColor magentaColor]; // signals incorrect value in stylesheet
//    }
//    [a push:color];
//}
