//
//  HCSyntaxHighlightController.m
//  HTTPClient
//
//  Created by Todd Ditchendorf on 12/26/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCSyntaxHighlightController.h"

@interface HCSyntaxHighlightController ()
- (NSAttributedString *)parseHeaders:(NSString *)s getMIMEType:(NSString **)MIMEType;
@property (nonatomic, retain) NSDictionary *headerNameAttributes;
@property (nonatomic, retain) NSDictionary *headerValueAttributes;
@property (nonatomic, retain) NSDictionary *textAttributes;
@end

@implementation HCSyntaxHighlightController

- (id)init {
    self = [super init];
    if (self) {
        NSFont *monacoFont = [NSFont fontWithName:@"Monaco" size:11.];
        
        NSColor *textColor = nil;
        NSColor *attrNameColor = nil;
        NSColor *attrValueColor = nil;
        
        if (YES /*isDarkBG*/) {
            textColor = [NSColor whiteColor];
            attrNameColor = [NSColor colorWithDeviceRed:.33 green:.45 blue:.48 alpha:1.];
            attrValueColor = [NSColor colorWithDeviceRed:.77 green:.18 blue:.20 alpha:1.];
        } else {
            textColor = [NSColor blackColor];
            attrNameColor = [NSColor colorWithDeviceRed:0. green:0. blue:.75 alpha:1.];
            attrValueColor = [NSColor colorWithDeviceRed:.75 green:0. blue:0. alpha:1.];
        }

        self.headerNameAttributes   = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrNameColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.headerValueAttributes  = [NSDictionary dictionaryWithObjectsAndKeys:
                                       attrValueColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
        self.textAttributes         = [NSDictionary dictionaryWithObjectsAndKeys:
                                       textColor, NSForegroundColorAttributeName,
                                       monacoFont, NSFontAttributeName,
                                       nil];
    }
    return self;
}


- (void)dealloc {
    self.grammarNamesForMIMETypes = nil;
    self.headerNameAttributes = nil;
    self.headerValueAttributes = nil;
    self.textAttributes = nil;
    [super dealloc];
}


- (NSMutableDictionary *)grammarNamesForMIMETypes {
    if (!grammarNamesForMIMETypes) {
        self.grammarNamesForMIMETypes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                      @"javascript", @"text/javascript",
//                                      @"javascript", @"application/javascript",
                                      @"html", @"text/html",
                                      @"html", @"application/xml",
                                      @"html", @"application/xhtml+xml",
                                      @"html", @"application/xhtml",
//                                      @"css", @"text/css",
                                      @"json", @"application/json",
                                      nil];
    }
    return grammarNamesForMIMETypes;
}


- (NSAttributedString *)highlightedStringForString:(NSString *)s {
    
    NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] init] autorelease];
    NSString *MIMEType = nil;
    
    // preprocess/highlight headers
    NSRange r = [s rangeOfString:@"\r\n\r\n"];
    if (NSNotFound != r.location) {
        NSAttributedString *highlightedHeaders = [self parseHeaders:[s substringToIndex:r.location] getMIMEType:&MIMEType];
        [result appendAttributedString:highlightedHeaders];
        s = [s substringFromIndex:r.location + r.length];
    }
    
    NSInteger lengthOfHeaders = result.length;

    // if there's a body, highlight it too
    if (s.length) {
        
        // TODO remove
        MIMEType = @"text/html";
        
        // if you have a mimetype, highlight accordingly
        if (MIMEType.length) {
            // get grammar name for MIMEType ex: 'xml' for 'application/xml'
            NSString *grammarName = [self.grammarNamesForMIMETypes objectForKey:[MIMEType lowercaseString]];
            
            if (grammarName.length) {
                // highlight if a parser exists for that grammar
                [result appendAttributedString:[super highlightedStringForString:s ofGrammar:grammarName]];
            }
        } 

        // if that didnt work for some reason, just return a white string
        if (result.length == lengthOfHeaders) {
            NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:s attributes:textAttributes];
            [result appendAttributedString:as];
            [as release];
        }
    }

    return result;
}


- (NSAttributedString *)parseHeaders:(NSString *)s getMIMEType:(NSString **)MIMEType {
    NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] init] autorelease];
    NSAttributedString *as = nil;

    NSArray *lines = [s componentsSeparatedByString:@"\r\n"];
    for (NSString *line in lines) {
        NSRange r = [line rangeOfString:@":"];
        if (NSNotFound == r.location) { // handle response status line or malformed header
            line = [NSString stringWithFormat:@"%@\r\n", line];
            as = [[NSAttributedString alloc] initWithString:line attributes:textAttributes];
            [result appendAttributedString:as];
            [as release];
        } else {
            NSInteger i = r.location + 1;
            NSString *name = [line substringToIndex:i];
            NSString *value = [NSString stringWithFormat:@"%@\r\n", [line substringFromIndex:i]];
            
            if (!(*MIMEType) &&  NSOrderedSame == [name caseInsensitiveCompare:@"mime-type"]) {
                (*MIMEType) = value;
            }
            
            as = [[NSAttributedString alloc] initWithString:name attributes:headerNameAttributes];
            [result appendAttributedString:as];
            [as release];

            as = [[NSAttributedString alloc] initWithString:value attributes:headerValueAttributes];
            [result appendAttributedString:as];
            [as release];
        }
    }
    as = [[NSAttributedString alloc] initWithString:@"\r\n" attributes:textAttributes];
    [result appendAttributedString:as];
    [as release];
    
    return result;
}

@synthesize grammarNamesForMIMETypes;
@synthesize headerNameAttributes;
@synthesize headerValueAttributes;
@synthesize textAttributes;
@end
