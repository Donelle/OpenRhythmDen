//
//  RDMusicLibrary.m
//  RhythmDen
//
//  Created by Donelle Sanders on 1/11/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//
#import "RDMusicRepository.h"

@interface RDMusicRepository ()  {
@private
    RDAppPreference * _preferences;
    NSManagedObjectContext * _managedObjectContext;
}

- (void)initiateContext:(NSPersistentStoreCoordinator *)coordinator;
@end

@implementation RDMusicRepository
@synthesize managedObjectContext = _managedObjectContext;

- (id)init 
{
    self = [super init];
    if (self != nil) {
        _preferences = [[RDAppPreference alloc] init];
    }
    
    return self;
}

-(void)initiateContext:(NSPersistentStoreCoordinator *)coordinator
{
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return _managedObjectContext;
}


- (void)didReceiveMergeChangesNotification:(NSNotification *)notification
{
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    [_managedObjectContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
}


#pragma mark - Instance Methods

-(void)saveChanges
{
    @try {
        NSError * errors = nil;
        BOOL bSuccessful = [_managedObjectContext save:&errors];
#ifdef DEBUG
        if (!bSuccessful) {
            NSLog(@"Saving changes to disk failed with: %@", errors);
        }
#endif
    }
    @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"Saving changes to disk failed with: %@", exception);
#endif
    }
}


- (void)synchronizeRepository:(NSArray *)albumLocations
{
    if (albumLocations.count > 0) {
        NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
        NSError * errors = nil; NSArray * fetchedObjects = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
        if (errors != nil) {
            NSLog(@"Errors occured fetching ablums: %@", errors);
        }
#endif
       
        [fetchedObjects enumerateObjectsUsingBlock:^(id model, NSUInteger idx, BOOL *stop) {
            RDAlbumModel * album = (RDAlbumModel *)model;
            __block BOOL bFound = NO;
            //
            // search for the album title in the list
            //
            [albumLocations enumerateObjectsUsingBlock:^(id location, NSUInteger idx, BOOL *stop) {
                if ([album.albumLocation compare:location options:NSCaseInsensitiveSearch] == NSOrderedSame)
                    *stop = bFound = YES;
            }];
            
            if (!bFound) {
#ifdef DEBUG
                NSLog(@"Removing Ablum: %@ with Location: %@", album.albumTitle, album.albumLocation);
#endif
                //
                // Remove album from related artists
                //
                RDArtistModel * artist = [album albumArtists];
                [artist removeArtistAlbumsObject:album];
                //
                // If we are not related to any other albums delete us
                //
                if (artist.artistAlbums.count == 0)
                    [_managedObjectContext deleteObject:artist];
                //
                // Remove all the tracks on the album
                //
                [album.albumTracks enumerateObjectsUsingBlock:^(id objTrack, BOOL *stop) {
                    RDTrackModel * track = (RDTrackModel *)objTrack;
                    [_managedObjectContext deleteObject:track];
                }];
                //
                // Remove all sync data associated with album
                //
                RDDropboxSyncMetaModel * syncModel = [self syncMetaModelByLocation:album.albumLocation];
                if (syncModel) [_managedObjectContext deleteObject:syncModel];
                //
                // Now remove the album
                //
                [_managedObjectContext deleteObject:album];
            }
        }];
        
        [self saveChanges];
    }
}


- (void)deleteEverything:(void (^)(float))updateProgress
{
    @autoreleasepool {
        NSArray * entities = @[ @"Track", @"Artist", @"Album", @"Playlist"];
        __block NSMutableArray * managedObjects = [NSMutableArray array];
        //
        // Queue up all the objects to delete
        //
        [entities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    
            NSFetchRequest * request = [[NSFetchRequest alloc] init];
            [request setEntity:[NSEntityDescription entityForName:obj inManagedObjectContext:_managedObjectContext]];
            [request setIncludesPropertyValues:NO];
            
            NSError * error = nil;
            NSArray * results = [_managedObjectContext executeFetchRequest:request error:&error];
#ifdef DEBUG
            if (error != nil) {
                NSLog(@"Errors occured fetching %@: %@", obj, error);
            }
#endif  
            [managedObjects addObjectsFromArray:results];
        }];
        //
        // Delete the sync data
        //
        [self syncMetaModelDeleteAll];
        //
        // Now do the delete them
        //
        NSUInteger totalObjects = managedObjects.count;
        [managedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self deleteModel:obj];
            [self saveChanges];
            
            float progress = ((idx + 1.0) / totalObjects);
            updateProgress (progress);
        }];
    }
}

