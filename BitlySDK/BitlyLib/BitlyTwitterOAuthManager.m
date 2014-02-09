//
//  BitlyTwitterOAuthManager.m
//  BitlyLib
//
//  Created by Tracy Pesin on 7/12/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyTwitterOAuthManager.h"
#import "BitlyLibUtil.h"
#import "OAuthConsumer.h"
#import "OAMutableURLRequest.h"
#import "BitlyDebug.h"
#import "BitlyConfig.h"


@interface BitlyTwitterOAuthManager () {
    BitlyOAuthCompletionHandler requestTokenCompletionHandler;
    BitlyTweetCompletionHandler tweetCompletionHandler;
}

@property (nonatomic, retain) OAToken *requestToken;
@property (nonatomic, retain) BitlyOAuthCompletionHandler requestTokenCompletionHandler;
@property (nonatomic, retain) BitlyTweetCompletionHandler tweetCompletionHandler;

- (void)getAccessTokenWithRequestToken:(OAToken *)token verifier:(NSString *)verifier;

@end


@implementation BitlyTwitterOAuthManager

//Set by user


//Notifications
NSString * const BitlyTwitterOAuthAccountAuthorizedNotification = @"BitlyTwitterOAuthAccountAuthorized";
NSString * const BitlyTwitterOAuthFailedNotification = @"BitlyTwitterOAuthFailedNotification";
NSString * const BitlyTwitterOauthAccountUserInfoKey = @"BitlyTwitterOauthAccountUserInfoKey";
NSString * const BitlyTwitterOauthErrorUserInfoKey = @"BitlyTwitterOauthErrorUserInfoKey";

@synthesize requestToken;

static BitlyTwitterOAuthManager *theInstance;

static NSString * const ErrorDomain = @"BitlyOAuthErrorDomain";
static NSInteger RequestTokenErrorCode = -200;
static NSInteger TweetErrorCode = -205;
static NSInteger AccessTokenErrorCode = -210;
static NSInteger OAuthCredentialsErrorCode = -215;


+ (BitlyTwitterOAuthManager *)sharedTwitterOAuthManager {
    if (!theInstance) {
        theInstance = [[BitlyTwitterOAuthManager alloc] init];
    }
    return theInstance;
}

- (void)dealloc {
    [requestToken release];
    Block_release(requestTokenCompletionHandler);
    [tweetCompletionHandler release];
    
    [super dealloc];
}

#pragma mark properties

- (BitlyTwitterOAuthAccount *)oauthAccount {
    return [BitlyTwitterOAuthAccount savedAccount];
}


- (BitlyOAuthCompletionHandler)requestTokenCompletionHandler {
    return requestTokenCompletionHandler;
}

- (void)setRequestTokenCompletionHandler:(BitlyOAuthCompletionHandler)handler {
    requestTokenCompletionHandler = Block_copy(handler);
}

- (BitlyOAuthCompletionHandler)tweetCompletionHandler {
    return tweetCompletionHandler;
}

- (void)setTweetCompletionHandler:(BitlyTweetCompletionHandler)handler {
    tweetCompletionHandler = Block_copy(handler);
}



#pragma mark -

- (NSURL *)authorizeURL {
    if (self.requestToken) {
        NSString *urlString = [NSString stringWithFormat:BitlyTwitterAuthorizeURLFormat, self.requestToken.key];     
        return [NSURL URLWithString:urlString];
    } else {
        return nil;
    }
}

#pragma mark -

