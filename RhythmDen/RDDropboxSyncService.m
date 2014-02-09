//
//  RDDropboxSyncService.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 1/16/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "RDDropboxSyncService.h"
#import "RDDropboxMusicStream.h"
#import "RDDropboxPreference.h"
#import "RDMusicRepository.h"
#import "RDiTunesSearchService.h"
#import "RDModels+RhythmDen.h"
#import "LEColorPicker.h"
#import "UIImage+RhythmDen.h"
#import "NSObject+RhythmDen.h"

@interface RDDropboxServiceFetchRequest : NSOperation<RDDropboxMusicStreamDelegate,RDiTunesSearchServiceDelegate>
- (id)initWithAlbumLocation:(NSString *)location;
- (void)fetchBinary:(NSURL *)artworkUrl;
@end

@implementation RDDropboxServiceFetchRequest
{
    NSURLSessionDataTask * _dataTask;
    RDDropboxMusicStream * _dropboxStream;
    RDiTunesSearchService * _itunesSearch;
    NSString * _albumLocation;
    NSString * _albumArtworkUrl;
    CFRunLoopRef _currentRunLoop;
    NSThread * _currentThread;
    BOOL _isFinished, _isExecuting, _isCancelled; /* NOT USED */
}

- (id)initWithAlbumLocation:(NSString *)location
{
    if (self = [super init]) {
        _albumLocation = location;
    }
    return self;
}

- (void)dealloc
{
    _albumLocation = nil;
    _dropboxStream.delegate = nil;
    _dropboxStream = nil;
    _itunesSearch.delegate = nil;
    _itunesSearch = nil;
    _albumArtworkUrl = nil;
}

- (void)noOp
{
    /* NOOP */
}

- (void)main
{
    [self setValue:@(YES) forKeyPath:@"isExecuting"];
    
    @autoreleasepool {
        _currentRunLoop = CFRunLoopGetCurrent();
        _currentThread = [NSThread currentThread];
        
        RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
        RDAlbumModel * album = [repository albumModelByLocation:_albumLocation];
        if (!album.albumArtwork) {
            //
            // Fetch the data stream
            //
            _albumArtworkUrl = album.albumArtworkUrl;
            if (_albumArtworkUrl) {
                //
                // Setup dropbox service
                //
                RDDropboxPreference * preference = [[RDDropboxPreference alloc] init];
                _dropboxStream = [[RDDropboxMusicStream alloc] initWithUser:preference.userId];
                _dropboxStream.delegate = self;
                [_dropboxStream retrieveStreamableMediaURLFor:_albumArtworkUrl];
            } else {
                //
                // Setup itunes service
                //
                NSDictionary * query = @{ RDiTunesSearchQueryAlbumNameKey : album.albumTitle, RDiTunesSearchQueryArtistNameKey : album.albumArtists.artistName };
                _itunesSearch = [RDiTunesSearchService new];
                _itunesSearch.delegate = self;
                [_itunesSearch search:query];
            }
#ifdef DEBUG
            NSLog(@"RDDropboxServiceFetchRequest - Fetching artwork for album '%@'", _albumLocation);
#endif
            
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(noOp) userInfo:nil repeats:YES];
            CFRunLoopRun();
        }
#ifdef DEBUG
        else {
            NSLog(@"RDDropboxServiceFetchRequest - Skipping artwork fetch for album '%@'", _albumLocation);
        }
#endif
        
#ifdef DEBUG
        NSLog(@"RDDropboxServiceFetchRequest - Threaded ended for '%@'", _albumLocation);
#endif
    }
    
    [self setValue:@(NO) forKeyPath:@"isExecuting"];
    [self setValue:@(YES) forKeyPath:@"isFinished"];
}


-(void)cancel
{
    //
    // Cancel stream
    //
    [_dropboxStream cancelRequest];
    [_dataTask cancel];
}

#pragma mark - Instance Methods

