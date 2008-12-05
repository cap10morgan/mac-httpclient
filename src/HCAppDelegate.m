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

@implementation HCAppDelegate

+ (void)initialize {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultValues" ofType:@"plist"];
    id defaultValues = [NSDictionary dictionaryWithContentsOfFile:path];
    
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.preferencesWindowController = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)n {
    
}


#pragma mark -
#pragma mark Actions

- (IBAction)showPreferences:(id)sender {
    self.preferencesWindowController = [[[HCPreferencesWindowController alloc] init] autorelease];
    [preferencesWindowController showWindow:self];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(windowWillClose:) 
                                                 name:NSWindowWillCloseNotification 
                                               object:[preferencesWindowController window]];
}


- (void)windowWillClose:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[n object]];
    [[preferencesWindowController retain] autorelease];
    self.preferencesWindowController = nil;
}

@synthesize preferencesWindowController;
@end
