//
//  HCSyntaxHighlightController.h
//  HTTPClient
//
//  Created by Todd Ditchendorf on 12/26/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDSyntaxHighlightController.h"

// TDSyntaxHighlightController subclass used to highlight http headers separately,
// then pass the message body to the superclass for normal syntax highlight processing.
// This class is designed specifically for HTTP Client.app, whereas TDSyntaxHighlightController is for general use.

// for now, it does HTTP header highlighting manually cuz its so simple, but that will prolly also be moved to
// TDParseKit-based parsing eventually

@interface HCSyntaxHighlightController : TDSyntaxHighlightController {
    NSMutableDictionary *grammarNamesForMIMETypes;
    NSDictionary *headerNameAttributes;
    NSDictionary *headerValueAttributes;
    NSDictionary *textAttributes;
}
- (NSAttributedString *)highlightedStringForString:(NSString *)s;

@property (nonatomic, retain) NSMutableDictionary *grammarNamesForMIMETypes;
@end