- (void)deleteModel:(NSManagedObject *)model
{
    [_managedObjectContext deleteObject:model];
    [self saveChanges];
}

- (NSFetchedResultsController *)createLibraryController:(NSPredicate *)predicate sortBy:(RDSortPreference)sortBy useCache:(NSString *)cacheName useKeyPath:(NSString *)sectionKeyPath
{
    NSFetchedResultsController * controller = nil;
    NSFetchRequest * request = nil;
    
    switch (sortBy) {
        case RDSortByAlbumPreference:
        {
            NSSortDescriptor * sortbyName = [[NSSortDescriptor alloc] initWithKey:@"albumTitle" ascending:YES selector:@selector(caseInsensitiveCompare:)];
            
            request = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
            [request setSortDescriptors:@[sortbyName]];
            [request setFetchBatchSize:20];
            [request setPredicate:predicate];
            
            break;
        }
            
        case RDSortByArtistPreference:
        {
            NSSortDescriptor * sortbyName = [[NSSortDescriptor alloc] initWithKey:@"artistName" ascending:YES selector:@selector(caseInsensitiveCompare:)];
            
            request = [[NSFetchRequest alloc] initWithEntityName:@"Artist"];
            [request setSortDescriptors:@[sortbyName]];
            [request setFetchBatchSize:20];
            [request setPredicate:predicate];
            
            break;
        }
            
        default:
            break;
    }
    
    controller =
        [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                            managedObjectContext:_managedObjectContext
                                              sectionNameKeyPath:sectionKeyPath
                                                       cacheName:cacheName];
    NSError * errors = nil;
    BOOL bSucceeded = [controller performFetch:&errors];
#ifdef DEBUG
    if (!bSucceeded)
    {
        NSLog(@"Errors occured fetching ablums: %@", errors);
    }
#endif
    return controller;
}

- (NSFetchedResultsController *)searchLibraryControllerWith:(NSString *)queryText sortBy:(RDSortPreference)sortBy
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"albumTitle contains[c] %@", queryText];
    if (sortBy == RDSortByArtistPreference)
        predicate = [NSPredicate predicateWithFormat:@"artistName contains[c] %@", queryText];
    
    return [self createLibraryController:predicate sortBy:sortBy useCache:nil useKeyPath:nil];
}

- (NSFetchedResultsController *)musicLibraryControllerBySort:(RDSortPreference)sortBy
{
    return [self createLibraryController:Nil sortBy:sortBy useCache:@"musicLibrary" useKeyPath:@"firstLetter"];
}

-(NSArray *)albumModelsByTitle:(NSString *)title
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"albumTitle like %@", title];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * albums = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching albums: %@", errors);
    }
#endif 
    
    return albums;
}

- (RDAlbumModel *)albumModelByLocation:(NSString *)location
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"albumLocation like[c] %@", location];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * albums = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching albums: %@", errors);
    }
#endif
    
    return albums.count == 1 ? [albums objectAtIndex:0] : nil;
}


-(RDAlbumModel *)albumModelWithTitle:(NSString *)title andLocation:(NSString *)location
{
    RDAlbumModel * album = [NSEntityDescription insertNewObjectForEntityForName:@"Album"
                                                         inManagedObjectContext:_managedObjectContext];
    [album setAlbumTitle:title];
    [album setAlbumLocation:location];
    
    return album;
}


-(NSArray *)artistModelsByName:(NSString *)artistName
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"artistName like %@", artistName];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Artist"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * artists = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching artists: %@", errors);
    }
