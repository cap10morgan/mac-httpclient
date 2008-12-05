//
//  TDSignificantWhitespaceState.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 7/14/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TDParseKit/TDWhitespaceState.h>
#import <TDParseKit/TDToken.h>

static const NSInteger TDTT_WHITESPACE = 5;

@interface TDToken (TDSignificantWhitespaceStateAdditions)
@property (nonatomic, readonly, getter=isWhitespace) BOOL whitespace;
@end

@interface TDSignificantWhitespaceState : TDWhitespaceState {

}
@end
