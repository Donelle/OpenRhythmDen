//
//  RDAppPreference.m
//  RhythmDen
//
//  Created by Donelle Sanders on 1/8/12.
//  Copyright (c) 2012 The Potter's Den. All rights reserved.
//

#import "RDAppPreference.h"

@implementation RDAppPreference

-(void)setLastSyncronized:(NSDate *)lastSyncronized
{
    [super write:lastSyncronized forKey:@"LastSyncronized"];
}

-(NSDate *)lastSyncronized
{
    return [super read:@"LastSyncronized"];
}

- (void)setAlertNotOnWifi:(BOOL)alertNotOnWifi
{
    [super write:[NSNumber numberWithBool:alertNotOnWifi] forKey:@"AlertNotOnWifi"];
}

- (BOOL)alertNotOnWifi
{
    NSNumber * value = [super read:@"AlertNotOnWifi"];
    return value != nil ? [value boolValue] : YES;
}

- (void)setLibrarySortBy:(RDSortPreference)librarySortBy
{
    [super write:[NSNumber numberWithInt:librarySortBy] forKey:@"LibrarySortBy"];
}

- (RDSortPreference)librarySortBy
{
    NSNumber * value = [super read:@"LibrarySortBy"];
    return (value.intValue == RDSortByAlbumPreference || value.intValue == RDSortByArtistPreference) ?
        value.intValue : RDSortByAlbumPreference;
}

- (void)setShownDropboxTutorial:(BOOL)shownDropboxTutorial
{
    [super write:[NSNumber numberWithBool:shownDropboxTutorial] forKey:@"ShownDropboxTutorial"];
}

- (BOOL)shownDropboxTutorial
{
    NSNumber * value = [super read:@"ShownDropboxTutorial"];
    return value != nil ? [value boolValue] : FALSE;
}

- (void)setShownPlayerTutorial:(BOOL)shownPlayerTutorial
{
    [super write:[NSNumber numberWithBool:shownPlayerTutorial] forKey:@"ShownPlayerTutorial"];
}

- (BOOL)shownPlayerTutorial
{
    NSNumber * value = [super read:@"ShownPlayerTutorial"];
    return value != nil ? [value boolValue] : FALSE;
}

@end
