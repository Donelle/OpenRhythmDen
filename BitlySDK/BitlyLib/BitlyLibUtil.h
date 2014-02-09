//
//  BitlyLibUtil.h
//  BitlyLib
//
//  Created by Tracy Pesin on 6/27/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitlyLibUtil : NSObject

@property (nonatomic, retain) NSString *lastAccountUsed;

+ (NSString *)urlEncode:(NSString *)string;
+ (NSDictionary *)parseQueryString:(NSString *)query;

+ (BitlyLibUtil *)sharedBitlyUtil;


@end
