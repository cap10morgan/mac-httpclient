//
//  TDGenericAssembler.h
//  TDParseKit
//
//  Created by Todd Ditchendorf on 12/22/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDGenericAssembler : NSObject {
    NSMutableDictionary *attributes;
    NSMutableDictionary *defaultProperties;
    NSMutableDictionary *productionNames;
    NSMutableAttributedString *displayString;
    NSString *prefix;
    NSString *suffix;
}
@property (nonatomic, retain) NSMutableDictionary *attributes;
@property (nonatomic, retain) NSMutableDictionary *defaultProperties;
@property (nonatomic, retain) NSMutableDictionary *productionNames;
@property (nonatomic, retain) NSMutableAttributedString *displayString;
@end
