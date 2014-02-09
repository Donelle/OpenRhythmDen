//
//  RDPreferenceViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/10/13.
//
//

#import "RDPreferenceViewController.h"
#import "RDDropboxTutorialViewController.h"
#import "RDAppPreference.h"
#import "RDDropboxPreference.h"
#import "RDMusicLibrary.h"
#import "RDMusicRepository.h"
#import "RDMusicPlayer.h"
#import "RDInternetDetectionActionSheet.h"
#import "RDMusicResourceCache.h"
#import "DBSession+RhythmDen.h"
#import "RDSwipeableTableViewCell.h"
#import "UIImage+RhythmDen.h"
#import "UIColor+RhythmDen.h"
#import "DETAnimatedTransitionController.h"
#import "RDAlertView.h"
#import "MSCellAccessory.h"
#import "Reachability.h"
#import "NSObject+RhythmDen.h"
#import "UIApplication+RhythmDen.h"
#import "GPUImageSDK.h"
#import "iRate.h"
#import <DropboxSDK/DropboxSDK.h>
#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>


@interface RDProgressView : UIView

@property (assign, nonatomic) CGFloat progress;

- (id)initWithTitle:(NSString *)title;
- (void)show;
- (void)hide;

@end


@implementation RDProgressView
{
    UILabel * _progressLabel;
    UILabel * _titleLabel;
    UIActivityIndicatorView * _activityView;
    UIView * _contentView;
    BOOL _isVisible ;
}

- (id)initWithTitle:(NSString *)title
{
    if (self = [super initWithFrame:CGRectZero]) {
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        UIColor * textColor = cache.buttonTextColor;

        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = cache.darkBackColor;
        _contentView.layer.borderColor = [cache.darkBackColor lighterColor].CGColor;
        _contentView.layer.borderWidth = 1.0;
        _contentView.layer.cornerRadius = 10.0f;
        _contentView.alpha =  0.0f;
        [self addSubview:_contentView];
        
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityView.tintColor = textColor;
        [_activityView startAnimating];
        [_contentView addSubview:_activityView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = title;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
        [_contentView addSubview:_titleLabel];
        
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _progressLabel.text = @"0% Completed";
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.font = [UIFont systemFontOfSize:12.0];
        _progressLabel.textColor = textColor;
        [_contentView addSubview:_progressLabel];
        
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _activityView.frame = CGRectMake(50, 15, 10, 10);
    _titleLabel.frame = CGRectMake(_activityView.frame.origin.x + 20, 10, 150, 20);
    _progressLabel.frame = CGRectMake(0, 35, _contentView.bounds.size.width, 20);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (_isVisible) {
        CGRect contentRect = _contentView.frame;
        //
        // Draw the background
        //
        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:10.0];
        [[UIColor blackColor] set];
        [path fill];
        
        UIColor * color = [[RDMusicResourceCache sharedInstance] buttonTextColor];
        [color set];
        //
        // Draw the progress bar
        //
        CGRect barRect = CGRectMake(contentRect.origin.x + 15, contentRect.origin.y + 60, contentRect.size.width - 30, 20);
        barRect = CGRectInset(barRect, 1.0, 1.0);
        path = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:10.0f];
        [path stroke];
        //
        // Draw the status
        //
        CGRect progressRect = CGRectInset(barRect, 3.0, 3.0);
        progressRect.size.width *=  _progress;
        path = [UIBezierPath bezierPathWithRoundedRect:progressRect cornerRadius:7.0f];
        [path fill];
    }
}


#pragma mark - Properties

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    NSUInteger percentage = floor(_progress * 100.0f);
    _progressLabel.text = [NSString stringWithFormat:@"%i%% Completed", percentage];
    [self setNeedsDisplay];
}

#pragma mark - Instance Methods

