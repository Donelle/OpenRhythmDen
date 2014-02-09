//
//  NSArray+RDSafeNSArray.h
//  RhythmDen
//
//  Created by Donelle Sanders on 6/23/13.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (RhythmDen)

- (id)safeObjectAtIndex:(NSUInteger)index;

@end

@interface NSMutableArray (RhythmDen)
- (void)shuffle;
@end