- (void)fetchBinary:(NSURL *)artworkUrl
{
    //
    // Fetch the binary image of the artwork
    //
    _dataTask = [[NSURLSession sharedSession] dataTaskWithURL:artworkUrl
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if (data != nil) {
                                                    @autoreleasepool {
                                                        RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
                                                        RDAlbumModel * album = [repository albumModelByLocation:_albumLocation];
                                                        //
                                                        // Generate thumbnail
                                                        //
                                                        UIImage * image = [UIImage imageWithData:data],
                                                                * thumbNail = [image shrink:CGSizeMake(65, 65)];
                                                        
                                                        album.albumArtworkThumb = UIImagePNGRepresentation(thumbNail);
                                                        album.albumArtwork = data;
                                                        //
                                                        // We stopped rendering the colorscheme here because the user can put us in background mode
                                                        // and therefore LEColorPicker will suspend the process until the app returns to the foreground.
                                                        // Well... the problem is this, by the time the user returns the app to the foreground, this
                                                        // thread will have been long gone causing an exception. So what we're going to do is get the
                                                        // color scheme later on when the user loads the album up in the player.
                                                        //
                                                        [album setColorSchemeWith:[NSDictionary dictionary]];
                                                        double maxSize = 320.0 * 2.0;
                                                        if (maxSize > (image.size.width + image.size.height))
                                                            album.albumArtwork = UIImagePNGRepresentation([image shrink:CGSizeMake(320.0, 320.0)]);
                                                        //
                                                        // Save to repository
                                                        //
                                                        [repository saveChanges];
                                                    }
#ifdef DEBUG
                                                    NSLog(@"RDDropboxServiceFetchRequest - Done fetching artwork for %@", _albumLocation);
#endif
                                                }
                                                
#ifdef DEBUG
                                                else {
                                                    NSLog(@"RDDropboxServiceFetchRequest - Error occured fetching image. Error: %@", error);
                                                }
#endif  
                                                CFRunLoopStop(_currentRunLoop);
                                            }];
    [_dataTask resume];
}

#pragma mark - RDiTunesSearchServiceDelegate Methods

- (void)iTunesSearchService:(RDiTunesSearchService *)service didSucceedWith:(NSDictionary *)info
{
    if ([info count] > 0) {
        __block BOOL bFound = NO;
        NSArray * albums = [info objectForKey:RDiTunesAlbumskey];
        [albums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary * scores = [obj objectForKey:RDiTunesFuzzyScoreKey];
            NSNumber * artistSocre = [scores objectForKey:RDiTunesArtistNameKey];
            NSNumber * albumScore = [scores objectForKey:RDiTunesAlbumNameKey];
            
            if ([artistSocre floatValue] >= .9 && [albumScore floatValue] >= .92) {
                //
                // Save meta data before we fetch more data
                //
                [self fetchBinary:[NSURL URLWithString:[obj objectForKey:RDiTunesArtworkUrlKey]]];
                *stop = bFound = YES;
            }
        }];
        
        if (bFound) return;
    }
    
#ifdef DEBUG
    NSLog(@"RDDropboxServiceFetchRequest(iTunesSearchService) - Failed to get artwork for %@", _albumLocation);
#endif
    CFRunLoopStop(_currentRunLoop);
}

- (void)iTunesSearchServiceFailed:(RDiTunesSearchService *)service withError:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"RDDropboxServiceFetchRequest(iTunesSearchService) - Failed to get artwork for %@", _albumLocation);
#endif
    CFRunLoopStop(_currentRunLoop);
}

#pragma mark - RDDropboxMusicStreamDelegate Methods

- (void)retrieveMediaCompleted:(id)response
{
    NSURL * artworkUrl = (NSURL *)[(NSDictionary *)response objectForKey:@"url"];
    if (artworkUrl) {
        [self fetchBinary:artworkUrl];
    } else {
#ifdef DEBUG
        NSLog(@"RDDropboxServiceFetchRequest(retrieveMediaCompleted) - Failed to get artwork for %@", _albumLocation);
        NSLog(@"RDDropboxServiceFetchRequest - Fetching artwork for album '%@' using iTunesService", _albumLocation);
#endif
        [self performBlock:^{
            RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
            RDAlbumModel * album = [repository albumModelByLocation:_albumLocation];
            //
            // Setup itunes service
            //
            NSDictionary * query = @{ RDiTunesSearchQueryAlbumNameKey : album.albumTitle, RDiTunesSearchQueryArtistNameKey : album.albumArtists.artistName };
            _itunesSearch = [RDiTunesSearchService new];
            _itunesSearch.delegate = self;
            [_itunesSearch search:query];
        } onThread:_currentThread];
    }
}

