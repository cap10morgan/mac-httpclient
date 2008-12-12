//
//  HCWindowController.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HCWindowController.h"
#import "HCWindowController+HTTPAuth.h"
#import "HCAppDelegate.h"
#import "HCPreferencesWindowController.h"
#import "HTTPService.h"
#import "TDSourceCodeTextView.h"
#import "TDHtmlSyntaxHighlighter.h"

@interface HCWindowController ()
- (BOOL)shouldPlaySounds;
- (void)playSuccessSound;
- (void)playErrorSound;
- (void)wrapTextChanged:(NSNotification *)n;
- (void)syntaxHighlightTextChanged:(NSNotification *)n;
- (void)setupFonts;
- (void)setupHeadersTable;
- (void)setupBodyTextView;
- (NSFont *)miniSystemFont;
- (NSComboBoxCell *)comboBoxCellWithTag:(int)tag;
- (BOOL)isNameRequiringTodaysDateString:(NSString *)name;
- (NSString *)todaysDateString;
- (void)changeSizeForBody;
- (void)renderGutters;
- (void)updateTextWrapInTextView:(NSTextView *)textView withinScrollView:(NSScrollView *)scrollView;
- (NSAttributedString *)attributedStringForString:(NSString *)s;
- (void)updateSoureCodeViews;
- (void)cleanUserAgentStringsInHeaders:(NSArray *)headers;
- (void)requestCompleted:(id)cmd;
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
        
        self.syntaxHighlighter = [[[TDHtmlSyntaxHighlighter alloc] initWithAttributesForDarkBackground:YES] autorelease];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(wrapTextChanged:)
                                                     name:HCWrapRequestResponseTextChangedNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(syntaxHighlightTextChanged:)
                                                     name:HCSyntaxHighlightRequestResponseTextChangedNotification 
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.service = nil;
    self.headersController = nil;
    self.recentURLStrings = nil;
    self.command = nil;
    self.highlightedRawRequest = nil;
    self.highlightedRawResponse = nil;
    self.headerNames = nil;
    self.headerValues = nil;
    self.syntaxHighlighter = nil;
    self.authUsername = nil;
    self.authPassword = nil;
    self.authMessage = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self setupFonts];
    [self setupHeadersTable];
    [self setupBodyTextView];
    [self updateSoureCodeViews];
    
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
    
//    if (NSNotFound == [URLString rangeOfString:@"."].location) {
//        URLString = [NSString stringWithFormat:@"%@.com", URLString];
//        [command setObject:URLString forKey:@"URLString"];
//    }
    
    
    NSArray *headers = [headersController arrangedObjects];
    
    // trim out the user-friendly UA names in any user-agent string header values
    [self cleanUserAgentStringsInHeaders:headers];
    
    [command setObject:headers forKey:@"headers"];
    [service sendHTTPRequest:command];
    
    if (![recentURLStrings containsObject:[command objectForKey:@"URLString"]]) {
        [recentURLStrings addObject:[command objectForKey:@"URLString"]];
    }
}


- (IBAction)clear:(id)sender {
    [command setObject:@"" forKey:@"rawRequest"];
    [command setObject:@"" forKey:@"rawResponse"];
    [self renderGutters];
}


- (IBAction)showRequest:(id)sender {
    [tabView selectTabViewItemAtIndex:0];
}


- (IBAction)showResponse:(id)sender {
    [tabView selectTabViewItemAtIndex:1];
}


#pragma mark -
#pragma mark Private

- (BOOL)shouldPlaySounds {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:HCPlaySuccessFailureSoundsKey] boolValue];
}


- (void)playSuccessSound {
    if ([self shouldPlaySounds]) {
        [[NSSound soundNamed:@"Hero"] play];
    }
}


- (void)playErrorSound {
    if ([self shouldPlaySounds]) {
        [[NSSound soundNamed:@"Basso"] play];
    }
}


- (void)wrapTextChanged:(NSNotification *)n {
    [self updateTextWrapInTextView:requestTextView withinScrollView:requestScrollView];
    [self updateTextWrapInTextView:responseTextView withinScrollView:responseScrollView];
    [self renderGutters];
}


- (void)syntaxHighlightTextChanged:(NSNotification *)n {
    [self updateSoureCodeViews];
}


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
    NSComboBoxCell *cbCell = [[[NSComboBoxCell alloc] init] autorelease];
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


- (void)renderGutters {
    [requestTextView renderGutter];
    [responseTextView renderGutter];
}


