    //
//  BitlyTweetSheet.m
//  Bitly
//
//  Created by Tracy Pesin on 11/22/10.
//  Copyright 2010 Betaworks. All rights reserved.
//

#import "BitlyTweetSheet.h"
#import "BitlyLibUtil.h"
#import "BitlyTweetSheetAccountSelector.h"
#import "BitlyTwitterOAuthViewController.h"

#import <Twitter/TWRequest.h>
#import "BitlyTwitterOAuthManager.h"
#import <QuartzCore/QuartzCore.h>
#import "BitlyDebug.h"

@interface BitlyTweetSheet() <BitlyTweetSheetAccountSelectorDelegate, BitlyTwitterOAuthDelegate> {
    BOOL sendRequested;
}

@property (nonatomic, retain, readwrite) BitlyTwitterOAuthAccount *oauthAccount;
@property (nonatomic, retain) BitlyTwitterOAuthViewController *oauthViewController;
@property (nonatomic, retain) TWRequest *twitterRequest;

- (void)setCharCount;
- (void)getAccountStoreAccounts;
- (void)getOAuthAccount;
- (void)presentOAuthDialog;
- (void)oauthAccountAuthorized:(BitlyTwitterOAuthAccount *)anOauthAccount;
- (void)userCancelledTweet:(id)sender;
- (void)sendTweet;
- (void)setAccountStoreAccounts;
- (void)setAccounts;
@end


@implementation BitlyTweetSheet

@synthesize charCountLabel;
@synthesize textView;
@synthesize delegate;
@synthesize initialText;
@synthesize submitButton;
@synthesize activeAccountButton;
@synthesize switchAccountsButton;

@synthesize account;
@synthesize accountStore;
@synthesize allAccounts;
@synthesize accountPickerPopover;
@synthesize oauthAccount;
@synthesize oauthViewController;
@synthesize twitterRequest;

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.oauthViewController.delegate = nil;
    [oauthViewController release];
    
	[initialText release];
    [charCountLabel release];
	[textView release];
	[submitButton release];
    [account release];
    [accountStore release];
	
    [activeAccountButton release];
    [switchAccountsButton release];
    
    [allAccounts release];
    
    [accountPickerPopover release];
    
    [twitterRequest release];
    
    [super dealloc];
}

#pragma mark initializer

- (id)init {
    NSString *nibName = nil;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        nibName = @"BitlyTweetSheet_iPad";
    } else {
        nibName = @"BitlyTweetSheet_iPhone";
    }
    
    return [super initWithNibName:nibName bundle:nil];
}



#pragma mark -

- (UIPopoverController *)popoverController {
    UINavigationController *navController = [[UINavigationController alloc] 
                                             initWithRootViewController:self];
    
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    
    [navController release];
    
    return [popoverController autorelease];

}

- (void)presentModallyFromViewController:(UIViewController *)viewController {
    
    UINavigationController *navController = [[UINavigationController alloc] 
                                             initWithRootViewController:self];
    
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [viewController presentModalViewController:navController animated:YES];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) { 
        navController.view.superview.bounds = CGRectMake (0.0, 
                                                          0.0, 
                                                          self.contentSizeForViewInPopover.width,
                                                          self.contentSizeForViewInPopover.height + 44.0);
    }
    
    navController.navigationBar.tintColor = [UIColor colorWithRed:77/255.0 green:173/255.0 blue:245/255.0 alpha:1.0];
    
    [navController release];

}

- (void)addURL:(NSURL *)url 
{
    if ([self isViewLoaded]) {
        [self.textView addURL:url];
    } else {
        if (self.initialText.length) {
            self.initialText = [NSString stringWithFormat:@"%@ %@", self.initialText, [url absoluteString]];
        } else {
            self.initialText = [url absoluteString];
        }
    }
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.navigationItem.title = @"Share on Twitter";
    
    self.contentSizeForViewInPopover = self.view.frame.size;
        
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                target:self 
                                                                                action:@selector(userCancelledTweet:)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    [cancelItem release];

    self.activeAccountButton.enabled = NO;

	if (self.initialText) {
		self.textView.text = self.initialText;
    }   
    
}

