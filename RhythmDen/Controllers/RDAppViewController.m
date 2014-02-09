//
//  RDAppViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 6/23/13.
//
//

#import "RDAppViewController.h"
#import "RDMusicResourceCache.h"
#import "RDAppPreference.h"
#import "RDAlertView.h"


@implementation RDAppViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    //
    // Set the background
    //
    UIImage * background = [cache gradientImageByKey:ResourceCacheViewBackColorKey withRect:self.view.bounds withColors:cache.viewGradientBackColors];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:background]];
    //
    // Set the color scheme
    //
    self.tabBar.barTintColor = cache.tabBarBackgroundColor;
    self.tabBar.tintColor = cache.labelTitleTextColor;
    //
    // Now determine if this is the first use. Indirectly we are determining
    // this by checking if both tutorials have not been done. The first time
    // the user successfully adds a dropbox account the tutorial will immediately
    // popup. After the user is able to sync their library, the first time they
    // access the player a popup will show as well.
    //
    RDAppPreference * preference = [RDAppPreference new];
    if (!preference.shownPlayerTutorial && !preference.shownDropboxTutorial) {
        //
        // We are in first use so switch to the preference tab
        //
        NSUInteger ndx = self.viewControllers.count - 1;
        [self setSelectedIndex:ndx];
    }
    
#ifdef BETA_TESTING
    NSLog(@"====[THIS IS A BETA TESTING BUILD]====");
    //
    // Make sure we don't work after beta expires
    //
    if ([self isBetaExpired]) {
        [self performBlock:^{
            NSString * message = @"Thank you for participating in the Beta Testing program! \
                                   To continue using Rhythm Den please download the release version from the App Store";
            
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:nil, nil];
            
            RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
            [modalAlert show];
        } afterDelay:5.0];
    }
#endif
}


- (BOOL)shouldAutorotate
{
    return [self.selectedViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.selectedViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.selectedViewController preferredInterfaceOrientationForPresentation];
}

#pragma mark - Instance Methods


- (BOOL)isBetaExpired
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd"];
    
    NSDate * exprDate = [dateFormat dateFromString:@"20131031"];
    return [exprDate compare:[NSDate date]]  == NSOrderedAscending;
}

@end
