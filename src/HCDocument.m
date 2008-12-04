//
//  HCDocument.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCDocument.h"
#import "HCWindowController.h"

@implementation HCDocument

- (id)init {
    self = [super init];
    if (self) {
        // this must be created in -init rather than -makeWindowControllers so it is available in -readData:ofType:error:
        self.windowController = [[[HCWindowController alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.windowController = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument

- (void)makeWindowControllers {
    [self addWindowController:windowController];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSData *result = nil;
    @try {
        id dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setObject:[[windowController window] stringWithSavedFrame] forKey:@"windowFrameString"];
        [dict setObject:[NSNumber numberWithBool:windowController.isBodyShown] forKey:@"bodyShown"];
        
        id cmd = [NSMutableDictionary dictionaryWithDictionary:windowController.command];
        [cmd setObject:@"" forKey:@"rawRequest"];
        [cmd setObject:@"" forKey:@"rawResponse"];
        
        [dict setObject:cmd forKey:@"command"];
        [dict setObject:windowController.recentURLStrings forKey:@"recentURLStrings"];
        [dict setObject:[windowController.headersController arrangedObjects] forKey:@"headers"];
        
        result = [NSKeyedArchiver archivedDataWithRootObject:dict];
        if (!result) [NSException raise:@"UnknownError" format:nil];
    } @catch (NSException *e) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:[e userInfo]];
    }
    return result;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result = YES;
    @try {
        id dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (!dict) [NSException raise:@"UnknownError" format:nil];
        
        [[windowController window] setFrameFromString:[dict objectForKey:@"windowFrameString"]];
        windowController.bodyShown = [[dict objectForKey:@"bodyShown"] boolValue];
        windowController.command = [dict objectForKey:@"command"];
        windowController.recentURLStrings = [dict objectForKey:@"recentURLStrings"];
        [windowController.headersController addObjects:[dict objectForKey:@"headers"]];
    } @catch (NSException *e) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:[e userInfo]];
        result = NO;
    }
    return result;
}

@synthesize windowController;
@end
