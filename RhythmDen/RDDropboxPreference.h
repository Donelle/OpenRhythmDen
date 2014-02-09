//
//  RDDropboxPreference.h
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "RDPreference.h"

@interface RDDropboxPreference : RDPreference

@property (strong, nonatomic) NSString * authToken;
@property (strong, nonatomic) NSString * folderPath;
@property (strong, nonatomic) NSString * folderDisplayName;
@property (strong, nonatomic) NSString * userId;
@property (strong, nonatomic) NSString * userDisplayName;

- (void)removeAll;

@end