- (void)show
{
    CGRect windowRect = [[UIApplication sharedApplication] keyWindow].bounds;
    self.frame = CGRectMake(0, 0, windowRect.size.width, windowRect.size.height);
    
    UIView * backgroundView = [[UIView alloc] initWithFrame:windowRect];
    backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [self insertSubview:backgroundView atIndex:0];
    
    CGSize contentSize = CGSizeMake(120, 50);
    _contentView.layer.opacity = 0.0f;
    _contentView.transform = CGAffineTransformMakeScale(0.5f, 0.5f);
    _contentView.frame = CGRectMake((windowRect.size.width - contentSize.width) / 2, ((windowRect.size.height - contentSize.height) / 2), contentSize.width, contentSize.height);
    
    UIInterpolatingMotionEffect* xAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                         type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xAxis.minimumRelativeValue = [NSNumber numberWithFloat:-10.0];
    xAxis.maximumRelativeValue = [NSNumber numberWithFloat:10.0];
    
    UIInterpolatingMotionEffect* yAxis = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                         type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yAxis.minimumRelativeValue = [NSNumber numberWithFloat:-10.0];
    yAxis.maximumRelativeValue = [NSNumber numberWithFloat:10.0];
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xAxis, yAxis];
    [_contentView addMotionEffect:group];
    
    [UIView animateWithDuration:0.3
                          delay:0.1
         usingSpringWithDamping:0.7f
          initialSpringVelocity:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         _contentView.layer.opacity = 1.0f;
                         _contentView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL completed) {
                         _contentView.backgroundColor = [UIColor clearColor];
                         _progress = 0.0;
                         _isVisible = YES;
                         [self setNeedsDisplay];
                     }];
}


- (void)hide
{
    self.layer.transform = CATransform3DMakeScale(1, 1, 1);
    self.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         self.layer.transform = CATransform3DMakeScale(0.6f, 0.6f, 1.0);
                         self.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished) {
                         [self removeFromSuperview];
					 }
	 ];
}

@end


#pragma mark - RDPreferenceViewController Implemenation

#define SECTION_ACCOUNT 0
#define SECTION_OPTIONS 1
#define SECTION_HELP 2
#define SECTION_ABOUT 3

@interface RDPreferenceViewController () <
    RDSwipeableTableViewCellDelegate,
    DBRestClientDelegate,RDDropboxTutorialViewDelegate,
    MFMailComposeViewControllerDelegate,
    MFMessageComposeViewControllerDelegate
>

- (void)validateLibrarySyncronization;
- (void)updateSyncronizationUI:(NSString *)statusText;
- (void)showSyncronizationUI;
- (void)startBackgroundTask;
- (void)endBackgroundTask;
- (void)whipeOutAccount;
- (void)setAccountCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setAlertSettingCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setAboutCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setFeedbackCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setShareWithFriendsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setTutorialsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setLibraryInfoCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;
- (void)setRateUsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index;

- (void)didReceiveLibrarySyncCompleteNotification:(NSNotification *)notification;
- (void)didReceiveLibrarySyncStartedNotification:(NSNotification *)notification;
- (void)didReceiveLibrarySyncCancelledNotification:(NSNotification *)notification;
- (void)didReceiveLibrarySyncFailedNotification:(NSNotification *)notification;
- (void)dropboxRegistrationComplete:(NSNotification *)notification;
- (void)didReceiveEnteredBackgroundNotification:(NSNotification *)notification;
- (void)didReceiveEnteredForegroundNotification:(NSNotification *)notification;
- (void)didReceiveNetworkConnectionChangedNotification:(NSNotification *)notification;

- (void)didSlideAlertOption:(UISwitch *)sender;
- (void)didPressDeleteAccount;

@end


