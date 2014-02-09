//
//  RDViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 12/29/11.
//  Copyright (c) 2011 The Potter's Den, Inc. All rights reserved.
//

#import "RDViewController.h"
#import "RDMusicResourceCache.h"
#import "RDMusicPlayer.h"

@implementation RDViewController

#pragma mark - View Life Cycle

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    // Set the background and navigationbar look and feel
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UIImage * background = [cache gradientImageByKey:ResourceCacheViewBackColorKey withRect:self.view.bounds withColors:cache.viewGradientBackColors];
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:background]];
    
    [self.navigationController.navigationBar setBackgroundImage:cache.transparentImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}


- (void)viewDidAppear:(BOOL)animated
{
    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDViewController - didReceiveMemoryWarning was called on %@", self);
#endif
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark - Instance Methods

- (void)registerForNotificationWith:(SEL)selector
{
    NSString * name = [NSString stringWithFormat:@"%@Notification", NSStringFromSelector(selector)];
    [self registerForNotificationWith:selector forName:name];
}


-(void)registerForNotificationWith:(SEL)selector forName:(NSString *)name
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:name object:nil];
}

- (void)unregisterForNotificationWith:(SEL)selector
{
    NSString * name = [NSString stringWithFormat:@"%@Notification", NSStringFromSelector(selector)];
    [self unregisterForNotificationWith:selector forName:name];
}

-(void)unregisterForNotificationWith:(SEL)selector forName:(NSString *)name
{
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:name];
}

- (void)postNotification:(SEL)selector
{
    [self postNotification:selector withObject:nil];   
}

- (void)postNotification:(SEL)selector withObject:(id)data
{
    NSString * name = [NSString stringWithFormat:@"%@Notification", NSStringFromSelector(selector)];
    NSDictionary * userdata = [[NSDictionary alloc] initWithObjectsAndKeys:data, @"data", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userdata];
}

@end
