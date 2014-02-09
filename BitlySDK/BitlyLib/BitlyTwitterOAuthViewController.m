//
//  BitlyTwitterOAuthViewController.m
//  BitlyLib
//
//  Created by Tracy Pesin on 7/11/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyTwitterOAuthViewController.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OAPlaintextSignatureProvider.h"
#import "BitlyTwitterOAuthManager.h"
#import "BitlyDebug.h"
#import "BitlyConfig.h"


@interface BitlyTwitterOAuthViewController () 

@property (nonatomic, retain) NSURL *url;

- (void)reload;

@end


@implementation BitlyTwitterOAuthViewController

@synthesize url;
@synthesize webView;
@synthesize activityIndicator;
@synthesize requestToken;
@synthesize delegate;

- (void)dealloc
{
    self.delegate = nil;
    
    [requestToken release], requestToken = nil;
    [url release], url = nil;
    [webView stopLoading], webView.delegate = nil, [webView release], webView = nil;
    [activityIndicator release], activityIndicator = nil;
    
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.webView = nil;
    self.activityIndicator = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)loadView
{
    UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;;
    self.view = mainView;
    [mainView release];
    
    UIWebView *wv = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView = wv;
    [wv release];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator = ai;
    [ai release];
    self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleLeftMargin;
    
    CGRect frame = self.activityIndicator.frame;
    frame.origin.x = floor((self.view.bounds.size.width - frame.size.width) / 2.0);
    frame.origin.y = floor((self.view.bounds.size.height - frame.size.height) / 2.0);
    self.activityIndicator.frame = frame;
    [self.view addSubview:activityIndicator];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userCancelledAuth)];
    self.navigationItem.leftBarButtonItem = cancelItem;
    [cancelItem release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *authorizeURL = [BitlyTwitterOAuthManager sharedTwitterOAuthManager].authorizeURL;
    if (authorizeURL) {
        self.url = authorizeURL;
    } else {
        BitlyLog(@"ERROR: Authorize URL not provided");    
    }
    
    [[NSNotificationCenter defaultCenter] 
     addObserverForName:BitlyTwitterOAuthAccountAuthorizedNotification  
     object:nil 
     queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *notification) {
         BitlyTwitterOAuthAccount *anAccount = [notification.userInfo objectForKey:BitlyTwitterOauthAccountUserInfoKey];
         if ([delegate respondsToSelector:@selector(oAuthViewController:didAuthorizeAccount:)]) {
             [delegate oAuthViewController:self didAuthorizeAccount:anAccount];
         }
         [self dismissModalViewControllerAnimated:YES];
     }]; 
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:BitlyTwitterOAuthFailedNotification 
     object:nil 
     queue:[NSOperationQueue mainQueue] 
     usingBlock:^(NSNotification *notification) {
         NSError *error = [notification.userInfo objectForKey:BitlyTwitterOauthErrorUserInfoKey];
         if ([delegate respondsToSelector:@selector(oAuthViewController:didFailWithError:)]) {
             [delegate oAuthViewController:self didFailWithError:error];
         }
     }];

    [self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    self.webView.alpha = 1.0;
    if (self.title == nil) {
        NSString *docTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        if ([docTitle length] > 0) {
            self.navigationItem.title = docTitle;
        }
    }
}

#pragma mark -
- (void)reload {
    if (self.url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
        self.webView.alpha = 0.0;
        [self.activityIndicator startAnimating];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
   
    NSString *urlString = [request.URL absoluteString];
    NSString *twitterSuccessCallbackURL = [ [BitlyConfig sharedBitlyConfig] twitterOAuthSuccessCallbackURL];
    
    
    if (![twitterSuccessCallbackURL length]) {
        NSError *error = [NSError errorWithDomain:@"BitlyOAuthErrorDomain" code:-1 
                                         userInfo:[NSDictionary dictionaryWithObject:@"Twitter callback URL not set. See setter on BitlyConfig." forKey:NSLocalizedDescriptionKey]];
        if ([delegate respondsToSelector:@selector(oAuthViewController:didFailWithError:)]) {
            [delegate oAuthViewController:self didFailWithError:error];
        }
    } else {

        if ([urlString rangeOfString:twitterSuccessCallbackURL].location == 0 ) {
            BitlyTwitterOAuthManager *oauthMgr = [BitlyTwitterOAuthManager sharedTwitterOAuthManager];
            [oauthMgr authorizationCompletedWithCallbackURL:request.URL];  
            return NO;
        }
    }    
    return YES;
}

#pragma mark -
#pragma mark Actions

- (void)userCancelledAuth {
    [self dismissModalViewControllerAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(oAuthViewControllerAuthCancelledByUser:)]) {
        [self.delegate oAuthViewControllerAuthCancelledByUser:self];
    }
}

@end
