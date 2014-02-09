//
//  BitlyRequest.m
//
//  Created by Tracy Pesin
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyRequest.h"
#import "BitlyLibUtil.h"
#import "NSDictionary_JSONExtensions.h"
#import "BitlyConfig.h"


@interface BitlyRequest ()
@property (nonatomic, retain) NSURLConnection *URLConnection;
@property (nonatomic, retain) NSMutableData *receivedData;
@end

@implementation BitlyRequest

@synthesize delegate;
@synthesize longURL;
@synthesize URLConnection;
@synthesize receivedData;

- (void)dealloc {
    [longURL release];
    [URLConnection release];

    [super dealloc];
}

- (BitlyRequest *)initWithURL:(NSURL *)aURL 
{
    self = [super init];
	if (self) {
		self.longURL = aURL;
	}
	return self;
}

- (void)setDelegate:(id<BitlyRequestDelegate>)aDelegate {
    delegate = aDelegate;
}

- (void)start {
    NSString *bitlyLogin = [[BitlyConfig sharedBitlyConfig] bitlyLogin];
    if (![bitlyLogin length]) {
        NSLog(@"You need to set the bitly login");
        [delegate bitlyRequest:self failedForLongURL:longURL statusCode:-1 statusText:@"Bitly login not set!"];
        return;
    }
    NSString *bitlyAPIKey = [[BitlyConfig sharedBitlyConfig] bitlyAPIKey];
    if (![bitlyAPIKey length]) {
        NSLog(@"You need to set the bitly api key");
        [delegate bitlyRequest:self failedForLongURL:longURL statusCode:-1 statusText:@"Bitly API key not set!"];
        return;
    }
    
    //Only get here if credentials are set
    NSString *longURLString = [BitlyLibUtil urlEncode:[longURL absoluteString]];
    NSString *requestString = [NSString stringWithFormat:@"http://api.bitly.com/v3/shorten?login=%@&apiKey=%@&longUrl=%@&format=json", bitlyLogin, bitlyAPIKey, longURLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.URLConnection = c;
    [c release];
    
    if (URLConnection) {
        [URLConnection start];
        self.receivedData = [NSMutableData data];
    } else {
        [self.delegate bitlyRequest:self failedForLongURL:longURL statusCode:-1 statusText:@"Error creating URLConnection"];
    }
    
    
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    self.URLConnection = nil;
    self.receivedData = nil;

    NSString *statusText = [NSString stringWithFormat: @"Connection failed! Error - %@ %@",
                            [error localizedDescription],
                            [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];
    
    [self.delegate bitlyRequest:self failedForLongURL:longURL statusCode:-1 statusText:statusText];

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    NSString *jsonString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    NSDictionary *responseDict = [NSDictionary dictionaryWithJSONString:jsonString error:&error];
    [jsonString release];
    
    if (error) {
        [delegate bitlyRequest:self failedForLongURL:self.longURL statusCode:0 statusText:@"Response could not be converted to a JSON value"];
    } else {
        NSDecimalNumber *statusCode = [responseDict objectForKey:@"status_code"];
        NSString *statusText = [responseDict objectForKey:@"status_txt"];
        NSDictionary *data = [responseDict objectForKey:@"data"];
        
        if (statusCode.intValue != 200) {
            [delegate bitlyRequest:self failedForLongURL:self.longURL statusCode:statusCode.intValue statusText:statusText];
        } else {
            if (!data) { 
                [delegate bitlyRequest:self failedForLongURL:self.longURL statusCode:statusCode.intValue statusText:@"Response data was empty"];
            } else {
                NSString *url = [data objectForKey:@"url"];
                if (!url) {
                    [delegate bitlyRequest:self failedForLongURL:self.longURL statusCode:statusCode.intValue statusText:@"Returned url was nil"];
                } else {
                    [delegate bitlyRequestSucceeded:self forLongURL:self.longURL withShortURLString:url responseData:data];
                }
            }
        }
    } 
    
    self.URLConnection = nil;
    self.receivedData = nil;
}

@end