#endif 
    
    return artists;

}

-(RDArtistModel *)artistModelWithName:(NSString *)artistName
{
    RDArtistModel * model = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:_managedObjectContext];
    [model setArtistName:artistName];
    
    return model;
}


-(RDTrackModel *)trackModelWithName:(NSString *)trackName
{
    RDTrackModel *model = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:_managedObjectContext];
    [model setTrackName:trackName];
    
    return model;
}

- (RDTrackModel *)trackByLocation:(NSString *)trackLocation
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"trackLocation like[c] %@", trackLocation];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Track"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * tracks = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching track by location: %@", errors);
    }
#endif
    
    return tracks.count > 0 ? [tracks objectAtIndex:0] : nil;
}

- (RDPlaylistModel *)playlistModelWithName:(NSString *)name
{
    RDPlaylistModel *model = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist"
                                                           inManagedObjectContext:_managedObjectContext];
    [model setName:name];
    
    return model;
}

- (NSArray *)playlistModels
{
    NSSortDescriptor * sortbyName = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                ascending:YES
                                                                 selector:@selector(caseInsensitiveCompare:)];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
    [request setSortDescriptors:@[sortbyName]];
    
    NSError * errors = nil;
    NSArray * models = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching playlists: %@", errors);
    }
#endif
    
    return models;
}


- (RDPlaylistModel *)playlistByName:(NSString *)name
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name like[c] %@", name];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * playlists = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching playlist by name: %@", errors);
    }
#endif
    
    return playlists.count > 0 ? [playlists objectAtIndex:0] : nil;
}


- (NSFetchedResultsController *)mixLibraryController
{
    NSSortDescriptor * sortbyName = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                ascending:YES
                                                                 selector:@selector(caseInsensitiveCompare:)];
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Playlist"];
    [request setSortDescriptors:@[sortbyName]];
    [request setFetchBatchSize:50];
    
    NSFetchedResultsController * controller =
                [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                    managedObjectContext:_managedObjectContext
                                                      sectionNameKeyPath:nil
                                                               cacheName:@"mixLibrary"];
    NSError * errors = nil;
    BOOL bSucceeded = [controller performFetch:&errors];
#ifdef DEBUG
    if (!bSucceeded)
    {
        NSLog(@"Errors occured fetching ablums: %@", errors);
    }
#endif
    return controller;
}

- (RDLibraryMetaModel *)libraryMeta
{
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"LibraryMeta"];
    
    NSError * errors = nil;
    NSArray * results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching library metadata by name: %@", errors);
    }
#endif
    
    RDLibraryMetaModel * model = nil;
    if (results.count > 0)
        model = [results objectAtIndex:0];
    else {
        model = [NSEntityDescription insertNewObjectForEntityForName:@"LibraryMeta"
                                              inManagedObjectContext:_managedObjectContext];
        [self saveChanges];
    }
    
    //
    // Fetch the total number of albums
    //
    NSExpression *keyExpression = [NSExpression expressionForKeyPath:@"albumTitle"];
    NSExpression *countExpression = [NSExpression expressionForFunction:@"count:"
                                                              arguments:[NSArray arrayWithObject:keyExpression]];
    
    NSExpressionDescription *description = [[NSExpressionDescription alloc] init];
    [description setName:@"totalAlbums"];
    [description setExpression:countExpression];
    [description setExpressionResultType:NSInteger32AttributeType];
    
    request = [[NSFetchRequest alloc] initWithEntityName:@"Album"];
    [request setResultType:NSDictionaryResultType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:description]];
    
    results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching album count: %@", errors);
    }
