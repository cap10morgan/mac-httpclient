//
//  HCWindowController.h
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol HTTPService;

@interface HCWindowController : NSWindowController {
    IBOutlet NSComboBox *URLComboBox;
    IBOutlet NSTableView *headersTable;
    IBOutlet NSTextView *bodyTextView;
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextView *requestTextView;
    IBOutlet NSTextView *responseTextView;
    IBOutlet NSScrollView *requestScrollView;
    IBOutlet NSScrollView *responseScrollView;
    IBOutlet NSArrayController *headersController;
    id <HTTPService>service;
    
    NSMutableArray *recentURLStrings;
    NSMutableDictionary *command;
    BOOL busy;
    BOOL bodyShown;
    
    NSArray *headerNames;
    NSDictionary *headerValues;
    
    // HTTPAuth
    IBOutlet NSPanel *httpAuthSheet;
    IBOutlet NSTextField *authUsernameTextField;
    IBOutlet NSTextField *authPasswordTextField;
    
    NSString *authUsername;
    NSString *authPassword;
    NSString *authMessage;
    BOOL rememberAuthPassword;    
}
- (IBAction)openLocation:(id)sender;
- (IBAction)execute:(id)sender;
- (IBAction)clear:(id)sender;

@property (nonatomic, retain) id <HTTPService>service;
@property (nonatomic, retain) NSArrayController *headersController;
@property (nonatomic, retain) NSMutableArray *recentURLStrings;

@property (nonatomic, retain) id command;
@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, getter=isBodyShown) BOOL bodyShown;

@property (nonatomic, retain) NSArray *headerNames;
@property (nonatomic, retain) NSDictionary *headerValues;

@property (nonatomic, copy) NSString *authUsername;
@property (nonatomic, copy) NSString *authPassword;
@property (nonatomic, copy) NSString *authMessage;
@property (nonatomic) BOOL rememberAuthPassword;
@end