@implementation RDPreferenceViewController {
    RDAppPreference * _appPreferences;
    RDDropboxPreference * _dropboxPreferences;
    DBRestClient * _dropboxClient;
    id<UIViewControllerAnimatedTransitioning> _animationController;
    UIViewController * _tutorialController;
    UIBackgroundTaskIdentifier _backgroundTaskID;
    Reachability * _reachability;
    BOOL _bCanSyncOnCellular;
    NSOperationQueue * _clearLibraryOp;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    // Subscribe to notifications
    //
    [self registerForNotificationWith:@selector(didReceiveLibrarySyncCompleteNotification:) forName:RDMusicLibrarySyncCompleteNotification];
    [self registerForNotificationWith:@selector(didReceiveLibrarySyncStartedNotification:) forName:RDMusicLibrarySyncStartedNotification];
    [self registerForNotificationWith:@selector(didReceiveLibrarySyncCancelledNotification:) forName:RDMusicLibrarySyncCancelledNotification];
    [self registerForNotificationWith:@selector(didReceiveLibrarySyncFailedNotification:) forName:RDMusicLibrarySyncFailedNotification];
    [self registerForNotificationWith:@selector(didReceiveEnteredBackgroundNotification:) forName:UIApplicationWillResignActiveNotification];
    [self registerForNotificationWith:@selector(didReceiveEnteredForegroundNotification:) forName:UIApplicationDidBecomeActiveNotification];
    [self registerForNotificationWith:@selector(didReceiveNetworkConnectionChangedNotification:) forName:kReachabilityChangedNotification];
    /* See RDAppDelegate.m for how this notification is defined */
    [self registerForNotificationWith:@selector(dropboxRegistrationComplete:)];
    //
    // Get a handle to our internet connection and start monitoring
    //
    _reachability = [Reachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    //
    // Set up the title
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
    title.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    title.textColor =  cache.labelTitleTextColor;
    title.backgroundColor = [UIColor clearColor];
    title.text = self.navigationItem.title;
    self.navigationItem.titleView = title;
    self.statusLabel.textColor = [cache.buttonTextColor darkerColor];

    _appPreferences = [[RDAppPreference alloc] init];
    _dropboxPreferences = [[RDDropboxPreference alloc] init];
    _animationController = [[DETAnimatedTransitionController alloc] init];
    _clearLibraryOp = [NSOperationQueue new];
    _clearLibraryOp.name = @"Clear Library Queue";
    
    if ([[RDMusicLibrary sharedInstance] isSyncronizing]) {
        [self showSyncronizationUI];
    } else {
        [self validateLibrarySyncronization];
        [self updateSyncronizationUI:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [_preferenceView reloadData];
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDPreferenceViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder && (![RDMusicLibrary sharedInstance].isSyncronizing || _clearLibraryOp.operationCount == 0)) {
        _appPreferences = nil;
        _dropboxPreferences = nil;
        _preferenceView = nil;
        _statusLabel = nil;
        _refreshView = nil;
        _refreshStatusLabel = nil;
        _refreshLibraryButton = nil;
        _animationController = nil;
        _dropboxClient.delegate = self;
        _dropboxClient = nil;
        self.view = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
}


#pragma mark - Instance Methods


- (void)startBackgroundTask
{
#ifdef DEBUG
    NSLog(@"RDPreferenceViewController - registering background task");
#endif
    _backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSTimeInterval timeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
#ifdef DEBUG
        NSLog(@"RDPreferenceViewController - Background Time:%f", timeRemaining);
#endif
        //
        // Start teh cancellation
        //
        RDMusicLibrary * library = [RDMusicLibrary sharedInstance];
        if (library.isSyncronizing) {
            [self.refreshLibraryButton setTitle:@"Pausing Sync..." forState:UIControlStateNormal];
            [self.refreshStatusLabel setText:@"Pausing Synchronization..."];
            
            [library pauseSynchronization];
            while (!library.isOnPause)
                [NSThread sleepForTimeInterval:1.0];
            //
            // Notify the user whats going on
            //
            [[UIApplication sharedApplication] postNotificationMessage:@"We've suspended synchronization and will resume when you return to the app"];
        }
        //
        // Give dropbox time to cancel
        //
        if (timeRemaining <= 0.0) {
            //
            // Kill the task
            //
            if (_backgroundTaskID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                _backgroundTaskID = UIBackgroundTaskInvalid;
            }
        }
    }];
}


- (void)endBackgroundTask
{
    if (_backgroundTaskID != UIBackgroundTaskInvalid) {
#ifdef DEBUG
        NSLog(@"RDPreferenceViewController - unregistering the background task");
#endif
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
        _backgroundTaskID = UIBackgroundTaskInvalid;
    }
}

-(void)validateLibrarySyncronization
{
    [_refreshLibraryButton setEnabled:_dropboxPreferences.userId != nil];
}

- (void)updateSyncronizationUI:(NSString *)statusText
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UIColor * textColor = [UIColor colorWithRed:234.0/255.0 green:227.0/255.0 blue:203.0/255.0 alpha:1.0];
    
    [self.refreshView setHidden:YES];
    [self.statusLabel setHidden:NO];
    self.refreshLibraryButton.backgroundColor = cache.darkBackColor;
    self.refreshLibraryButton.layer.borderColor = cache.barTintColor.CGColor;
    self.refreshLibraryButton.layer.borderWidth = 0.5f;
    self.refreshLibraryButton.layer.cornerRadius = 5.0f;
    [self.refreshLibraryButton setTitle:@"Sync Library" forState:UIControlStateNormal];
    [self.refreshLibraryButton setTitleColor:textColor forState:UIControlStateNormal];
    
    if (!self.refreshLibraryButton.enabled) {
        self.refreshLibraryButton.layer.borderWidth = 0.0f;
        [self.refreshLibraryButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
    
    if (statusText) {
        _statusLabel.text = statusText;
    } else {
        NSDate * timeStamp = [_appPreferences lastSyncronized];
        if (timeStamp != nil) {
            NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MM/dd/yyyy 'at' HH:mm "];
            [formatter setLocale:[NSLocale autoupdatingCurrentLocale]];
            [formatter setTimeStyle: NSDateFormatterShortStyle];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            _statusLabel.text = [@"Library last synchronized: " stringByAppendingString:[formatter stringFromDate:timeStamp]] ;
        }
    }
}

- (void)showSyncronizationUI
{
    [self.statusLabel setHidden:YES];
    [self.refreshStatusLabel setText:@"Synchronizing your library"];
    [self.refreshView setHidden:NO];
    [self.refreshLibraryButton setTitle:@"Cancel Sync" forState:UIControlStateNormal];
    self.refreshLibraryButton.backgroundColor = [[UIColor redColor] darkerColor];
    self.refreshLibraryButton.layer.borderWidth = 0.0f;
}


- (void)setAccountCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    NSString * accountName = _dropboxPreferences.userDisplayName;
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = _dropboxPreferences.userId == nil ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = _dropboxPreferences.userId == nil ? @"Add Dropbox Account" : accountName;
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.imageView.image = [UIImage imageNamed:@"dropbox"];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.delegate = self;
    cell.revealDirection = _dropboxPreferences.userId == nil ? RDSwipeableTableViewCellRevealDirectionNone : RDSwipeableTableViewCellRevealDirectionRight;
    cell.revealDistance = 75.0f;
    cell.accessoryView = nil;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}


- (void)setAlertSettingCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UISwitch * onOff = [[UISwitch alloc] init];
    onOff.on = _appPreferences.alertNotOnWifi;
    onOff.backgroundColor = cache.labelTitleTextColor;
    onOff.onTintColor = [[UIColor greenColor] darkerColor];
    onOff.tintColor = cache.barTintColor;
    onOff.clipsToBounds = YES;
    onOff.layer.cornerRadius = 15.0f;
    [onOff addTarget:self action:@selector(didSlideAlertOption:) forControlEvents:UIControlEventValueChanged];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.accessoryView = onOff;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = @"Warn on Cellular Network";
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.clipsToBounds = YES;
    cell.layer.cornerRadius = 5.0f;
    cell.imageView.image = nil;
}

