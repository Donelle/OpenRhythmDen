//
//  NSObject+RhythmDen.m
//  RhythmDen
//
//  Created by Donelle Sanders on 9/26/13.
//
//

#import "NSObject+RhythmDen.h"

@implementation NSObject (RhythmDen)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(fireBlock:) withObject:block afterDelay:delay];
}

- (void)cancelBlockRequest:(void (^)(void))block
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireBlock:) object:block];
}

- (void)performBlock:(void (^)(void))block onThread:(NSThread *)thread
{
    [self performSelector:@selector(fireBlock:) onThread:thread withObject:block waitUntilDone:NO];
}

- (void)performBlockInBackground:(void (^)(void))block
{
    [self performSelectorInBackground:@selector(fireBlock:) withObject:block];
}


- (void)fireBlock:(void (^)(void))block {
    block();
}

@end