- (void)retrieveMediaCancelled
{
#ifdef DEBUG
    NSLog(@"RDDropboxServiceFetchRequest(RDDropboxMusicStreamDelegate) - Fetched cancelled for '%@'", _albumLocation);
#endif
    
    [self setValue:@(YES) forKeyPath:@"isCancelled"];
    CFRunLoopStop(_currentRunLoop);
}

- (void)requestFailed:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"RDDropboxServiceFetchRequest(RDDropboxMusicStreamDelegate) - Failed to get artwork for %@", _albumLocation);
    NSLog(@"RDDropboxServiceFetchRequest - Fetching artwork for album '%@' using iTunesService", _albumLocation);
#endif
    [self performBlock:^{
        RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
        RDAlbumModel * album = [repository albumModelByLocation:_albumLocation];
        //
        // Setup itunes service
        //
        NSDictionary * query = @{ RDiTunesSearchQueryAlbumNameKey : album.albumTitle, RDiTunesSearchQueryArtistNameKey : album.albumArtists.artistName };
        _itunesSearch = [RDiTunesSearchService new];
        _itunesSearch.delegate = self;
        [_itunesSearch search:query];
    } onThread:_currentThread];
}

@end




@interface RDDropboxSyncService () <RDDropboxMusicStreamDelegate,NSFetchedResultsControllerDelegate>
- (void)extract:(NSDictionary *)trackVals;
- (void)updateWithStatus:(RDDropboxSyncStatus)status withContext:(id)context;
- (void)updateSyncInfo:(NSDictionary *)locations;
@end


@implementation RDDropboxSyncService
{
    RDDropboxSyncStatus _serviceStatus;
    BOOL _isFinished, _isExecuting, _isCancelled; /* NOT USED */
    RDDropboxMusicStream * _dropboxStream;
    NSOperationQueue * _fetchArtRequests;
    NSMutableArray * _albumLocations;
    RDMusicRepository * _repository;
    RDDropboxPreference * _preferences;
    CFRunLoopRef _currentRunLoop;
}

- (void)dealloc
{
    _preferences = nil;
    _startLocation = nil;
    _fetchArtRequests = nil;
    [_albumLocations removeAllObjects];
    _albumLocations = nil;
    _currentRunLoop = nil;
}


#pragma mark - NSOperation Methods

- (BOOL)isExecuting
{
    return _serviceStatus == RDDropboxSyncStatusStarted;
}

- (BOOL)isCancelled
{
    return _serviceStatus == RDDropboxSyncStatusCancelled;
}

- (BOOL)isFinished
{
    return  _serviceStatus == RDDropboxSyncStatusCompleted ||
            _serviceStatus == RDDropboxSyncStatusCancelled ||
            _serviceStatus == RDDropboxSyncStatusFailed;
}

- (void)main
{
    [self setValue:@(YES) forKeyPath:@"isExecuting"];
    
    @autoreleasepool {
        _currentRunLoop = CFRunLoopGetCurrent();
        _preferences = [[RDDropboxPreference alloc] init];
        _albumLocations = [NSMutableArray array];
    
        _fetchArtRequests = [[NSOperationQueue alloc] init];
        _fetchArtRequests.name = @"DropboxSyncService Artwork Queue";
        _fetchArtRequests.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        //
        // Create an instance to the repository
        //
        _repository = [RDMusicRepository createThreadedInstance];
        //
        // Populate the locations
        //
        NSMutableDictionary * locations = [NSMutableDictionary dictionary];
        [[_repository syncMetaModels] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RDDropboxSyncMetaModel * model = obj;
            NSMutableDictionary * info = [NSMutableDictionary dictionaryWithDictionary:@{@"location" : model.location, @"hash" : model.locationHash}];
            [locations setObject:info forKey:model.location];
        }];
        
        [locations setObject:_startLocation forKey:@"startLocation"];
        //
        // Create an instance of the dropbox stream and start it
        //
        _dropboxStream = [[RDDropboxMusicStream alloc] initWithUser:_preferences.userId];
        _dropboxStream.delegate = self;
        [_dropboxStream retrieveMediaFor:locations];
        
        [self updateWithStatus:RDDropboxSyncStatusStarted withContext:nil];
        
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(noOp) userInfo:nil repeats:YES];
        CFRunLoopRun();
        
#ifdef DEBUG
        NSLog(@"RDDropboxSyncService - Run loop exited for Dropbox Service");