- (void)setAboutCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = @"About Rhythm Den";
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:cache.barTintColor];
    cell.imageView.image = nil;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}

- (void)setFeedbackCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = @"Send Feedback / Get Support";
    cell.imageView.image = [[UIImage imageNamed:@"message"] tintColor:cache.barTintColor];
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.accessoryView = nil;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}

- (void)setShareWithFriendsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = @"Share with Friends";
    cell.imageView.image = [[UIImage imageNamed:@"share"] tintColor:cache.barTintColor];
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.accessoryView = nil;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}

- (void)setTutorialsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = @"Tutorials";
    cell.imageView.image = [[UIImage imageNamed:@"help"] tintColor:cache.barTintColor];
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.accessoryView = [MSCellAccessory accessoryWithType:FLAT_DISCLOSURE_INDICATOR color:cache.barTintColor];
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}

- (void)setLibraryInfoCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    RDLibraryMetaModel * model = [[RDMusicRepository sharedInstance] libraryMeta];
    
    NSString * infoText = @"";
    
    if (model.totalAlbums > 0 && model.totalTracks > 0)
        infoText = [NSString stringWithFormat:@"%i Total Albums / %i Total Tracks\n", model.totalAlbums, model.totalTracks];
    
    NSUInteger dTotalSeconds = model.totalPlayTime;
    
    NSUInteger dHours = floor(dTotalSeconds / 3600);
    if (dHours > 0)
        infoText = [NSString stringWithFormat:@"%@%ihrs ", infoText, dHours];
    
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    if (dMinutes > 0)
        infoText = [NSString stringWithFormat:@"%@%imins ", infoText, dMinutes];
    
    if (dHours > 0 || dMinutes > 0)
        infoText = [NSString stringWithFormat:@"%@Total Listening Time", infoText];

    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont systemFontOfSize:13.0];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [cache.barTintColor darkerColor];
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.text = infoText;
    cell.imageView.image = nil;
    cell.accessoryView = nil;
}

- (void)setRateUsCell:(RDSwipeableTableViewCell *)cell forIndex:(NSIndexPath *)index
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = @"Rate Rhythm Den";
    cell.imageView.image = [[UIImage imageNamed:@"favorite"] tintColor:cache.barTintColor];
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;
    cell.accessoryView = nil;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
}


