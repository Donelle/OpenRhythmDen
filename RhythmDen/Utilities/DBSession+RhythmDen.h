//
//  DBSession+RhythmDen.h
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import <DropboxSDK/DBSession.h>

@interface DBSession (RhythmDen)
-(void)removeCredentialsWith:(NSString *)userId;

@end
