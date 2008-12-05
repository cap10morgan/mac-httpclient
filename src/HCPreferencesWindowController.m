//
//  HCPreferencesWindowController.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCPreferencesWindowController.h"
#import "HCAppDelegate.h"

@implementation HCPreferencesWindowController

- (id)init {
    self = [super initWithWindowNibName:@"HCPreferencesWindow"];
    if (self) {
        
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}


- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [[self window] center];
}


- (void)wrapTextChanged:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:HCWrapRequestResponseTextChangedNotification object:nil];
}

@end
