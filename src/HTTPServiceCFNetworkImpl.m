//
//  HTTPServiceCFNetworkImpl.m
//  HTTPClient
//
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "HTTPServiceCFNetworkImpl.h"

#define BUFSIZE 1024

@interface HTTPServiceCFNetworkImpl ()
- (void)doSendHTTPRequest;
- (void)success:(NSString *)rawResponse;
- (void)doSuccess:(NSString *)rawResponse;
- (void)failure:(NSString *)msg;
- (void)doFailure:(NSString *)msg;
@end


static NSString *getRawStringForHTTPMessageRef(CFHTTPMessageRef message) {
    NSData *data = (NSData *)CFHTTPMessageCopySerializedMessage(message);
    NSString *result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [data release];
    return result;
}


static CFHTTPMessageRef createHTTPMessageRef(HTTPServiceCFNetworkImpl *self, NSURL *URL, NSString *method, NSString *body, NSArray *headers) {

    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)method, (CFURLRef)URL, kCFHTTPVersion1_1);
    
    if ([body length]) {
        CFHTTPMessageSetBody(message, (CFDataRef)[body dataUsingEncoding:NSUTF8StringEncoding]);
    }
    
    for (id header in headers) {
        NSString *name = [header objectForKey:@"name"];
        NSString *value = [header objectForKey:@"value"];
        if ([name length] && [value length]) {
            CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)name, (CFStringRef)value);
        }
    }
    
    NSString *rawMessage = getRawStringForHTTPMessageRef(message);
    [self.command setObject:rawMessage forKey:@"rawRequest"];
    
    return message;
}


static CFHTTPMessageRef createResponseBySendingHTTPRequest(HTTPServiceCFNetworkImpl *self, CFHTTPMessageRef req, BOOL followRedirects) {
    CFHTTPMessageRef response = NULL;
    NSMutableData *responseBodyData = [NSMutableData data];
    
    CFReadStreamRef stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, req);
    CFBooleanRef autoredirect = followRedirects ? kCFBooleanTrue : kCFBooleanFalse;
    CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPShouldAutoredirect, autoredirect);
    CFReadStreamOpen(stream);    
    
    BOOL done = NO;
    while (!done) {
        UInt8 buf[BUFSIZE];
        CFIndex numBytesRead = CFReadStreamRead(stream, buf, BUFSIZE);
        if (numBytesRead < 0) {
            CFStreamError error = CFReadStreamGetError(stream);
            NSString *msg = [NSString stringWithFormat:@"Network Error. Domain: %d, Code: %d", error.domain, error.error];
            NSLog(msg);
            [self failure:msg];
            responseBodyData = nil;
            done = YES;
        } else if (numBytesRead == 0) {
            done = YES;
        } else {
            [responseBodyData appendBytes:buf length:numBytesRead];
        }
    }
    
    CFReadStreamClose(stream);
    NSInteger streamStatus = CFReadStreamGetStatus(stream);
        
    if (kCFStreamStatusError != streamStatus) {
        response = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
        CFHTTPMessageSetBody(response, (CFDataRef)responseBodyData);
    }
    
    if (stream) {
        CFRelease(stream);
        stream = NULL;
    }
    
    return response;
}


static BOOL isAuthChallengeForProxyStatusCode(NSInteger statusCode) {
    return (407 == statusCode);
}


static BOOL isAuthChallengeStatusCode(NSInteger statusCode) {
    return (401 == statusCode || isAuthChallengeForProxyStatusCode(statusCode));
}


