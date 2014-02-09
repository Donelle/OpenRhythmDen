//
//  RDActionSheet.m
//  RhythmDen
//
//  Created by Donelle Sanders on 6/23/13.
//
//

#import "RDInternetDetectionActionSheet.h"
#import "RDAppPreference.h"
#import "Reachability.h"

@implementation RDInternetDetectionActionSheet
{
    BOOL _bResult;
}


- (BOOL)hasInternetConnectivity
{
    NetworkStatus status = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (status == NotReachable) {
        //
        // Internet is not reachable so display the alert
        //
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                         message:@"Unable to connect to the internet please check your network settings"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
        return NO;
    }

    return YES;
}


- (BOOL)showInView:(UIView *)view
{
    BOOL bCanUseWifi = NO;
    
    do {
        //
        // See if we have internet connection period
        //
        if (![self hasInternetConnectivity])
            break;
        //
        // Check to see if we are on wifi
        //
        NetworkStatus status  = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
        bCanUseWifi = status != NotReachable;
        if (bCanUseWifi) break;
        //
        // We are not on wifi so lets see if we need to alert the user
        //
        RDAppPreference * preferences = [[RDAppPreference alloc] init];
        bCanUseWifi = !preferences.alertNotOnWifi;
        if (bCanUseWifi) break;
        //
        // We do so lets show the alert
        //
        UIActionSheet * alert = [[UIActionSheet alloc] initWithTitle:@"You are currently NOT USING WIFI do you wish to continue?"
                                                            delegate:self
                                                   cancelButtonTitle:@"NO"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:@"YES", nil];
        alert.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        if ([view isKindOfClass:[UITabBar class]]) {
            [alert showFromTabBar:(UITabBar *)view];
        } else {
            [alert showInView:view];
        }
        //
        // Wait until we get an answer
        //
        CFRunLoopRun();
        bCanUseWifi = _bResult;
    }while (false);
    
    
    return bCanUseWifi;
}


#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _bResult = buttonIndex != 1;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
