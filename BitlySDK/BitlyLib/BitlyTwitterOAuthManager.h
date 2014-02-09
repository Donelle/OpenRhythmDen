//
//  BitlyTwitterOAuthManager.h
//  BitlyLib
//
//  Created by Tracy Pesin on 7/12/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BitlyTwitterOAuthAccount.h"

extern NSString * const BitlyTwitterOAuthAccountAuthorizedNotification;
extern NSString * const BitlyTwitterOAuthFailedNotification;
extern NSString * const BitlyTwitterOauthAccountUserInfoKey;
extern NSString * const BitlyTwitterOauthErrorUserInfoKey;


@interface BitlyTwitterOAuthManager : NSObject {
    
}

@property (nonatomic, retain, readonly) BitlyTwitterOAuthAccount *oauthAccount;
@property (nonatomic, readonly) NSURL *authorizeURL;

typedef void(^BitlyOAuthCompletionHandler)(BOOL success, NSError *error);
typedef void(^BitlyTweetCompletionHandler)(BOOL success, NSError *error);

+ (BitlyTwitterOAuthManager *)sharedTwitterOAuthManager;

- (void)getOAuthRequestTokenWithCompletionHandler:(BitlyOAuthCompletionHandler)completionHandler;
- (void)authorizationCompletedWithCallbackURL:(NSURL *)callbackURL;
- (void)sendTweet:(NSString *)tweet withAccount:(BitlyTwitterOAuthAccount *)account completionHandler:(BitlyTweetCompletionHandler)completionHandler;

@end
