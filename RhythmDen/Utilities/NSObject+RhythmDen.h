//
//  NSObject+RhythmDen.h
//  RhythmDen
//
//  Created by Donelle Sanders on 9/26/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (RhythmDen)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;
- (void)cancelBlockRequest:(void (^)(void))block;

- (void)performBlockInBackground:(void (^)(void))block;
- (void)performBlock:(void (^)(void))block onThread:(NSThread *)thread;

@end