- (void)setAccounts {
    if ([ACAccountStore class]) {
        [self getAccountStoreAccounts];
    } else {
        [self getOAuthAccount];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        //Don't do this on iphone because bringing up the keyboard blocks some of the ui
        [self.textView becomeFirstResponder];
    }
    [self setCharCount];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                                                           [self setAccounts];
                                                       }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];  
    
    [self setAccounts];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [self setActiveAccountButton:nil];
    [self setSwitchAccountsButton:nil];
    [super viewDidUnload];
	self.textView = nil;
	self.submitButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ( UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        
    }
    return YES;
}

- (void)setCharCount {
	int charsRemaining = 140 - self.textView.text.length;
	charCountLabel.text = [NSString stringWithFormat:@"%d characters remaining", charsRemaining];
	if (charsRemaining < 0) {
		charCountLabel.textColor = [UIColor redColor];
		self.submitButton.enabled = NO;
	} else {
		charCountLabel.textColor = [UIColor grayColor];
		self.submitButton.enabled = YES;
	}
}


#pragma mark Actions

- (IBAction)tweetButtonTapped:(id)sender {
    sendRequested = YES;
    [self.textView shortenLinks];
}

- (void)sendTweet {
  
    if (self.textView.text.length) {
        if ([TWRequest class]) {
            
            NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
            TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                                     parameters:[NSDictionary dictionaryWithObject:textView.text forKey:@"status"] 
                                                  requestMethod:TWRequestMethodPOST];
            self.twitterRequest = request;
            [request release];
            
            twitterRequest.account = account;
            [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (error) {
                    if ([delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate bitlyTweetSheet:self didFailWithError:error]; 
                        });
                    }
                } else {
                    if ([delegate respondsToSelector:@selector(bitlyTweetSheetDidSendTweet:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate bitlyTweetSheetDidSendTweet:self];
                        });
                    }
                }
            }];
        } else { //version < iOS5
            [[BitlyTwitterOAuthManager sharedTwitterOAuthManager] 
             sendTweet:textView.text 
             withAccount:self.oauthAccount                
             completionHandler:^(BOOL success, NSError *error) {
                 if (error) {
                     if ([delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [delegate bitlyTweetSheet:self didFailWithError:error];
                         });
                     }
                 } else {
                     if ([delegate respondsToSelector:@selector(bitlyTweetSheetDidSendTweet:)]) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [delegate bitlyTweetSheetDidSendTweet:self];
                         });
                     }
                 }
             }];
        }
    }
}

- (IBAction)switchAccount:(id)sender {

    BitlyTweetSheetAccountSelector *accountPicker = [[BitlyTweetSheetAccountSelector alloc] initWithAccounts:self.allAccounts];
    accountPicker.delegate = self;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverController *pop = [[UIPopoverController alloc] initWithContentViewController:accountPicker];
        self.accountPickerPopover = pop;
        [pop release];
        [self.accountPickerPopover presentPopoverFromRect:((UIView *)sender).frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
        [accountPicker release];
    } else {
        [self.navigationController pushViewController:accountPicker animated:YES];
    }
}

- (void)userCancelledTweet:(id)sender {
    if ([self.delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
        [self.delegate bitlyTweetSheetUserCancelledTweet:self];
    }
}


#pragma mark AccountStore
- (void)getAccountStoreAccounts {
    ACAccountStore *as = [[ACAccountStore alloc] init];
    self.accountStore = as;
    [as release];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:
     ^(BOOL granted, NSError *error) {
         if (error) {
             if ([self.delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
                 [self.delegate bitlyTweetSheet:self didFailWithError:error];
             }
         } else {
             if (granted) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self setAccountStoreAccounts];
                 });
             } else {
                 if ([self.delegate respondsToSelector:@selector(bitlyTweetSheetAccountAccessDenied:)]) {
                     [self.delegate bitlyTweetSheetAccountAccessDenied:self];
                 }
             }
         }
     }];
}


- (void)setAccountStoreAccounts {
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:accountType];
    if (!twitterAccounts.count) {
        self.submitButton.enabled = NO;
        self.activeAccountButton.enabled = NO;
        [self.activeAccountButton setTitle:@"" forState:UIControlStateNormal];
        
        if ([self.delegate respondsToSelector:@selector(bitlyTweetSheetNoAccountsAvailable:)]) {
            [self.delegate bitlyTweetSheetNoAccountsAvailable:self];
        }
    } else {
        self.submitButton.enabled = YES;
        NSString *lastAccountUsed = [BitlyLibUtil sharedBitlyUtil].lastAccountUsed;
        NSUInteger lastAccountIdx = NSNotFound;
        if (lastAccountUsed) {
            lastAccountIdx = [twitterAccounts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                ACAccount *a = (ACAccount *)obj;
                return [a.username isEqualToString:lastAccountUsed];
            }];
        }
        if (lastAccountIdx != NSNotFound) {
            self.account = [twitterAccounts objectAtIndex:lastAccountIdx];
        } else {
            self.account = [twitterAccounts objectAtIndex:0];
            [BitlyLibUtil sharedBitlyUtil].lastAccountUsed = self.account.username;
        }
        [self.activeAccountButton setTitle:self.account.accountDescription forState:UIControlStateNormal];    
        
        if (twitterAccounts.count > 1) {
            self.allAccounts = twitterAccounts;
            self.switchAccountsButton.hidden = NO;
            self.activeAccountButton.enabled = YES;
        }   
    }
}


