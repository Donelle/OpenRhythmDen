//
//  RDMusicLibrary.h
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RDModels.h"
#import "RDAppPreference.h"

@interface RDMusicRepository : NSObject
@property (readonly, nonatomic) NSManagedObjectContext * managedObjectContext;

+ (RDMusicRepository *)sharedInstance;
+ (RDMusicRepository *)createThreadedInstance;

- (NSFetchedResultsController *)musicLibraryControllerBySort:(RDSortPreference)sortBy;
- (NSFetchedResultsController *)searchLibraryControllerWith:(NSString *)queryText sortBy:(RDSortPreference)sortBy;

- (NSArray *)albumModelsByTitle:(NSString *)title;
- (RDAlbumModel *)albumModelByLocation:(NSString *)location;
- (RDAlbumModel *)albumModelWithTitle:(NSString *)title andLocation:(NSString *)location;

- (NSArray *)artistModelsByName:(NSString *)artistName;
- (RDArtistModel *)artistModelWithName:(NSString *)artistName;

- (RDTrackModel *)trackModelWithName:(NSString *)trackName;
- (RDTrackModel *)trackByLocation:(NSString *)trackLocation;

- (RDPlaylistModel *)playlistModelWithName:(NSString *)name;
- (NSArray *)playlistModels;
- (RDPlaylistModel *)playlistByName:(NSString *)name;
- (NSFetchedResultsController *)mixLibraryController;

- (RDLibraryMetaModel *)libraryMeta;
- (void)updatePlayTime:(double)seconds;

- (void)insertSyncMetaModelWithLocation:(NSString *)location withHash:(NSString *)hash;
- (RDDropboxSyncMetaModel *)syncMetaModelByLocation:(NSString *)location;
- (void)syncMetaModelDeleteAll;
- (NSArray *)syncMetaModels;

- (void)saveChanges;
- (void)synchronizeRepository:(NSArray *)albumLocations;
- (void)deleteModel:(NSManagedObject *)model;
- (void)deleteEverything:(void (^)(float progress))updateProgress;

@end