- (void)updateTextWrapInTextView:(NSTextView *)textView withinScrollView:(NSScrollView *)scrollView {
    BOOL wrap = [[NSUserDefaults standardUserDefaults] boolForKey:HCWrapRequestResponseTextKey];
    
    if (wrap) {
        NSSize s = [scrollView bounds].size;
        s.height = [[textView textContainer] containerSize].height;
        [scrollView setHasHorizontalScroller:NO];
        [[textView textContainer] setContainerSize:s];
        s.width -= 15; // subtract for width of vert scroll gutter? neccesary to prevent annoying slight horz scrolling
        [textView setFrameSize:s];
        [[textView textContainer] setWidthTracksTextView:YES];
        [textView setHorizontallyResizable:NO];
    } else {
        [scrollView setHasHorizontalScroller:YES];
        [textView setHorizontallyResizable:YES];
        [[textView textContainer] setContainerSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
        [[textView textContainer] setWidthTracksTextView:NO];    
        [textView setMaxSize:NSMakeSize(MAXFLOAT, MAXFLOAT)];
    }

    NSRange r = NSMakeRange(0, textView.string.length);
    [[[textView textContainer] layoutManager] invalidateDisplayForCharacterRange:r];
    [textView setNeedsDisplay:YES];
}


- (BOOL)isSyntaxHighlightOn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:HCSyntaxHighlightRequestResponseTextKey];
}


- (NSAttributedString *)attributedStringForString:(NSString *)s {
    if ([self isSyntaxHighlightOn]) {
        return [syntaxHighlighter attributedStringForString:s];
    } else {
        id attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSColor blackColor], NSForegroundColorAttributeName,
                    [NSFont fontWithName:@"Monaco" size:11.], NSFontAttributeName,
                    nil];
        return [[[NSAttributedString alloc] initWithString:s attributes:attrs] autorelease];
    }
}


- (void)updateSoureCodeViews {
    if (command) {
        NSString *rawRequest = [command objectForKey:@"rawRequest"];
        if (rawRequest.length) {
            self.highlightedRawRequest = [self attributedStringForString:rawRequest];
        }
        NSString *rawResponse = [command objectForKey:@"rawResponse"];
        if (rawResponse.length) {
            self.highlightedRawResponse = [self attributedStringForString:rawResponse];
        }
    }

    NSColor *bgColor = [self isSyntaxHighlightOn] ? [NSColor colorWithDeviceRed:30./255. green:30./255. blue:36./255. alpha:1.] : [NSColor whiteColor];
    NSColor *ipColor = [self isSyntaxHighlightOn] ? [NSColor whiteColor] : [NSColor blackColor];
    
    [requestTextView setBackgroundColor:bgColor];
    [responseTextView setBackgroundColor:bgColor];
    [requestTextView setInsertionPointColor:ipColor];
    [responseTextView setInsertionPointColor:ipColor];
}


// trim out the user-friendly UA names in any user-agent string header values
- (void)cleanUserAgentStringsInHeaders:(NSArray *)headers {
    for (id headerDict in headers) {
        if (NSOrderedSame == [[headerDict objectForKey:@"name"] caseInsensitiveCompare:@"user-agent"]) {
            NSString *value = [headerDict objectForKey:@"value"];
            NSString *marker = @" --- ";
            NSRange r = [value rangeOfString:marker];
            if (NSNotFound != r.location) {
                value = [value substringFromIndex:r.location + marker.length];
                [headerDict setObject:value forKey:@"value"];
            }
        }
    }
}


- (void)requestCompleted:(id)cmd {
    if ([[command objectForKey:@"followRedirects"] boolValue]) {
        [URLComboBox setStringValue:[cmd objectForKey:@"finalURLString"]];
    }
    
    self.command = cmd;
    [self updateSoureCodeViews];
    [self renderGutters];
    self.busy = NO;
    [self openLocation:self]; // focus the url bar    
}


#pragma mark -
#pragma mark HTTPServiceDelegate

- (void)HTTPService:(id <HTTPService>)service didRecieveResponse:(NSString *)rawResponse forRequest:(id)cmd {
    [self playSuccessSound];
    [self requestCompleted:cmd];
}


- (void)HTTPService:(id <HTTPService>)service request:(id)cmd didFail:(NSString *)msg {
    [self playErrorSound];
    [self requestCompleted:cmd];
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
#pragma mark NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [self renderGutters];
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
@synthesize highlightedRawRequest;
@synthesize highlightedRawResponse;
@synthesize busy;
@synthesize bodyShown;
@synthesize headerNames;
@synthesize headerValues;
@synthesize syntaxHighlighter;
@synthesize authUsername;
@synthesize authPassword;
@synthesize authMessage;
@synthesize rememberAuthPassword;
@end
