//
//  RDViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/29/11.
//  Copyright (c) 2011 The Potter's Den. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UINavigationController+RDViewRotationSupport.h"

@interface RDViewController : UIViewController

- (void)registerForNotificationWith:(SEL)selector;
- (void)registerForNotificationWith:(SEL)selector forName:(NSString *)name;
- (void)unregisterForNotificationWith:(SEL)selector;
- (void)unregisterForNotificationWith:(SEL)selector forName:(NSString *)name;
- (void)postNotification:(SEL)selector;
- (void)postNotification:(SEL)selector withObject:(id)data;

@end
