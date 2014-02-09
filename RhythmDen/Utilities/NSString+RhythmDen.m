//
//  NSString+RhythmDen.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 11/12/13.
//
//

#import "NSString+RhythmDen.h"

@implementation NSString (RhythmDen)

- (NSString*)urlEscapeString
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)self;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, CFSTR("!*'();:@=+$,/?%#[]\" "),kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    
    return [s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp"];
}

- (NSString *)removeAllWhitespaces
{
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}

//
//  Created by Nicholas Bruning on 5/12/11.
//  Copyright (c) 2011 Involved Pty Ltd. All rights reserved.
//

- (float) scoreAgainst:(NSString *)otherString
{
    return [self scoreAgainst:otherString fuzziness:nil];
}

- (float) scoreAgainst:(NSString *)otherString fuzziness:(NSNumber *)fuzziness
{
    return [self scoreAgainst:otherString fuzziness:fuzziness options:NSStringScoreOptionNone];
}

- (float) scoreAgainst:(NSString *)anotherString fuzziness:(NSNumber *)fuzziness options:(NSStringScoreOption)options
{
    NSMutableCharacterSet *workingInvalidCharacterSet = [NSCharacterSet lowercaseLetterCharacterSet];
    [workingInvalidCharacterSet formUnionWithCharacterSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    [workingInvalidCharacterSet addCharactersInString:@" "];
    NSCharacterSet *invalidCharacterSet = [workingInvalidCharacterSet invertedSet];
    
    NSString *string = [[[self decomposedStringWithCanonicalMapping] componentsSeparatedByCharactersInSet:invalidCharacterSet] componentsJoinedByString:@""];
    NSString *otherString = [[[anotherString decomposedStringWithCanonicalMapping] componentsSeparatedByCharactersInSet:invalidCharacterSet] componentsJoinedByString:@""];
    
    // If the string is equal to the abbreviation, perfect match.
    if([string isEqualToString:otherString]) return (float) 1.0f;
    
    //if it's not a perfect match and is empty return 0
    if([otherString length] == 0) return (float) 0.0f;
    
    float totalCharacterScore = 0;
    NSUInteger otherStringLength = [otherString length];
    NSUInteger stringLength = [string length];
    BOOL startOfStringBonus = NO;
    float otherStringScore;
    float fuzzies = 1;
    float finalScore;
    
    // Walk through abbreviation and add up scores.
    for(uint index = 0; index < otherStringLength; index++){
        float characterScore = 0.1;
        NSInteger indexInString = NSNotFound;
        NSString *chr;
        NSRange rangeChrLowercase;
        NSRange rangeChrUppercase;
        
        chr = [otherString substringWithRange:NSMakeRange(index, 1)];
        
        //make these next few lines leverage NSNotfound, methinks.
        rangeChrLowercase = [string rangeOfString:[chr lowercaseString]];
        rangeChrUppercase = [string rangeOfString:[chr uppercaseString]];
        
        if(rangeChrLowercase.location == NSNotFound && rangeChrUppercase.location == NSNotFound){
            if(fuzziness){
                fuzzies += 1 - [fuzziness floatValue];
            } else {
                return 0; // this is an error!
            }
            
        } else if (rangeChrLowercase.location != NSNotFound && rangeChrUppercase.location != NSNotFound){
            indexInString = MIN(rangeChrLowercase.location, rangeChrUppercase.location);
            
        } else if(rangeChrLowercase.location != NSNotFound || rangeChrUppercase.location != NSNotFound){
            indexInString = rangeChrLowercase.location != NSNotFound ? rangeChrLowercase.location : rangeChrUppercase.location;
            
        } else {
            indexInString = MIN(rangeChrLowercase.location, rangeChrUppercase.location);
            
        }
        
        // Set base score for matching chr
        
        // Same case bonus.
        if(indexInString != NSNotFound && [[string substringWithRange:NSMakeRange(indexInString, 1)] isEqualToString:chr]){
            characterScore += 0.1;
        }
        
        // Consecutive letter & start-of-string bonus
        if(indexInString == 0){
            // Increase the score when matching first character of the remainder of the string
            characterScore += 0.6;
            if(index == 0){
                // If match is the first character of the string
                // & the first character of abbreviation, add a
                // start-of-string match bonus.
                startOfStringBonus = YES;
            }
        } else if(indexInString != NSNotFound) {
            // Acronym Bonus
            // Weighing Logic: Typing the first character of an acronym is as if you
            // preceded it with two perfect character matches.
            if( [[string substringWithRange:NSMakeRange(indexInString - 1, 1)] isEqualToString:@" "] ){
                characterScore += 0.8;
            }
        }
        
        // Left trim the already matched part of the string
        // (forces sequential matching).
        if(indexInString != NSNotFound){
            string = [string substringFromIndex:indexInString + 1];
        }
        
        totalCharacterScore += characterScore;
    }
    
    if(NSStringScoreOptionFavorSmallerWords == (options & NSStringScoreOptionFavorSmallerWords)){
        // Weigh smaller words higher
        return totalCharacterScore / stringLength;
    }
    
    otherStringScore = totalCharacterScore / otherStringLength;
    
    if(NSStringScoreOptionReducedLongStringPenalty == (options & NSStringScoreOptionReducedLongStringPenalty)){
        // Reduce the penalty for longer words
        float percentageOfMatchedString = otherStringLength / stringLength;
        float wordScore = otherStringScore * percentageOfMatchedString;
        finalScore = (wordScore + otherStringScore) / 2;
        
    } else {
        finalScore = ((otherStringScore * ((float)(otherStringLength) / (float)(stringLength))) + otherStringScore) / 2;
    }
    
    finalScore = finalScore / fuzzies;
    
    if(startOfStringBonus && finalScore + 0.15 < 1){
        finalScore += 0.15;
    }
    
    return finalScore;
}

@end
