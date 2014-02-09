//
//  UIApplication+RhythmDen.m
//  RhythmDen
//
//  Created by Donelle Sanders on 10/23/13.
//
//

#import "UIApplication+RhythmDen.h"

@implementation UIApplication (RhythmDen)

- (void)postNotificationMessage:(NSString *)message
{
    UILocalNotification * localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = message;
    localNotification.applicationIconBadgeNumber = self.applicationIconBadgeNumber + 1;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

@end