#endif
    }
    
    [self setValue:@(YES) forKeyPath:@"isFinished"];
}

-(void)cancel
{
    CFRunLoopPerformBlock(_currentRunLoop, kCFRunLoopDefaultMode, ^{
        //
        // Cancel stream
        //
        [_dropboxStream cancelRequest];
        [_fetchArtRequests cancelAllOperations];
    });
}


#pragma mark - Instance Methods

- (void)noOp
{
    /* NO OP */
}

-(void)updateWithStatus:(RDDropboxSyncStatus)status withContext:(id)context
{
    _serviceStatus = status;
    
    switch (status) {
        case RDDropboxSyncStatusFailed:
        {
            [_delegate dropboxSyncRequestFailed:context];
            CFRunLoopStop(_currentRunLoop);
            break;
        }
            
        case RDDropboxSyncStatusCompleted:
        {
            [_delegate dropboxSyncRequestCompleted:context];
            CFRunLoopStop(_currentRunLoop);
            break;
        }
            
        case RDDropboxSyncStatusCancelled:
        {
            [_delegate dropboxSyncRequestStatus:RDDropboxSyncStatusCancelled withContext:context];
            CFRunLoopStop(_currentRunLoop);
            break;
        }
            
        default:
        {
            if ([_delegate respondsToSelector:@selector(dropboxSyncRequestStatus:withContext:)])
                [_delegate dropboxSyncRequestStatus:status withContext:context];
            
            break;
        }
    }
}