#endif

    if (results != nil && results.count > 0){
        NSNumber *totalAlbums = [[results objectAtIndex:0] valueForKey:@"totalAlbums"];
        model.totalAlbums = [totalAlbums intValue];
    }
    //
    // Fetch the total number tracks
    //
    keyExpression = [NSExpression expressionForKeyPath:@"trackName"];
    countExpression = [NSExpression expressionForFunction:@"count:"
                                                arguments:[NSArray arrayWithObject:keyExpression]];
    
    description = [[NSExpressionDescription alloc] init];
    [description setName:@"totalTracks"];
    [description setExpression:countExpression];
    [description setExpressionResultType:NSInteger32AttributeType];
    
    request = [[NSFetchRequest alloc] initWithEntityName:@"Track"];
    [request setResultType:NSDictionaryResultType];
    [request setPropertiesToFetch:[NSArray arrayWithObject:description]];
    
    results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching track count: %@", errors);
    }
#endif

    if (results != nil && results.count > 0){
        NSNumber *totalTracks = [[results objectAtIndex:0] valueForKey:@"totalTracks"];
        model.totalTracks = [totalTracks intValue];
    }
    
    return model;
}

- (void)updatePlayTime:(double)seconds
{
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"LibraryMeta"];
    
    NSError * errors = nil;
    NSArray * results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching library metadata by name: %@", errors);
    }
#endif
    RDLibraryMetaModel * model = (RDLibraryMetaModel *)[results objectAtIndex:0];
    model.totalPlayTime = model.totalPlayTime + seconds;
    [self saveChanges];
}


- (void)insertSyncMetaModelWithLocation:(NSString *)location withHash:(NSString *)hash
{
    RDDropboxSyncMetaModel *model = [NSEntityDescription insertNewObjectForEntityForName:@"SyncMeta"
                                                           inManagedObjectContext:_managedObjectContext];
    [model setLocation:location];
    [model setLocationHash:hash];
}

- (void)syncMetaModelDeleteAll
{
    [[self syncMetaModels] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self deleteModel:obj];
    }];
    
    [self saveChanges];
}

- (RDDropboxSyncMetaModel *)syncMetaModelByLocation:(NSString *)location
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"location like[c] %@", location];
    
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"SyncMeta"];
    [request setPredicate:predicate];
    
    NSError * errors = nil;
    NSArray * results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching SyncMeta by location: %@", errors);
    }
#endif
    
    return results.count > 0 ? [results objectAtIndex:0] : nil;
}

- (NSArray *)syncMetaModels
{
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"SyncMeta"];
    
    NSError * errors = nil;
    NSArray * results = [_managedObjectContext executeFetchRequest:request error:&errors];
#ifdef DEBUG
    if (errors != nil) {
        NSLog(@"Errors occured fetching library metadata by name: %@", errors);
    }
#endif
    
    return results;
}

#pragma mark - Class Methods

+ (NSPersistentStoreCoordinator *)sharedPersistanceStoreCoordinator
{
    static NSPersistentStoreCoordinator * instance = nil;
    
    if (!instance) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MusicLibrary" withExtension:@"momd"];
        NSManagedObjectModel * managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSURL *appDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [appDirectory URLByAppendingPathComponent:@"MusicLibrary.sqlite"];
        
        NSError *error = nil;
        NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
        instance = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        if (![instance addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        {
            NSLog(@"An unexpected error attempting to load music library error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        }
    }
    
    return instance;
}

+ (RDMusicRepository *)sharedInstance
{
    static RDMusicRepository * instance = nil;
    if (instance == nil)
    {
        NSThread * currentThread = [NSThread currentThread];
        NSThread * mainThread = [NSThread mainThread];
        //
        // We won't initialize this shared instance unless its on
        // the main thread
        //
        if (mainThread == currentThread) {
            instance = [[RDMusicRepository alloc] init];
            [instance initiateContext:[RDMusicRepository sharedPersistanceStoreCoordinator]];
            //
            // Add notifications
            //
            [[NSNotificationCenter defaultCenter] addObserver:instance
                                                     selector:@selector(didReceiveMergeChangesNotification:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:nil];
        }
    }
    
    return instance;
}

+ (RDMusicRepository *)createThreadedInstance
{
    RDMusicRepository * instance = [[RDMusicRepository alloc] init];
    [instance initiateContext:[RDMusicRepository sharedPersistanceStoreCoordinator]];
    
    return instance;
}



@end
