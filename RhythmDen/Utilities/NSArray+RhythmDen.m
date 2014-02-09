//
//  NSArray+RDSafeNSArray.m
//  RhythmDen
//
//  Created by Donelle Sanders on 6/23/13.
//
//

#import "NSArray+RhythmDen.h"

@implementation NSArray (RhythmDen)

- (id)safeObjectAtIndex:(NSUInteger)index
{
    if (self.count > index) {
        return [self objectAtIndex:index];
    }
    
    return nil;
}

@end


@implementation NSMutableArray (RhythmDen)

- (void)shuffle
{
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = arc4random_uniform(nElements) + i;
        [self exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

@end