- (void)whipeOutAccount
{
    //
    // Clear dropbox info
    //
    [[DBSession sharedSession] removeCredentialsWith:_dropboxPreferences.userId];
    [[DBSession sharedSession] unlinkUserId:_dropboxPreferences.userId];

    [_dropboxPreferences removeAll];
    _appPreferences.lastSyncronized = nil;
    //
    // Update the UI
    //
    [self validateLibrarySyncronization];
    [self updateSyncronizationUI:@"Library not syncronized"];
    //
    // Update the info area
    //
    [self.preferenceView reloadData];
    //
    // Notification if we are in the background
    //
    if (_backgroundTaskID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] postNotificationMessage:@"Your library was cleared successfully! Add a new account?"];
    //
    // Send a notification letting the rest of the UI know we cleared the library
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicLibraryClearedNotification object:nil];
}


#pragma mark - Notifications

- (void)didReceiveNetworkConnectionChangedNotification:(NSNotification *)notification
{
    __block NetworkStatus status = [_reachability currentReachabilityStatus];
#ifdef DEBUG
    NSString * strStatus;
    switch (status) {
        case ReachableViaWWAN:
            strStatus = @"Cellular Network";
            break;
        case ReachableViaWiFi:
            strStatus = @"Wifi";
            break;
        default:
            strStatus = @"Offline";
            break;
    }
    NSLog(@"RDMusicPlayer - Internet connection changed to %@", strStatus);
#endif
    //
    // See if we are currently in the middle of synchronizing and if
    // our status changed to Cellular as well
    //
    RDMusicLibrary * library = [RDMusicLibrary sharedInstance];
    if (library.isSyncronizing && !_bCanSyncOnCellular && status == ReachableViaWWAN) {
        //
        // We are so stop everything
        //
        [library cancelSynchronization];
        while (library.isSyncronizing)
            [NSThread sleepForTimeInterval:1.0];
        //
        // If we are in background send a notification
        //
        if (_backgroundTaskID != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] postNotificationMessage:@"We've cancelled synchronization because your network connection has changed from WIFI to Cellular"];
        //
        // Now let the user know we cancelled synchronization because
        // the connection changed to cellular
        //
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                         message:@"Synchronization was cancelled because we are no longer on a WIFI connection"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
    }
}


- (void)didReceiveEnteredBackgroundNotification:(NSNotification *)notification
{
    RDMusicLibrary * library = [RDMusicLibrary sharedInstance];
    if ((library.isSyncronizing || _clearLibraryOp.operationCount > 0) && _backgroundTaskID == UIBackgroundTaskInvalid)
        [self startBackgroundTask];
}

- (void)didReceiveEnteredForegroundNotification:(NSNotification *)notification
{
    [self endBackgroundTask];
    //
    // See if we need to resume synchronization
    //
    __block RDMusicLibrary * library = [RDMusicLibrary sharedInstance];
    if (library.isOnPause) {
        [self showSyncronizationUI];
        [library resumeSynchronization];
    }
}

