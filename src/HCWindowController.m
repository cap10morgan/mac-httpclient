//
//  HCWindowController.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCWindowController.h"
#import "HCWindowController+HTTPAuth.h"
#import "HCPreferencesWindowController.h"
#import "HTTPService.h"
#import "TDSourceCodeTextView.h"

@interface HCWindowController ()
- (void)setupFonts;
- (void)setupHeadersTable;
- (void)setupBodyTextView;
- (NSFont *)miniSystemFont;
- (NSComboBoxCell *)comboBoxCellWithTag:(int)tag;
- (BOOL)isNameRequiringTodaysDateString:(NSString *)name;
- (NSString *)todaysDateString;
- (void)changeSizeForBody;
@end

@implementation HCWindowController

- (id)init {
    self = [super initWithWindowNibName:@"HCDocumentWindow"];
    if (self != nil) {
        self.service = [[[NSClassFromString(@"HTTPServiceCFNetworkImpl") alloc] initWithDelegate:self] autorelease];

        self.command = [NSMutableDictionary dictionary];
        [command setObject:@"GET" forKey:@"method"];

        self.recentURLStrings = [NSMutableArray array];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"HeaderNames" ofType:@"plist"];
        self.headerNames = [NSArray arrayWithContentsOfFile:path];
        
        path = [[NSBundle mainBundle] pathForResource:@"HeaderValues" ofType:@"plist"];
        self.headerValues = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return self;
}


- (void)dealloc {
    self.service = nil;
    self.headersController = nil;
    self.recentURLStrings = nil;
    self.command = nil;
    self.headerNames = nil;
    self.headerValues = nil;
    self.authUsername = nil;
    self.authPassword = nil;
    self.authMessage = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self setupFonts];
    [self setupHeadersTable];
    [self setupBodyTextView];
    
    [headersController addObserver:self
                        forKeyPath:@"arrangedObjects"
                           options:NSKeyValueObservingOptionOld
                           context:NULL];
    
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [[self document] updateChangeCount:NSChangeDone];
}


#pragma mark -
#pragma mark Actions

- (IBAction)openLocation:(id)sender {
    [[self window] makeFirstResponder:URLComboBox];
}


- (IBAction)execute:(id)sender {
    [self clear:self];
    
    NSString *URLString = [command objectForKey:@"URLString"];
    if (![URLString length]) {
        NSBeep();
        return;
    }
    
    self.busy = YES;
    
    if (![URLString hasPrefix:@"http://"] && ![URLString hasPrefix:@"https://"]) {
        URLString = [NSString stringWithFormat:@"http://%@", URLString];
        [command setObject:URLString forKey:@"URLString"];
    }
    
    if (NSNotFound == [URLString rangeOfString:@"."].location) {
        URLString = [NSString stringWithFormat:@"%@.com", URLString];
        [command setObject:URLString forKey:@"URLString"];
    }
    
    [command setObject:[headersController arrangedObjects] forKey:@"headers"];
    [service sendHTTPRequest:command];
    
    if (![recentURLStrings containsObject:[command objectForKey:@"URLString"]]) {
        [recentURLStrings addObject:[command objectForKey:@"URLString"]];
    }
}


- (IBAction)clear:(id)sender {
    [command setObject:@"" forKey:@"rawRequest"];
    [command setObject:@"" forKey:@"rawResponse"];
    [responseTextView renderGutter];
}


- (IBAction)completeAuth:(id)sender {
    //[NSApp endSheet:httpAuthSheet returnCode:[sender tag]];
    [NSApp stopModalWithCode:[sender tag]];
}


#pragma mark -
#pragma mark Private

- (void)setupFonts {
    NSFont *monaco = [NSFont fontWithName:@"Monaco" size:10.];
//    [bodyTextView setFont:monaco];
    [requestTextView setFont:monaco];
    [responseTextView setFont:monaco];
}


- (void)setupHeadersTable {
    [[headersTable tableColumnWithIdentifier:@"headerName"] setDataCell:[self comboBoxCellWithTag:0]];
    [[headersTable tableColumnWithIdentifier:@"headerValue"] setDataCell:[self comboBoxCellWithTag:1]];
    //[headersTable setIntercellSpacing:NSMakeSize(3, 3)];
}


- (void)setupBodyTextView {
    [bodyTextView setFont:[self miniSystemFont]];
}


- (NSFont *)miniSystemFont {
    return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
}


