//
//  BitlyConfig.m
//  BitlyLib
//
//  Created by Tracy Pesin on 8/12/11.
//  Copyright (c) 2011 Betaworks. All rights reserved.
//

#import "BitlyConfig.h"

@interface BitlyConfig() {
    NSString *bitlyLogin;
    NSString *bitlyAPIKey;
    NSString *twitterOAuthConsumerKey;
    NSString *twitterOAuthConsumerSecret;
    NSString *twitterOAuthSuccessCallbackURL;
}
- (NSDictionary *)plistConfig;

@end

static BitlyConfig *theInstance = nil;

@implementation BitlyConfig

@synthesize bitlyLogin = __bitlyLogin;
@synthesize bitlyAPIKey = __bitlyAPIKey;
@synthesize twitterOAuthConsumerKey = __twitterOAuthConsumerKey;
@synthesize twitterOAuthConsumerSecret = __twitterOAuthConsumerSecret;
@synthesize twitterOAuthSuccessCallbackURL = __twitterOAuthSuccessCallbackURL;

- (void)dealloc 
{
    [bitlyLogin release];
    [bitlyAPIKey release];
    [twitterOAuthConsumerKey release];
    [twitterOAuthConsumerSecret release];
    [twitterOAuthSuccessCallbackURL release];
}

//These should be the same for everyone, but can be doublechecked at https://dev.twitter.com/apps/ 
NSString * const BitlyTwitterRequestTokenURL = @"https://api.twitter.com/oauth/request_token";
NSString * const BitlyTwitterAccessTokenURL = @"https://api.twitter.com/oauth/access_token";
NSString * const BitlyTwitterAuthorizeURLFormat = @"https://api.twitter.com/oauth/authorize?oauth_token=%@";


+ (BitlyConfig *)sharedBitlyConfig {
    if (!theInstance) {
        theInstance = [[BitlyConfig alloc] init];
    }
    return theInstance;
}

- (void)setBitlyLogin:(NSString *)login bitlyAPIKey:(NSString *)apiKey {
    self.bitlyLogin = login;
    self.bitlyAPIKey = apiKey;
}

- (void)setTwitterOAuthConsumerKey:(NSString *)consumerKey 
        twitterOAuthConsumerSecret:(NSString *)consumerSecret 
    twitterOAuthSuccessCallbackURL:(NSString *)successCallbackURL {
    twitterOAuthConsumerKey = consumerKey;
    twitterOAuthConsumerSecret = consumerSecret;
    twitterOAuthSuccessCallbackURL = successCallbackURL;
}

- (NSDictionary *)plistConfig {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"BitlyServices" ofType:@"plist"];
    if (plistPath) {
       return [[[NSDictionary alloc] initWithContentsOfFile:plistPath] autorelease];
    } else {
        return nil;
    }
}

- (NSString *)bitlyLogin {
    if (!__bitlyLogin) {
        NSDictionary *plistConfig = [self plistConfig];
        if (plistConfig) {
            self.bitlyLogin = [plistConfig objectForKey:@"BLYBitlyLogin"];
        } 
    }
    return __bitlyLogin;
}

- (NSString *)bitlyAPIKey {
    if (!__bitlyAPIKey) {
        NSDictionary *plistConfig = [self plistConfig];
        if (plistConfig) {
            self.bitlyAPIKey = [plistConfig objectForKey:@"BLYBitlyAPIKey"];
        }
    }
    return __bitlyAPIKey;
}

- (NSString *)twitterOAuthConsumerKey {
    if (!__twitterOAuthConsumerKey) {
        NSDictionary *plistConfig = [self plistConfig];
        if (plistConfig) {
            self.twitterOAuthConsumerKey = [plistConfig objectForKey:@"BLYTwitterOAuthConsumerKey"];
        }
    }
    return __twitterOAuthConsumerKey;
}

- (NSString *)twitterOAuthConsumerSecret {
    if (!__twitterOAuthConsumerSecret) {
        NSDictionary *plistConfig = [self plistConfig];
        if (plistConfig) {
            self.twitterOAuthConsumerSecret = [plistConfig objectForKey:@"BLYTwitterOAuthConsumerSecret"];
        }
    }
    return __twitterOAuthConsumerSecret;
}

- (NSString *)twitterOAuthSuccessCallbackURL {
    if (!__twitterOAuthSuccessCallbackURL) {
        NSDictionary *plistConfig = [self plistConfig];
        if (plistConfig) {
            self.twitterOAuthSuccessCallbackURL = [plistConfig objectForKey:@"BLYTwitterOAuthSuccessCallbackURL"];
        }
    }
    return __twitterOAuthSuccessCallbackURL;
}

@end