- (void)extract:(NSDictionary *)trackVals
{
    NSString * trackName = [[trackVals valueForKey:@"name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d{1}\\s?\\-\\s?\\d{1,3}"
                                                                           options:0
                                                                             error:&error];
    //
    // Check for matches that look like this "1-01 So Fresh So Clean"
    //
    NSArray * matches = [regex matchesInString:trackName options:0 range:NSMakeRange(0, [trackName length])];
    if (matches.count > 0) {
        NSTextCheckingResult *result = [matches objectAtIndex:0];
        //
        // Extract the match from the string and convert it to an integer
        //
        NSArray * components = [[trackName substringWithRange:[result range]] componentsSeparatedByString:@"-"];
        //
        // Try to parse the disc number
        //
        int disc = [[components objectAtIndex:0] intValue];
        if (disc > 0 && disc != INT_MAX && disc != INT_MIN)
            [trackVals setValue:@(disc) forKey:@"disc"];
        //
        // Try to parse the track number
        //
        int trackNum = [[components objectAtIndex:1] intValue];
        if (trackNum > 0 && trackNum != INT_MAX && trackNum != INT_MIN)
            [trackVals setValue:@(trackNum) forKey:@"trackNumber"];
        //
        // Set the new track name
        //
        trackName = [[trackName substringFromIndex:result.range.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d{1,3}"
                                                          options:0
                                                            error:&error];
        //
        // Check for matches that look like this "01 - So Fresh So Clean"
        //
        NSArray * matches = [regex matchesInString:trackName options:0 range:NSMakeRange(0, [trackName length])];
        if (matches.count > 0) {
            NSTextCheckingResult *result = [matches objectAtIndex:0];
            //
            // Extract the match from the string and convert it to an integer
            //
            NSString * tempVal = [trackName substringWithRange:[result range]];
            int trackNum = [tempVal intValue];
            //
            // Make sure we are valid number
            //
            if (trackNum > 0 && trackNum != INT_MAX && trackNum != INT_MIN)
                [trackVals setValue:@(trackNum) forKey:@"trackNumber"];
            //
            // Set the new track name
            //
            trackName = [[trackName substringFromIndex:result.range.length] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    //
    // Test to see if we have a prefix before the string and if so trim it
    //
    if ([trackName hasPrefix:@"-"] || [trackName hasPrefix:@"."])
        trackName = [[trackName substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    //
    // Replace track name
    //
    [trackVals setValue:trackName forKey:@"name"];
}


- (void)updateSyncInfo:(NSDictionary *)locations
{
    __block BOOL bHasChanges = NO;
    [locations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSString * location = [obj objectForKey:@"location"];
            NSString * hash = [obj objectForKey:@"hash"];
            RDDropboxSyncMetaModel * model = [_repository syncMetaModelByLocation:location];
            if (model) {
                model.locationHash = hash;
            } else {
                [_repository insertSyncMetaModelWithLocation:location withHash:hash];
            }
            
            bHasChanges = YES;
        }
    }];
    
    if (bHasChanges)
        [_repository saveChanges];
}


#pragma mark - DropboxMusicStreamDelegate protocol

- (void)didReceiveMedia:(id)response
{
    @autoreleasepool {
        NSDictionary * folder = (NSDictionary *)response;
        if (folder) {
            //
            // See if the album already exists in our inventory by title
            //
            RDAlbumModel * album = [_repository albumModelByLocation:[folder valueForKey:@"id"]];
            //
            // Determines if this a new album or a change to an existing
            //
            if (!album) {
                //
                // It didn't so lets create it
                //
                NSString * title = [[folder valueForKey:@"title"] stringByReplacingOccurrencesOfString:@"_" withString:@":"];
                album = [_repository albumModelWithTitle:title andLocation:[folder valueForKey:@"id"]];
                album.albumPrevTitle = title;
                //
                // See if an artist already exists in our inventory by artist name
                //
                __block RDArtistModel * artist = nil;
                NSString  * artistName = [(NSString *)folder valueForKey:@"artist"];
                NSArray * artists = [_repository artistModelsByName:artistName];
                [artists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    RDArtistModel * item = (RDArtistModel *)obj;
                    if ([artist.artistName compare:artistName] == NSOrderedSame) {
                        artist = item;
                        *stop = YES;
                    }
                }];
                
                if (!artist) {
                    //
                    // It didn't so lets create it
                    //
                    artist = [_repository artistModelWithName:artistName];
                }
                //
                // Set the artis
                //
                album.albumArtists = artist;
                [artist addArtistAlbumsObject:album];
            } else {
                //
                // This can happen during app upgrades
                //
                if (!album.albumPrevTitle)
                    album.albumPrevTitle = album.albumTitle;
            }
            
            NSArray * tracks = (NSArray *)[folder objectForKey:@"tracks"];
            NSMutableDictionary * trackDict = [NSMutableDictionary dictionary];
            //
            // Populate with new tracks
            //
            NSMutableDictionary * trackDiscs = [NSMutableDictionary dictionary];
            [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary * track = (NSDictionary *)obj;
                //
                // Copy the track location
                //
                NSString * locationPath = [track objectForKey:@"path"];
                [trackDict setValue:locationPath forKey:locationPath];
                //
                // Search to see if the track already exist in the album
                //
                RDTrackModel * trackModel = [_repository trackByLocation:locationPath];
                if (trackModel && !trackModel.trackAlbums) {
#ifdef DEBUG
                    NSLog(@"RDDropboxSyncService - Removing orphan track '%@' ", trackModel.trackName);
#endif
                    //
                    // This is an orphan track so lets delete him
                    //
                    [_repository deleteModel:trackModel];
                    trackModel = nil;
                }
                //
                // Parse the track
                //
                [track setValue:@(idx + 1) forKey:@"trackNumber"];
                [track setValue:@(1) forKey:@"disc"];
                [self extract:track];
                //
                // Remove the artist name from the track if it exists
                //
                NSString * trackName = [track valueForKey:@"name"];
                NSRange searchRange = NSMakeRange(0, [trackName length]);
                trackName = [[trackName stringByReplacingOccurrencesOfString:album.albumArtists.artistName
                                                                 withString:@""
                                                                    options:NSCaseInsensitiveSearch
                                                                      range:searchRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
                while ([trackName hasPrefix:@"-"] || [trackName hasPrefix:@"."])
                    trackName = [[trackName substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                //
                // Does the track exists?
                //
                if (!trackModel) {
                    //
                    //
                    // Add the track to the album
                    //
                    trackModel = [_repository trackModelWithName:trackName];
                    trackModel.trackName = trackName;
                    trackModel.trackPrevName = trackName;
                    trackModel.trackNumber = [[track valueForKey:@"trackNumber"] intValue];
                    trackModel.trackDisc = [[track objectForKey:@"disc"] intValue];
                    trackModel.trackLocation = locationPath;
                    [album addAlbumTracksObject:trackModel];
                } else {
                    //
                    // This can happen during app upgrades
                    //
                    trackModel.trackName = trackName;
                    trackModel.trackPrevName = trackName;
                    trackModel.trackNumber = [[track valueForKey:@"trackNumber"] intValue];
                    trackModel.trackDisc = [[track objectForKey:@"disc"] intValue];
                }
                //
                // Find the disk number
                //
                NSString * disc = [NSString stringWithFormat:@"%i", trackModel.trackDisc];
                if (![trackDiscs objectForKey:disc]) [trackDiscs setObject:disc forKey:disc];
            }];
            //
            // Now remove the tracks that are not in the new list
            //
            NSArray * albumTracks = [album.albumTracks allObjects];
            [albumTracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                RDTrackModel * track = (RDTrackModel *)obj;
                if (![trackDict objectForKey:track.trackLocation]) {
                    //
                    // Purge the playlists associated with the track
                    //
                    NSArray * trackPlaylists = [[track trackPlaylists] allObjects];
                    [trackPlaylists enumerateObjectsUsingBlock:^(id objPlaylist, NSUInteger ndx, BOOL *nStop) {
                        RDPlaylistModel * playlist = (RDPlaylistModel *)objPlaylist;
                        [playlist removePlaylistTracksObject:track];
                        [track removeTrackPlaylistsObject:playlist];
                    }];
#ifdef DEBUG
                    NSLog(@"RDDropboxSyncService - Removing track '%@' from album %@ because it no longer exists", track.trackName, album.albumTitle);
#endif
                    //
                    // Remove the track
                    //
                    [album removeAlbumTracksObject:track];
                    [_repository deleteModel:track];
                }
            }];
            //
            // See if we have any tracks in this album
            //
            if (album.albumTracks.count > 0) {
                //
                // Set the meta data
                //
                album.albumDiscs = trackDiscs.count;
                album.albumTrackCount = album.albumTracks.count;
                //
                // Save everything
                //
                [_repository saveChanges];
#if DEBUG
                NSLog(@"RDDropboxSyncService - Saved album %@", album.albumTitle);
#endif
                //
                // Set the artwork
                //
                NSString * artworkUrl = [folder objectForKey:@"albumArt"];
                if (artworkUrl && artworkUrl.length > 0) {
                    album.albumArtworkUrl = artworkUrl;
                    [_repository saveChanges];
                }
                //
                // Fetch the artwork
                //
                RDDropboxServiceFetchRequest * request = [[RDDropboxServiceFetchRequest alloc] initWithAlbumLocation:album.albumLocation];
                [_fetchArtRequests addOperation:request];
                //
                // Add to our list
                //
                [_albumLocations addObject:album.albumLocation];
            } else {
                [album.albumArtists removeArtistAlbumsObject:album];
                [_repository deleteModel:album];
                //
                // There is no tracks so delete the album
                //
                [_repository saveChanges];
#if DEBUG
                NSLog(@"RDDropboxSyncService - Removing album %@ because there were no tracks.", album.albumTitle);
#endif
            }
        }
    }
}

- (void)didReceiveMediaUnchanged:(id)response
{
    [_albumLocations addObject:response];
}


-(void)retrieveMediaCompleted:(id)response
{
    int maxWait = 60;
    int prevCount = [_fetchArtRequests operationCount];
    //
    // Make sure we are finished fetching before we end the runloop
    //
    while ([_fetchArtRequests operationCount] > 0) {
        [NSThread sleepForTimeInterval:5.0];
        
        if ([_fetchArtRequests operationCount] == prevCount)
            maxWait -= 5;
        else {
            prevCount = [_fetchArtRequests operationCount];
            maxWait = 60;
        }
        
        if (maxWait <= 0) {
#ifdef DEBUG
            NSLog(@"We are stuck in a loop so we gonna break out of this.");
#endif
            // Force cancel
            [_fetchArtRequests cancelAllOperations];
            break;
        }
    }
    //
    // Update our sync locations
    //
    [self updateSyncInfo:response];
    [self updateWithStatus:RDDropboxSyncStatusCompleted withContext:_albumLocations];
}

- (void)retrieveMediaCancelled:(id)response
{
    //
    // Update our sync locations
    //
    [self updateSyncInfo:response];
    [self updateWithStatus:RDDropboxSyncStatusCancelled withContext:_albumLocations];
    
    [self setValue:@(YES) forKeyPath:@"isCancelled"];
    CFRunLoopStop(_currentRunLoop);
}


-(void)requestFailed:(NSError *)error
{
    [self updateWithStatus:RDDropboxSyncStatusFailed withContext:error];
}

@end
