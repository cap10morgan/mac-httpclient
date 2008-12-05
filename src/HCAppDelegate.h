//
//  HCAppDelegate.h
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *HCPlaySuccessFailureSoundsKey;
extern NSString *HCWrapRequestResponseTextKey;
extern NSString *HCSyntaxHighlightRequestResponseTextKey;

extern NSString *HCWrapRequestResponseTextChangedNotification;

@class HCPreferencesWindowController;

@interface HCAppDelegate : NSDocumentController {
    HCPreferencesWindowController *preferencesWindowController;
}
- (IBAction)showPreferences:(id)sender;

@property (nonatomic, retain) HCPreferencesWindowController *preferencesWindowController;
@end
