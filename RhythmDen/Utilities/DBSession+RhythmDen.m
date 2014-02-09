//
//  DBSession+RhythmDen.m
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "DBSession+RhythmDen.h"

@implementation DBSession (RhythmDen)

-(void)removeCredentialsWith:(NSString *)userId
{
    // 
    // This totally removes the current user info from the system's defaults
    //
    [credentialStores removeObjectForKey:userId];
    [self performSelector:@selector(saveCredentials)];
}
@end