- (void)didReceiveLibrarySyncStartedNotification:(NSNotification *)notification
{
    [self showSyncronizationUI];
    //
    // Disable the delete account button
    //
    RDSwipeableTableViewCell * cell = (RDSwipeableTableViewCell *)[_preferenceView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.revealDirection = RDSwipeableTableViewCellRevealDirectionNone;
    //
    // Update the info area
    //
    [self.preferenceView reloadData];
}

- (void)didReceiveLibrarySyncCompleteNotification:(NSNotification *)notification
{
    [self updateSyncronizationUI:nil];
    //
    // Enable the delete account button
    //
    RDSwipeableTableViewCell * cell = (RDSwipeableTableViewCell *)[_preferenceView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.revealDirection = RDSwipeableTableViewCellRevealDirectionRight;
    //
    // Update the info area
    //
    [self.preferenceView reloadData];
    //
    // If we are in background send a notification
    //
    if (_backgroundTaskID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] postNotificationMessage:@"Synchronization is complete and your music library is now available! What would you like to play first?"];
}

- (void)didReceiveLibrarySyncCancelledNotification:(NSNotification *)notification
{
    [self updateSyncronizationUI:@"Synchronization was cancelled"];
    //
    // Enable the delete account button
    //
    RDSwipeableTableViewCell * cell = (RDSwipeableTableViewCell *)[_preferenceView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.revealDirection = RDSwipeableTableViewCellRevealDirectionRight;
    //
    // Update the info area
    //
    [self.preferenceView reloadData];
}

- (void)didReceiveLibrarySyncFailedNotification:(NSNotification *)notification
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                     message:@"An error occured while syncronizing your music library please try again"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
    [self updateSyncronizationUI:@"Synchronization failed"];
    //
    // Enable the delete account button
    //
    RDSwipeableTableViewCell * cell = (RDSwipeableTableViewCell *)[_preferenceView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.revealDirection = RDSwipeableTableViewCellRevealDirectionRight;
    //
    // Update the info area
    //
    [self.preferenceView reloadData];
    //
    // If we are in background send a notification
    //
    if (_backgroundTaskID != UIBackgroundTaskInvalid)
        [[UIApplication sharedApplication] postNotificationMessage:@"There was a problem synchronizing your music library"];
}

- (void)dropboxRegistrationComplete:(NSNotification *)notification
{
    NSNumber * result = [[notification userInfo] objectForKey:@"data"];
    BOOL isLinked = [result boolValue];
    if (isLinked) {
        [self savePreferences];
    }
    else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Dropbox Authentication"
                                                         message:@"Could not access your Dropbox account at this time. Please try again."
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
        
    }
}


#pragma mark - RDDropboxTutorialViewDelegate

- (void)dropboxTutorialDismissViewController:(RDDropboxTutorialViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
        controller.transitioningDelegate = nil;
    }];
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    DETAnimatedTransitionController * controller = (DETAnimatedTransitionController *)_animationController;
    controller.reverse = NO;
    
    return _animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    DETAnimatedTransitionController * controller = (DETAnimatedTransitionController *)_animationController;
    controller.reverse = YES;
    
    return _animationController;
}



#pragma mark - DBRestClientDelegate Protocol

-(void)restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info
{
    [_dropboxPreferences setUserDisplayName:info.displayName];
    [_dropboxPreferences setFolderPath:kDBRootAppFolder];
    
    [_dropboxClient createFolder:@"Music"];
    
    [self validateLibrarySyncronization];
    [self updateSyncronizationUI:@"Library not syncronized"];
    [_preferenceView reloadData];
    
    RDAppPreference * appPref = [RDAppPreference new];
    if (!appPref.shownDropboxTutorial) {
        RDDropboxTutorialViewController * tutorialController = (RDDropboxTutorialViewController *) [[self storyboard] instantiateViewControllerWithIdentifier:@"DropboxTutorial"];
        tutorialController.transitioningDelegate = self;
        tutorialController.delegate = self;
        
        [self presentViewController:tutorialController animated:YES completion:nil];
    }
}

-(void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error
{
    NSString * message = @"Could not access your box account at this time. Please check your internet connection and try again";
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Dropbox Authentication"
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
    
}




#pragma mark - RDSwipeableTableViewCell delegate methods

- (void)tableView:(UITableView *)tableView willBeginCellSwipe:(RDSwipeableTableViewCell *)cell inDirection:(RDSwipeableTableViewCellRevealDirection)direction
{
    if ([[cell.revealView subviews] count] == 0) {
        CGRect cellRect = cell.frame;
        
        UIButton * deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        deleteButton.backgroundColor = [[UIColor redColor] darkerColor];
        deleteButton.titleLabel.font = [UIFont systemFontOfSize:15];
        deleteButton.frame = CGRectMake(cellRect.size.width - 75, 0, 75, cellRect.size.height);
        deleteButton.clipsToBounds = YES;
        deleteButton.layer.cornerRadius = 5.0f;
        [deleteButton setImage:[[UIImage imageNamed:@"delete"] tintColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(didPressDeleteAccount) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.revealView addSubview:deleteButton];
        cell.revealView.backgroundColor = [[UIColor redColor] darkerColor];
    }

}



#pragma mark - UIActionSheetDelegate Protocol

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[RDMusicLibrary sharedInstance] syncronize];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate Protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:NO];
}


#pragma mark - MFMessageComposeViewControllerDelegate Protocol

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:NO];
}



