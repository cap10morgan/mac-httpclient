//
//  HCAppDelegate.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCAppDelegate.h"
#import "HCPreferencesWindowController.h"

NSString *HCPlaySuccessFailureSoundsKey = @"HCPlaySuccessFailureSounds";
NSString *HCWrapRequestResponseTextKey = @"HCWrapRequestResponseText";
NSString *HCSyntaxHighlightRequestResponseTextKey = @"HCSyntaxHighlightRequestResponseText";

NSString *HCWrapRequestResponseTextChangedNotification = @"HCWrapRequestResponseTextChangedNotification";
NSString *HCSyntaxHighlightRequestResponseTextChangedNotification = @"HCSyntaxHighlightRequestResponseTextChangedNotification";

@implementation HCAppDelegate

+ (void)initialize {
    if ([HCAppDelegate class] == self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultValues" ofType:@"plist"];
        id defaultValues = [NSDictionary dictionaryWithContentsOfFile:path];
        
        [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    }
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark NSApplicationDelegate

//- (void)applicationDidFinishLaunching:(NSNotification *)n {
//    
//}


#pragma mark -
#pragma mark Actions

- (IBAction)showPreferences:(id)sender {
    [[HCPreferencesWindowController instance] showWindow:self];
}

@end
