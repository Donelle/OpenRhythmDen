//
//  BitlyLibUtil.m
//  BitlyLib
//
//  Created by Tracy Pesin on 6/27/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyLibUtil.h"

@implementation BitlyLibUtil

static NSString * const BitlyTwitterLastAccountKey = @"BitlyTwitterLastAccountKey";

static BitlyLibUtil *theInstance;

+ (BitlyLibUtil *)sharedBitlyUtil {
    if (!theInstance) {
        theInstance = [[BitlyLibUtil alloc] init];
    }
    return theInstance;
}

- (NSString *)lastAccountUsed {
    return [[NSUserDefaults standardUserDefaults] stringForKey:BitlyTwitterLastAccountKey];
}

- (void)setLastAccountUsed:(NSString *)lastAccountUsed {
      [[NSUserDefaults standardUserDefaults] setObject:lastAccountUsed forKey:BitlyTwitterLastAccountKey];
}


+ (NSString *)urlEncode:(NSString *)string
{
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                NULL,
                                                                (CFStringRef)string,
                                                                NULL,
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                kCFStringEncodingUTF8 ) autorelease];
}


+ (NSDictionary *)parseQueryString:(NSString *)query 
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *keyVal = [pair componentsSeparatedByString:@"="];
        if ([keyVal count] == 2) {
            [dict setObject:[keyVal objectAtIndex:1] forKey:[keyVal objectAtIndex:0]];
        } else if ([keyVal count] == 1) {
            [dict setObject:@"" forKey:[keyVal objectAtIndex:0]];
        }
    }
    return [dict autorelease];
}

@end