#pragma mark - UITableViewDataSource Protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows;
    
    switch (section) {
        case SECTION_ACCOUNT:
            rows = 2;
            break;
            
        case SECTION_OPTIONS:
        case SECTION_ABOUT:
            rows = 1;
            break;
            
        case SECTION_HELP:
            rows = 4;
            break;
            
        default:
            rows = 0;
            break;
    }
    
    return rows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    /* Account, Options, Help, About */
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"Cell";
    
    RDSwipeableTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil) {
        cell = [[RDSwipeableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
    }
    
    
    switch (indexPath.section) {
        case SECTION_ACCOUNT:
        {
            if (indexPath.row == 0)
                [self setAccountCell:cell forIndex:indexPath];
            else
                [self setLibraryInfoCell:cell forIndex:indexPath];
            
            break;
        }
            
        case SECTION_OPTIONS:
        {
            if (indexPath.row == 0)
                [self setAlertSettingCell:cell forIndex:indexPath];
            
            break;
        }
            
        case SECTION_HELP:
        {
            if (indexPath.row == 0)
                [self setRateUsCell:cell forIndex:indexPath];
            else if (indexPath.row == 1)
                [self setFeedbackCell:cell forIndex:indexPath];
            else if (indexPath.row == 2)
                [self setShareWithFriendsCell:cell forIndex:indexPath];
            else if (indexPath.row == 3)
                [self setTutorialsCell:cell forIndex:indexPath];
            
            break;
        }
            
        case SECTION_ABOUT:
            [self setAboutCell:cell forIndex:indexPath];
            break;
            
        default:
            break;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 300, 20)];
    label.font = [UIFont fontWithName:@"Bebas" size:13.0];
    label.textColor = [[RDMusicResourceCache sharedInstance].buttonTextColor darkerColor];
    label.backgroundColor = [UIColor clearColor];
    label.shadowOffset = CGSizeMake(1, 1);
    label.shadowColor = [UIColor darkTextColor];
    label.contentMode = UIViewContentModeTop;
    
    switch (section) {
        case SECTION_ACCOUNT:
            label.text = @"Account";
            break;
            
        case SECTION_OPTIONS:
            label.text = @"Options";
            break;
            
        case SECTION_HELP:
            label.text = @"Help";
            break;
            
        case SECTION_ABOUT:
            label.text = @"About";
            break;

        default:
            break;
    }
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
    [view addSubview:label];
    
    return view;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case SECTION_ACCOUNT:
        {
            if (![[RDMusicLibrary sharedInstance] isSyncronizing]) {
                if (indexPath.row == 0 && indexPath.section == 0 && _dropboxPreferences.authToken == nil) {
                    if ([[DBSession sharedSession] isLinked]) {
                        //
                        // This happens when the user deletes the app without
                        // removing the user account so just unlink it everything
                        //
                        [[DBSession sharedSession] unlinkAll];
                    }
                        
                    [[DBSession sharedSession] linkFromController:self];
                }
            }
            break;
        }
        
        case SECTION_HELP:
        {
            if (indexPath.row == 0) {
                [[iRate sharedInstance] promptIfNetworkAvailable];
            } else if (indexPath.row == 1) {
                if ([MFMailComposeViewController canSendMail]) {
                    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                    NSString * build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                    NSString * iOSVersion = [[UIDevice currentDevice] systemVersion];
                    NSString * model = [[UIDevice currentDevice] model];
                    NSString * diagnostics = [NSString stringWithFormat:@"\n\n\n\nDiagnotics Information\n=================\nDevice: %@\niOS Version: %@\nRhythm Den Version: v%@ (Build %@)", model, iOSVersion, version, build];
                    MFMailComposeViewController * mailController = [[MFMailComposeViewController alloc] init];
                    [mailController setSubject:@"Feedback & Support"];
                    [mailController setToRecipients:@[@"support@rhythmdenapp.com"]];
                    [mailController setMessageBody:diagnostics isHTML:NO];
                    [mailController setMailComposeDelegate:self];
                    [self presentViewController:mailController animated:YES completion:NO];
                } else {
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                                     message:@"Sorry, you must enable Mail in order to use this feature"
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                    [alert show];
                }
            } else if (indexPath.row == 2) {
                
                if ([MFMessageComposeViewController canSendText]) {
                    MFMessageComposeViewController * messageController = [[MFMessageComposeViewController alloc] init];
                    [messageController setBody:@"Got a Dropbox account? Try out Rhythm Den music player http://bit.ly/1aRm8A6"];
                    [messageController setMessageComposeDelegate:self];
                    [self presentViewController:messageController animated:YES completion:nil];
                } else {
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                                     message:@"Sorry, you must enable Text Messaging in order to use this feature"
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                    [alert show];
                }
            } else if (indexPath.row == 3) {
                [self performSegueWithIdentifier:@"TutorialsSegue" sender:self];
            }

            break;
        }
            
        case SECTION_ABOUT:
        {
            [self performSegueWithIdentifier:@"AboutSegue" sender:self];
            break;
        }
            
        default:
            break;
    }
}


