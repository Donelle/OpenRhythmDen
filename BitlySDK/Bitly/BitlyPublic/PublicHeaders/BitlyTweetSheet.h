//
//  BitlyTweetSheet.h
//  Bitly
//
//  Created by Tracy Pesin on 11/22/10.
//  Copyright 2010 Betaworks. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <UIKit/UIKit.h>

#import "BitlyURLShortener.h"
#import "BitlyTextView.h"


@class BitlyTweetSheet;

@protocol BitlyTweetSheetDelegate <NSObject>
@optional
- (void)bitlyTweetSheetDidSendTweet:(BitlyTweetSheet *)viewController;
- (void)bitlyTweetSheet:(BitlyTweetSheet *)viewController didFailWithError:(NSError *)error;
- (void)bitlyTweetSheetUserCancelledTweet:(BitlyTweetSheet *)viewController;
- (void)bitlyTweetSheet:(BitlyTweetSheet *)viewController textDidChange:(NSString *)text;

/*These two methods are only relevant when on iOS5+ and the Accounts framework is being used. */
- (void)bitlyTweetSheetAccountAccessDenied:(BitlyTweetSheet *)viewController;
- (void)bitlyTweetSheetNoAccountsAvailable:(BitlyTweetSheet *)viewController;

@end

@interface BitlyTweetSheet : UIViewController <BitlyTextViewDelegate> {
}

@property (nonatomic, retain) IBOutlet UILabel *charCountLabel;
@property (nonatomic, retain) IBOutlet BitlyTextView *textView;
@property (nonatomic, retain) IBOutlet UIButton *submitButton;
@property (nonatomic, retain) IBOutlet UIButton *activeAccountButton;
@property (nonatomic, retain) IBOutlet UIButton *switchAccountsButton;

@property (nonatomic, retain) NSString *initialText;

@property (nonatomic, retain) ACAccount *account;
@property (nonatomic, retain) ACAccountStore *accountStore;
@property (nonatomic, retain) NSArray *allAccounts;

@property (nonatomic, retain) UIPopoverController *accountPickerPopover;



@property (nonatomic, readonly) UIPopoverController *popoverController;

@property (nonatomic, assign) id <BitlyTweetSheetDelegate> delegate;
 
- (void)addURL:(NSURL *)url;

- (void)presentModallyFromViewController:(UIViewController *)viewController;

- (IBAction)tweetButtonTapped:(id)sender;
- (IBAction)switchAccount:(id)sender;

@end
