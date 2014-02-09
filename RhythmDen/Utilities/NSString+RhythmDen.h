//
//  NSString+RhythmDen.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 11/12/13.
//
//

#import <Foundation/Foundation.h>
//
//  Created by Nicholas Bruning on 5/12/11.
//  Copyright (c) 2011 Involved Pty Ltd. All rights reserved.
//
enum{
    NSStringScoreOptionNone                         = 1 << 0,
    NSStringScoreOptionFavorSmallerWords            = 1 << 1,
    NSStringScoreOptionReducedLongStringPenalty     = 1 << 2
};

typedef NSUInteger NSStringScoreOption;

@interface NSString (RhythmDen)
- (NSString *)urlEscapeString;
- (NSString *)removeAllWhitespaces;
- (float) scoreAgainst:(NSString *)otherString;
- (float) scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness;
- (float) scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness options:(NSStringScoreOption)options;

@end