#pragma mark - UI Events

-(void)didPressSyncronizeLibrary:(id)sender
{
    RDMusicLibrary * library = [RDMusicLibrary sharedInstance];
    if (!library.isSyncronizing) {
        NetworkStatus status = [_reachability currentReachabilityStatus];
        //
        // Check connection
        //
        if (status == ReachableViaWWAN && _appPreferences.alertNotOnWifi) {
            _bCanSyncOnCellular = NO;
            //
            // Ask the user if they want to do this on cellular
            //
            RDInternetDetectionActionSheet * alert = [[RDInternetDetectionActionSheet alloc] init];
            if ([alert showInView:self.view.superview]) {
                _bCanSyncOnCellular = YES;
                [library syncronize];
            }
        } else {
            _bCanSyncOnCellular = !_appPreferences.alertNotOnWifi;
            [library syncronize];
        }
    } else {
        [self.refreshLibraryButton setTitle:@"Cancelling Sync..." forState:UIControlStateNormal];
        [self.refreshStatusLabel setText:@"Cancelling Synchronization..."];
        [library cancelSynchronization];
    }
}

- (void)didSlideAlertOption:(UISwitch *)sender
{
    _appPreferences.alertNotOnWifi = sender.on;
    _bCanSyncOnCellular = !_appPreferences.alertNotOnWifi;
}


- (void)didPressDeleteAccount
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Remove Account"
                                                     message:@"WARNING: Removing your account will remove all your music from your library! Are you sure you want to remove this account?"
                                                    delegate:nil
                                           cancelButtonTitle:@"No"
                                           otherButtonTitles:@"Yes", nil];
    
    RDAlertView * modalView = [[RDAlertView alloc] initWithAlert:alert];
    [modalView show];
    
    RDSwipeableTableViewCell * cell = (RDSwipeableTableViewCell *)[self.preferenceView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell resetToOriginalState];
    if (!modalView.cancelled) {
        cell.revealDirection = RDSwipeableTableViewCellRevealDirectionNone;
        //
        // Stop any music that is currently playing
        //
        RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
        [player stop];
        player.playlist = nil;
        //
        // Tell the library view screen to remove the Now Playing button
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackEndedNotification object:nil];
        //
        // See if we have any data in the library
        //
        RDLibraryMetaModel * model = [[RDMusicRepository sharedInstance] libraryMeta];
        if (model.totalTracks > 0) {
            [self performBlock:^{
                //
                // Snapshot what we look like and blur it
                //
                CGRect windowRect = [[UIScreen mainScreen] bounds];
                UIGraphicsBeginImageContextWithOptions(windowRect.size,NO,0.0f);
                [self.view drawViewHierarchyInRect:windowRect afterScreenUpdates:YES];
                UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                //
                // Blur it
                //
                GPUImageiOSBlurFilter *blurFilter = [GPUImageiOSBlurFilter new];
                blurFilter.blurRadiusInPixels = 5.0f;
                //
                // Let the UI know we've started the delete process
                //
                __block RDProgressView * progressView = [[RDProgressView alloc] initWithTitle:@"Clearing Library"];
                progressView.backgroundColor = [UIColor colorWithPatternImage:[blurFilter imageByFilteringImage:snapshotImage]];
                [self.tabBarController.view addSubview:progressView];
                [progressView show];
                //
                // Destroy their library
                //
                [_clearLibraryOp addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    RDMusicRepository * threadedRepository = [RDMusicRepository createThreadedInstance];
                    [threadedRepository deleteEverything:^(float progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progressView.progress = progress;
                            if (progress >= 1.0) {
                                [progressView hide];
                                [self whipeOutAccount];
                            }
                        });
                    }];
                }]];
            } afterDelay:0.5];
        } else {
            [self whipeOutAccount];
        }
    }
}


- (void)savePreferences
{
    NSString * userId = [[[DBSession sharedSession] userIds] objectAtIndex:0];
    MPOAuthCredentialConcreteStore * creds = [[DBSession sharedSession] credentialStoreForUserId:userId];
    [_dropboxPreferences setAuthToken:creds.accessToken];
    [_dropboxPreferences setUserId: userId];
    
    _dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:userId];
    _dropboxClient.delegate = self;
    [_dropboxClient loadAccountInfo];
}


@end