- (NSComboBoxCell *)comboBoxCellWithTag:(int)tag {
    NSComboBoxCell *cbCell = [[NSComboBoxCell alloc] init];
    [cbCell setEditable:YES];
    [cbCell setFocusRingType:NSFocusRingTypeNone];
    [cbCell setControlSize:NSSmallControlSize];
    [cbCell setFont:[self miniSystemFont]];
    [cbCell setUsesDataSource:YES];
    [cbCell setDataSource:self];
    [cbCell setTarget:self];
    [cbCell setAction:@selector(handleComboBoxTextChanged:)];
    [cbCell setTag:tag];
    [cbCell setNumberOfVisibleItems:12];
    return cbCell;
}


- (void)handleComboBoxTextChanged:(id)sender {
    NSInteger colIndex = [sender clickedColumn];
    NSMutableDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
    
    //NSLog(@"row: %i, col: %i",rowIndex,colIndex);
    if (0 == colIndex) { // name changed
        [header setObject:[sender stringValue] forKey:@"name"];
    } else { // value changed
        [header setObject:[sender stringValue] forKey:@"value"];
    }
}


- (BOOL)isNameRequiringTodaysDateString:(NSString *)name {
    return [name isEqualToString:@"if-modified-since"] 
        || [name isEqualToString:@"if-unmodified-since"] 
        || [name isEqualToString:@"if-range"];
}


- (NSString *)todaysDateString {
    NSCalendarDate *today = [NSCalendarDate date];
    // format: Sun, 06 Nov 1994 08:49:37 GMT
    [today setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [today descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S GMT"];
}


- (void)changeSizeForBody {
    CGFloat winHeight = [[self window] frame].size.height;
    NSRect tabFrame = [tabView frame];
    if (bodyShown) {
        tabFrame.size.height = winHeight - 308.0;
    } else {
        tabFrame.size.height = winHeight - 206.0;
    }
    [tabView setFrame:tabFrame];
    [tabView setNeedsDisplay:YES];    
}


#pragma mark -
#pragma mark HTTPServiceDelegate

- (void)HTTPService:(id <HTTPService>)service didRecieveResponse:(NSString *)rawResponse forRequest:(id)cmd {
    self.command = cmd;
    [responseTextView renderGutter];
    self.busy = NO;
}


- (void)HTTPService:(id <HTTPService>)service request:(id)cmd didFail:(NSString *)msg {
    [responseTextView renderGutter];
    NSBeep();
    self.busy = NO;
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [recentURLStrings count];
}


- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [recentURLStrings objectAtIndex:index];    
}


#pragma mark -
#pragma mark NSComboBoxCellDataSource

- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(NSInteger)index {
    BOOL isValueCell = [aComboBoxCell tag];
    if (isValueCell) {
        NSDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
        NSString *name = [[header objectForKey:@"name"] lowercaseString];
        
        if ([self isNameRequiringTodaysDateString:name]) {
            return [self todaysDateString];
        } else {
            return [[headerValues objectForKey:name] objectAtIndex:index];
        }
    } else {
        return [headerNames objectAtIndex:index];
    }
}


- (NSInteger)numberOfItemsInComboBoxCell:(NSComboBoxCell *)comboBoxCell {
    BOOL isValueCell = [comboBoxCell tag];
    if (isValueCell) {
        NSDictionary *header = [[headersController selectedObjects] objectAtIndex:0];
        NSString *name = [[header objectForKey:@"name"] lowercaseString];
        
        if ([self isNameRequiringTodaysDateString:name]) {
            return 1;
        } else {
            return [[headerValues objectForKey:name] count];
        }
    } else {
        return [headerNames count];
    }
}


#pragma mark -
#pragma mark Accessors

- (void)setBodyShown:(BOOL)yn {
    [self willChangeValueForKey:@"bodyShown"];
    bodyShown = yn;
    [self changeSizeForBody];
    [[self document] updateChangeCount:NSChangeDone];
    [self didChangeValueForKey:@"bodyShown"];
}


- (void)setCommand:(id)c {
    if (command != c) {
        [command autorelease];
        command = [c retain];
        
        [command addObserver:self forKeyPath:@"URLString" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"body" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"method" options:NSKeyValueObservingOptionNew context:NULL];
        [command addObserver:self forKeyPath:@"followRedirects" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

@synthesize service;
@synthesize headersController;
@synthesize recentURLStrings;
@synthesize command;
@synthesize busy;
@synthesize bodyShown;
@synthesize headerNames;
@synthesize headerValues;
@synthesize authUsername;
@synthesize authPassword;
@synthesize authMessage;
@synthesize rememberAuthPassword;
@end
