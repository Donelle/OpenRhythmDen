//
//  UINavigationController+RDViewRotationSupport.m
//  RhythmDen
//
//  Created by Donelle Sanders on 5/19/13.
//
//

#import "UINavigationController+RDViewRotationSupport.h"

@implementation UINavigationController (RDViewRotationSupport)

-(BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