#pragma mark -
#pragma mark OAuth

- (void)getOAuthAccount {
    BitlyTwitterOAuthManager *oauthMgr = [BitlyTwitterOAuthManager sharedTwitterOAuthManager];
    
    BitlyTwitterOAuthAccount *anAccount = [oauthMgr oauthAccount];
    
    if (!anAccount) {
        
        
        [oauthMgr getOAuthRequestTokenWithCompletionHandler:^(BOOL success, NSError *error){ 
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentOAuthDialog];
                });
            } else {
                if ([self.delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
                    [self.delegate bitlyTweetSheet:self didFailWithError:error];
                }
                BitlyLog(@"Error getting oauth request token: %@", [error localizedDescription]);
            }
        }];
    } else {
        [self oauthAccountAuthorized:anAccount];
    }
}

- (void)presentOAuthDialog {
    BitlyTwitterOAuthViewController *vc = [[BitlyTwitterOAuthViewController alloc] init];
    self.oauthViewController = vc;
    self.oauthViewController.delegate = self;
    [vc release];
    
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:self.oauthViewController];
    navc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navc animated:YES];
    [navc release];
}

- (void)oauthAccountAuthorized:(BitlyTwitterOAuthAccount *)anOauthAccount {
    self.oauthAccount = anOauthAccount;
    [activeAccountButton 
     setTitle: [NSString stringWithFormat:@"@%@", self.oauthAccount.username]
     forState:UIControlStateNormal];          
}

#pragma mark BitlyTwitterOAuthDelegate

- (void)oAuthViewController:(BitlyTwitterOAuthViewController *)viewController didAuthorizeAccount:(BitlyTwitterOAuthAccount *)anAccount {
    [self oauthAccountAuthorized:anAccount];
}

- (void)oAuthViewController:(BitlyTwitterOAuthViewController *)viewController didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(bitlyTweetSheetUserCancelledTweet:)]) {
        [self.delegate bitlyTweetSheetUserCancelledTweet:self];
    }
}

- (void)oAuthViewControllerAuthCancelledByUser:(BitlyTwitterOAuthViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(bitlyTweetSheet:didFailWithError:)]) {
        NSError *error = [NSError errorWithDomain:@"BitlyTwitterError"
                                             code: -213 
                                         userInfo:[NSDictionary dictionaryWithObject:@"User cancelled authorization" forKey:NSLocalizedDescriptionKey]];
                          [self.delegate bitlyTweetSheet:self didFailWithError:error];
    }
}

#pragma mark BitlyTweetSheetAccountSelectorDelegate
- (void)accountSelector:(BitlyTweetSheetAccountSelector *)accountSelector didSelectAccount:(ACAccount *)anAccount
{
    self.account = anAccount;
    [BitlyLibUtil sharedBitlyUtil].lastAccountUsed = self.account.username;
    [self.activeAccountButton setTitle:self.account.accountDescription forState:UIControlStateNormal]; 
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.accountPickerPopover dismissPopoverAnimated:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


#pragma mark BitlyTextViewDelegate
- (void)bitlyTextView:(BitlyTextView *)textView 
      didShortenLinks:(NSDictionary *)linkDictionary 
              oldText:(NSString *)oldText 
                 text:(NSString *)text {
    [self setCharCount];
    if (sendRequested) {
        [self sendTweet];
        sendRequested = NO;
    }
}

- (void)bitlyTextView:(BitlyTextView *)textView textDidChange:(NSString *)text {
	[self setCharCount];
    if ([delegate respondsToSelector:@selector(bitlyTweetSheet:textDidChange:)]) {
        [delegate bitlyTweetSheet:self textDidChange:text];
    }
}

@end
