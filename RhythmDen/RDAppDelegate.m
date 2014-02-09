//
//  RDAppDelegate.m
//  RhythmDen
//
//  Created by Donelle Sanders on 12/27/11.
//  Copyright (c) 2011 The Potter's Den, Inc. All rights reserved.
//

#import "RDAppDelegate.h"
#import "RDMusicResourceCache.h"
#import "RDMusicPlayer.h"
#import "RDMusicLibrary.h"
#import "RDMusicRepository.h"
#import "DropboxSDK.h"
#import "BitlyConfig.h"
#import "iRate.h"


// RhythmDen's Access Creds
#define DROPBOX_APPKEY @""
#define DROPBOX_APPSECRET @""
#define BITLY_APPKEY @""
#define BITLY_APPLOGIN @""

@implementation RDAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //
    // Initialize shared componentsm,
    //
    [[RDMusicResourceCache sharedInstance] initializeTheme];
    [RDMusicRepository sharedInstance];
    [RDMusicPlayer sharedInstance];
    //
    // Setup Dropbox
    //
    DBSession * dbSession = [[DBSession alloc] initWithAppKey:DROPBOX_APPKEY appSecret:DROPBOX_APPSECRET root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    //
    // Setup Bitly
    //
    [[BitlyConfig sharedBitlyConfig] setBitlyLogin:BITLY_APPLOGIN bitlyAPIKey:BITLY_APPKEY];
    //
    // Setup iRate
    //
    [iRate sharedInstance].daysUntilPrompt = 10;
    [iRate sharedInstance].usesUntilPrompt = 15;
    //
    // Reset the badges
    //
    application.applicationIconBadgeNumber = 0;
    //
    // Subscribe to remote control events
    //
    [application beginReceivingRemoteControlEvents];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        BOOL isLinked = [[DBSession sharedSession] isLinked];
        NSDictionary * userdata = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:isLinked], @"data", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"dropboxRegistrationComplete:Notification" object:self userInfo:userdata];
        
        return YES;
    }
    
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
        {
            if (player.isPaused ) {
                [player resume];
            } else if (player.isPlaying) {
                [player pause];
            }
            break;
        }
            
        case UIEventSubtypeRemoteControlStop:
            [player stop];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [player pause];
            break;
            
        case UIEventSubtypeRemoteControlPlay:
        {
            [player resume];
            break;
        }
            
        case UIEventSubtypeRemoteControlNextTrack:
        {
            [player playNextTrack];
            break;
        }
            
        case UIEventSubtypeRemoteControlPreviousTrack:
        {
            [player playPrevTrack];
            break;
        }
            
        default:
            break;
    }
}


@end
