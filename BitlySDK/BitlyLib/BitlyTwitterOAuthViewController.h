//
//  BitlyTwitterOAuthViewController.h
//  BitlyLib
//
//  Created by Tracy Pesin on 7/11/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAToken.h"
#import "BitlyTwitterOAuthAccount.h"

@class BitlyTwitterOAuthViewController;

@protocol BitlyTwitterOAuthDelegate <NSObject>
@optional 
- (void)oAuthViewController:(BitlyTwitterOAuthViewController *)viewController didAuthorizeAccount:(BitlyTwitterOAuthAccount *)oauthAccount;
- (void)oAuthViewController:(BitlyTwitterOAuthViewController *)viewController didFailWithError:(NSError *)error;
- (void)oAuthViewControllerAuthCancelledByUser:(BitlyTwitterOAuthViewController *)viewController;
@end


@interface BitlyTwitterOAuthViewController : UIViewController <UIWebViewDelegate> {
    
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, retain) OAToken *requestToken;

@property (nonatomic, assign) id<BitlyTwitterOAuthDelegate> delegate;

@end
