//
//  BitlyTwitterOAuthAccount.h
//  BitlyLib
//
//  Created by Tracy Pesin on 7/14/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAToken.h"

@interface BitlyTwitterOAuthAccount : NSObject

@property (nonatomic, retain) NSString *oauthKey;
@property (nonatomic, retain) NSString *oauthSecret;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *userID;

@property (nonatomic, readonly) BOOL isValid;

+ (BitlyTwitterOAuthAccount *)accountWithTwitterResponse:(NSString *)twitterResponse;
+ (BitlyTwitterOAuthAccount *)savedAccount;

- (OAToken *)oauthConsumerToken; 
- (void)saveToKeychain;

@end
