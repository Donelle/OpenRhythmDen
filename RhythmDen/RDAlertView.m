//
//  RDAlertView.m
//  RhythmDen
//
//  Created by Donelle Sanders on 10/3/13.
//
//

#import "RDAlertView.h"

@implementation RDAlertView
{
    UIAlertView * _alertView;
}

@synthesize cancelled = _cancelled;

- (id)initWithAlert:(UIAlertView *)alertView
{
    if (self = [super init]) {
        _alertView = alertView;
        _alertView.delegate = self;
    }
    return self;
}

- (void)show
{
    [_alertView show];
    CFRunLoopRun ();
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    _cancelled = buttonIndex == 0;
    CFRunLoopStop(CFRunLoopGetCurrent());
}


@end