- (void)getOAuthRequestTokenWithCompletionHandler:(BitlyOAuthCompletionHandler)completionHandler {
     
    self.requestTokenCompletionHandler = nil;
    
    self.requestTokenCompletionHandler = completionHandler;
    
    BitlyConfig *config = [BitlyConfig sharedBitlyConfig];
    NSString *twitterOAuthConsumerKey = [config twitterOAuthConsumerKey];
    NSString *twitterOAuthConsumerSecret = [config twitterOAuthConsumerSecret];
    
    if (![twitterOAuthConsumerKey length] || ![twitterOAuthConsumerSecret length]) {
        NSError *error = [NSError errorWithDomain:ErrorDomain code:OAuthCredentialsErrorCode 
                                         userInfo:[NSDictionary dictionaryWithObject:@"Twitter OAuth API keys not set. See setter on BitlyConfig." forKey:NSLocalizedDescriptionKey]];
         requestTokenCompletionHandler(NO, error);
      
    } else {
    
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:twitterOAuthConsumerKey
                                                        secret:twitterOAuthConsumerSecret];
        
        NSURL *url = [NSURL URLWithString:BitlyTwitterRequestTokenURL];
        
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                       consumer:consumer
                                                                          token:nil   // we don't have a Token yet
                                                                          realm:nil   // our service provider doesn't specify a realm
                                                              signatureProvider:nil] autorelease]; // use the default method, HMAC-SHA1
        
        [consumer release];
        
        [request setHTTPMethod:@"POST"];
        
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        
        [fetcher fetchDataWithRequest:request
                             delegate:self
                    didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                      didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
    }
}


- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    if (ticket.didSucceed && data) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        self.requestToken = token;
        [token release];
        [responseBody release];
        
        requestTokenCompletionHandler(YES, nil);
    } else {
        
        NSString *reason = nil;
        if (!ticket.didSucceed) {
            reason = @"Ticket did not succeed";
        } else {
            reason = @"No token data returned";
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:ErrorDomain code:RequestTokenErrorCode userInfo:userInfo];
        requestTokenCompletionHandler(NO, error);
    }
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    BitlyLog(@"Request token ticket failed: %@", [error localizedDescription]);
    requestTokenCompletionHandler(NO, error);
}

- (void)authorizationCompletedWithCallbackURL:(NSURL *)callbackURL {
    NSDictionary *params = [BitlyLibUtil parseQueryString:[callbackURL query]];
    NSString *oauthVerifier = [params objectForKey:@"oauth_verifier"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self getAccessTokenWithRequestToken:self.requestToken verifier:oauthVerifier];
    });
}

- (void)getAccessTokenWithRequestToken:(OAToken *)token verifier:(NSString *)verifier {
    BitlyConfig *config = [BitlyConfig sharedBitlyConfig];
    NSString *twitterOAuthConsumerKey = [config twitterOAuthConsumerKey];
    NSString *twitterOAuthConsumerSecret = [config twitterOAuthConsumerSecret];
    
    if (![twitterOAuthConsumerKey length] || ![twitterOAuthConsumerSecret length]) {
        NSError *error = [NSError errorWithDomain:ErrorDomain code:OAuthCredentialsErrorCode 
                                         userInfo:[NSDictionary dictionaryWithObject:@"Twitter OAuth API keys not set. See setter on BitlyConfig." forKey:NSLocalizedDescriptionKey]];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:BitlyTwitterOauthErrorUserInfoKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BitlyTwitterOAuthFailedNotification object:self userInfo:userInfo];

        
    } else {

        OAConsumer *consumer = [[[OAConsumer alloc] initWithKey:twitterOAuthConsumerKey
                                                         secret:twitterOAuthConsumerSecret] autorelease];
        
        NSURL *accessTokenURL = [NSURL URLWithString:BitlyTwitterAccessTokenURL];
        
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:accessTokenURL
                                                                       consumer:consumer
                                                                          token:token
                                                                          realm:nil   // our service provider doesn't specify a realm
                                                              signatureProvider:nil] autorelease]; // use the default method, HMAC-SHA1
        
        [request setOAuthParameterName:@"oauth_verifier" withValue:verifier];
        
        [request setHTTPMethod:@"POST"];
        
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        
        [fetcher fetchDataWithRequest:request
                             delegate:self
                    didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                      didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
    }
}


- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    if (ticket.didSucceed && data) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        BitlyTwitterOAuthAccount *oauthAccount = [BitlyTwitterOAuthAccount accountWithTwitterResponse:responseBody];
        
        [responseBody release];
        
        if (oauthAccount.isValid) {
            [oauthAccount saveToKeychain];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:oauthAccount forKey:BitlyTwitterOauthAccountUserInfoKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:BitlyTwitterOAuthAccountAuthorizedNotification
                                                                object:self 
                                                              userInfo:userInfo];
        } else {
            NSError *error = [NSError 
                              errorWithDomain:ErrorDomain 
                              code:AccessTokenErrorCode 
                              userInfo: [NSDictionary dictionaryWithObject:@"Invalid oauth access token response" 
                                                                    forKey:NSLocalizedDescriptionKey]];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:BitlyTwitterOauthErrorUserInfoKey];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BitlyTwitterOAuthFailedNotification object:self userInfo:userInfo];
        }
        
    } else {
        NSString *reason = nil;
        if (!ticket.didSucceed) {
            reason = @"Access token ticket did not succeed";
        } else {
            reason = @"No access token data returned";
        }
        NSError *error = [NSError 
                            errorWithDomain:ErrorDomain 
                            code:AccessTokenErrorCode 
                            userInfo: [NSDictionary dictionaryWithObject:reason 
                                                                  forKey:NSLocalizedDescriptionKey]];
                            
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:BitlyTwitterOauthErrorUserInfoKey];

        [[NSNotificationCenter defaultCenter] postNotificationName:BitlyTwitterOAuthFailedNotification object:self userInfo:userInfo];
    }
}


- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    BitlyLog(@"Access token ticket failed: %@", [error localizedDescription]);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:BitlyTwitterOauthErrorUserInfoKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:BitlyTwitterOAuthFailedNotification object:self userInfo:userInfo];
}

- (void)sendTweet:(NSString *)tweet 
      withAccount:(BitlyTwitterOAuthAccount *)account 
completionHandler:(BitlyTweetCompletionHandler)completionHandler {
    
    self.tweetCompletionHandler = completionHandler;
    
    NSURL *statusURL = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
    
    BitlyConfig *config = [BitlyConfig sharedBitlyConfig];
    NSString *twitterOAuthConsumerKey = [config twitterOAuthConsumerKey];
    NSString *twitterOAuthConsumerSecret = [config twitterOAuthConsumerSecret];
    
    if (![twitterOAuthConsumerKey length] || ![twitterOAuthConsumerSecret length]) {
        NSError *error = [NSError errorWithDomain:ErrorDomain code:OAuthCredentialsErrorCode 
                                         userInfo:[NSDictionary dictionaryWithObject:@"Twitter OAuth API keys not set. See setter on BitlyConfig." forKey:NSLocalizedDescriptionKey]];
        

        BitlyLog(@"Status api req failed: %@", [error localizedDescription]);
        tweetCompletionHandler(NO, error);
    } else {
    
        OAConsumer *consumer = [[[OAConsumer alloc] initWithKey:twitterOAuthConsumerKey
                                                         secret:twitterOAuthConsumerSecret] autorelease];
        
        
        
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:statusURL
                                                                       consumer:consumer
                                                                          token:account.oauthConsumerToken
                                                                          realm:nil
                                                              signatureProvider:nil] autorelease];
        
        [request setHTTPMethod:@"POST"];
        
        OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status"
                                                                             value:tweet];
           
        NSArray *params = [NSArray arrayWithObject:statusParam];
        [request setParameters:params];
        [statusParam release];
        
           
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        [fetcher fetchDataWithRequest:request
                             delegate:self
                    didFinishSelector:@selector(apiTicket:didFinishWithData:)
                      didFailSelector:@selector(apiTicket:didFailWithError:)];
    }
}

- (void)apiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    
    if (ticket.didSucceed && data) {
        NSString *responseBody = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];
        
        [responseBody release];
        tweetCompletionHandler(YES, nil);
    } else {
        NSString *reason = nil;
        if (!ticket.didSucceed) {
            reason = @"Ticket did not succeed";
        } else {
            reason = @"No token data returned";
        }
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:ErrorDomain code:TweetErrorCode userInfo:userInfo];
        tweetCompletionHandler(NO, error);
    }
}

- (void)apiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
    
    BitlyLog(@"Status api req failed: %@", [error localizedDescription]);
    tweetCompletionHandler(NO, error);
}

@end
