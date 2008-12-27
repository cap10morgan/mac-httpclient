//
//  TDMiniCSSAssembler.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/23/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDToken;

@interface TDMiniCSSAssembler : NSObject {
    NSMutableDictionary *attributes;
    TDToken *paren;
    TDToken *curly;
}
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, retain) TDToken *paren;
@property (nonatomic, retain) TDToken *curly;
@end