static NSString *makeHTTPRequest(HTTPServiceCFNetworkImpl *self, id delegate, NSURL *URL, NSString *method, NSString *body, NSArray *headers, BOOL followRedirects, NSString **outFinalURLString) {
    NSString *result = nil;
    CFHTTPMessageRef request = createHTTPMessageRef(self, URL, method, body, headers);
    CFHTTPMessageRef response = NULL;
    CFHTTPAuthenticationRef auth = NULL;
    NSInteger count = 0;
    
    do {
        //    send request
        response = createResponseBySendingHTTPRequest(self, request, followRedirects);
        
        if (!response) {
            result = nil;
            goto leave;
        }
        
        NSURL *finalURL = (NSURL *)CFHTTPMessageCopyRequestURL(response);
        (*outFinalURLString) = [finalURL absoluteString];
        NSInteger responseStatusCode = CFHTTPMessageGetResponseStatusCode(response);
        
        if (!isAuthChallengeStatusCode(responseStatusCode)) {
            result = getRawStringForHTTPMessageRef(response);
            goto leave;
        }
        
        if (count) {
            self.authUsername = nil;
            self.authPassword = nil;
        }
        
        BOOL forProxy = isAuthChallengeForProxyStatusCode(responseStatusCode);
        auth = CFHTTPAuthenticationCreateFromResponse(kCFAllocatorDefault, response);
        
        NSString *scheme = [(id)CFHTTPAuthenticationCopyMethod(auth) autorelease];
        NSString *realm  = [(id)CFHTTPAuthenticationCopyRealm(auth) autorelease];
        NSArray *domains = [(id)CFHTTPAuthenticationCopyDomains(auth) autorelease];
        NSURL *domain = domains.count ? [domains objectAtIndex:0] : nil;
        
        BOOL cancelled = NO;
        NSString *username = nil;
        NSString *password = nil;
        
        // try the previous username/password first? do we really wanna do that?
        if (0 == count && self.authUsername.length && self.authPassword.length) {
            username = self.authUsername;
            password = self.authPassword;
        } 
//        else {
            // get username/password from user
            cancelled = [delegate getUsername:&username password:&password forAuthScheme:scheme URL:URL realm:realm domain:domain forProxy:forProxy isRetry:count];
            count++;
//        }
        
        self.authUsername = username;
        self.authPassword = password;
        
        if (cancelled) {
            result = nil;
            goto leave;
        }        
        
        if (request) {
            CFRelease(request);
            request = NULL;
        }
        if (response) {
            CFRelease(response);
            response = NULL;
        }
        
        request = createHTTPMessageRef(self, URL, method, body, headers);
        
        NSMutableDictionary *creds = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            username,  kCFHTTPAuthenticationUsername,
            password,  kCFHTTPAuthenticationPassword,
            nil];
        
        if (domain && CFHTTPAuthenticationRequiresAccountDomain(auth)) {
            [creds setObject:[domain absoluteString] forKey:(id)kCFHTTPAuthenticationAccountDomain];
        }

        Boolean credentialsApplied = CFHTTPMessageApplyCredentialDictionary(request, auth, (CFDictionaryRef)creds, NULL);
        
        if (auth) {
            CFRelease(auth);
            auth = NULL;
        }

        if (!credentialsApplied) {
            NSLog(@"OH BOTHER. Can't add add auth credentials to request. dunno why. FAIL.");
            result = nil;
            goto leave;
        }
        
    } while (1);
    
leave:
    if (request) {
        CFRelease(request);
        request = NULL;
    }
    if (response) {
        CFRelease(response);
        response = NULL;
    }
    if (auth) {
        CFRelease(auth);
        auth = NULL;
    }
        
    return result;
}


@implementation HTTPServiceCFNetworkImpl

#pragma mark -
#pragma mark HTTPClientHTTPService

- (id)initWithDelegate:(id)d {
    self = [super init];
    if (self != nil) {
        self.delegate = d;
    }
    return self;
}


- (void)dealloc; {
    self.delegate = nil;
    self.command = nil;
    self.authUsername = nil;
    self.authPassword = nil;
    [super dealloc];
}


- (void)sendHTTPRequest:(id)cmd {
    self.command = cmd;
    [NSThread detachNewThreadSelector:@selector(doSendHTTPRequest) toTarget:self withObject:nil];
}


#pragma mark -
#pragma mark Private

- (void)doSendHTTPRequest {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *URLString = [[command objectForKey:@"URLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSString *method = [command objectForKey:@"method"];
    NSString *body = [command objectForKey:@"body"];
    NSArray *headers = [command objectForKey:@"headers"];
    BOOL followRedirects = [[command objectForKey:@"followRedirects"] boolValue];
    
    NSString *finalURLString = nil;
    NSString *rawResponse = makeHTTPRequest(self, delegate, URL, method, body, headers, followRedirects, &finalURLString);
    
    if (finalURLString.length) {
        [command setObject:finalURLString forKey:@"finalURLString"];
    }
    
    if (!rawResponse.length) {
        NSLog(@"(( Zero-length response returned from server. ))");
        [self failure:@""];
    } else {
        [command setObject:rawResponse forKey:@"rawResponse"];
        [self success:rawResponse];
    }
    
    [pool release];
}


- (void)success:(NSString *)rawResponse {
    [self performSelectorOnMainThread:@selector(doSuccess:) withObject:rawResponse waitUntilDone:NO];
}


- (void)doSuccess:(NSString *)rawResponse {
    [delegate HTTPService:self didRecieveResponse:rawResponse forRequest:command];
}


- (void)failure:(NSString *)msg {
    [self performSelectorOnMainThread:@selector(doFailure:) withObject:msg waitUntilDone:NO];
}


- (void)doFailure:(NSString *)msg {
    [delegate HTTPService:self request:command didFail:msg];
}

@synthesize delegate;
@synthesize command;
@synthesize authUsername;
@synthesize authPassword;
@end
