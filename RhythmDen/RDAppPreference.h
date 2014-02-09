//
//  RDAppPreference.h
//  RhythmDen
//
//  Created by Donelle Sanders on 1/8/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//
#import "RDPreference.h"

typedef enum {
    RDSortByAlbumPreference = 1,
    RDSortByArtistPreference = 2
}RDSortPreference ;


@interface RDAppPreference : RDPreference 

@property (strong, nonatomic) NSDate * lastSyncronized;
@property (assign, nonatomic) BOOL alertNotOnWifi;
@property (assign, nonatomic) RDSortPreference librarySortBy;
@property (assign, nonatomic) BOOL shownDropboxTutorial;
@property (assign, nonatomic) BOOL shownPlayerTutorial;

@end
