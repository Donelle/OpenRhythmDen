//
//  RDDropboxPreference.m
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "RDDropboxPreference.h"

@implementation RDDropboxPreference

- (void)setAuthToken:(NSString *)authToken
{
    [self write:authToken forKey:@"AuthToken"];
}

- (NSString *)authToken
{
    return [self read:@"AuthToken"];
}

- (void)setFolderPath:(NSString *)folderPath
{
    [self write:folderPath forKey:@"FolderPath"];
}

- (NSString *)folderPath
{
    return [self read:@"FolderPath"];
}

-(void)setUserId:(NSString *)userId
{
    [self write:userId forKey:@"UserId"];
}

-(NSString *)userId
{
    return [self read:@"UserId"];
}

-(void)setUserDisplayName:(NSString *)name
{
    [self write:name forKey:@"UserDisplayName"];
}

-(NSString *)userDisplayName
{
    return [self read:@"UserDisplayName"];
}

-(void)removeAll
{
    [self deleteKey:@"AuthToken"];
    [self deleteKey:@"FolderPath"];
    [self deleteKey:@"UserId"];
    [self deleteKey:@"Enabled"];
    [self deleteKey:@"FolderDisplayName"];
    [self deleteKey:@"UserDisplayName"];
}



@end
