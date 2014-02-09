//
//  DropboxMusicStream.m
//  Dropbox
//
//  Created by Donelle Sanders on 2/5/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "RDDropboxMusicStream.h"
#import <DropboxSDK/DropboxSDK.h>


typedef enum _DropboxRequestMethod {
    DropboxRequestMethodRetrieveMedia = 1,
    DropboxRequestMethodRetrieveAlbums = 2,
    DropboxRequestMethodRetrieveArtists = 3,
    DropboxRequestMethodRetrieveTracks = 4,
    DropboxRequestMethodRetrieveURL = 5,
}DropboxRequestMethod;


@interface RDDropboxMusicStream () <DBRestClientDelegate>

- (void)retrieveArtistsComplete:(DBMetadata *)metadata;
- (void)retrieveAlbumsComplete:(DBMetadata *)metadata;
- (void)retrieveAlbumTracksComplete:(DBMetadata *)metadata;

- (NSString *)getValueForLocation:(NSString *)location forKey:(NSString *)key;
- (void)setValue:(NSString *)value forLocation:(NSString *)location forKey:(NSString *)key;
@end


@implementation RDDropboxMusicStream {
    BOOL _bCancelRequest;
    DBRestClient * _restClient;
    DropboxRequestMethod _requestMethod;
    NSMutableArray * _content;
    NSMutableDictionary * _locations;
}

#pragma mark - Initialization

- (id)initWithUser:(NSString *)userId
{
    if (self = [super init]) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:userId];
        _restClient.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    _restClient.delegate = nil;
    _restClient = nil;
    [_content removeAllObjects];
    _content = nil;
    _delegate = nil;
    
}

#pragma mark - DBRestClientDelegate protocol

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    switch (_requestMethod) {
            
        case DropboxRequestMethodRetrieveArtists:
            [self retrieveArtistsComplete:metadata];
            break;
            
        case DropboxRequestMethodRetrieveAlbums:
            [self retrieveAlbumsComplete:metadata];
            break;
            
        case DropboxRequestMethodRetrieveTracks:
            [self retrieveAlbumTracksComplete:metadata];
            break;
        default:
            break;
    }
}

- (void)restClient:(DBRestClient *)client metadataUnchangedAtPath:(NSString *)path
{
    if (!_bCancelRequest) {
        if ([self.delegate respondsToSelector:@selector(didReceiveMediaUnchanged:)])
            [self.delegate didReceiveMediaUnchanged:[path lowercaseString]];
        
        [self retrieveAlbumsComplete:nil];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    //
    // Don't report error if we already cancelled
    //
    if (!_bCancelRequest) {
        [self.delegate requestFailed:error];
    }
}

- (void)restClient:(DBRestClient *)restClient loadedStreamableURL:(NSURL *)url thatExpires:(NSDate *)expireDate forFile:(NSString *)path
{
    NSDictionary * response = [NSDictionary dictionaryWithObjectsAndKeys:url, @"url", expireDate, @"expireDate", path, @"path", nil];
    if ([self.delegate respondsToSelector:@selector(retrieveMediaCompleted:)])
        [self.delegate retrieveMediaCompleted:response];
}

- (void)restClient:(DBRestClient*)restClient loadStreamableURLFailedWithError:(NSError*)error
{
    [self.delegate requestFailed:error];
}


#pragma mark - Instance Methods

- (void)retrieveMediaFor:(NSDictionary *)locations
{
    _bCancelRequest = NO;
    _requestMethod = DropboxRequestMethodRetrieveArtists;
    _locations = [NSMutableDictionary dictionaryWithDictionary:locations];
    _content = [NSMutableArray arrayWithObjects:[NSMutableArray array] /* Folder Type: Music/AudioBook */,
                                                [NSMutableArray array] /* Artist */,
                                                [NSMutableArray array] /* Album */,
                                                [NSMutableArray array] /* Albums to fetch tracks */,  nil];
    
    @try {
        [_restClient loadMetadata:@"/Music"];
    }
    @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"RDDropboxMusicStream - retreiveMedia threw exception\nException: %@", exception);
#endif
        NSError * error = [NSError errorWithDomain:@"" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.reason, @"Error", nil]];
        [self.delegate requestFailed:error];
    }
}

- (void)retrieveStreamableMediaURLFor:(NSString *)location
{
    _bCancelRequest = NO;
    
    @try {
        [_restClient loadStreamableURLForFile:location];
    }
    @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"RDDropboxMusicStream - retrieveStreamableMediaURLFor threw exception\nException: %@", exception);
#endif
        NSError * error = [NSError errorWithDomain:@"" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.reason, @"Error", nil]];
        [self.delegate requestFailed:error];
    }
    
}

- (void)cancelRequest
{
    _bCancelRequest = true;
    if ([self.delegate respondsToSelector:@selector(retrieveMediaCancelled:)])
        [self.delegate retrieveMediaCancelled:_locations];
}

#pragma mark - Private Methods


- (void)retrieveArtistsComplete:(DBMetadata *)metadata
{
    if (_bCancelRequest)
        return;
    
    NSMutableArray * artistList = [_content objectAtIndex:1];
    
    if (metadata) {
        NSString * startLocation = [_locations objectForKey:@"startLocation"];
        for (DBMetadata * item in metadata.contents) {
            BOOL bSameLocation = [startLocation compare:item.path options:NSCaseInsensitiveSearch] == NSOrderedSame;
            if (item.isDirectory && bSameLocation) {
                //
                // Remove everything that was added before this and we will start
                // adding items after this one
                //
                [artistList removeAllObjects];
    #ifdef DEBUG
                NSLog(@"RDDropboxMusicStream - will start fetching artists starting from %@", startLocation);
    #endif
            }
            
            [artistList addObject:[NSString stringWithString:item.path]];
        }
    }
    
    if(artistList.count > 0) {
        NSString * path = [artistList objectAtIndex:0];
        [artistList removeObjectAtIndex:0];
        
        @try {
            _requestMethod = DropboxRequestMethodRetrieveAlbums;
            [_restClient loadMetadata:path];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"RDDropboxMusicStream - retrieveArtistsComplete threw exception\nException: %@", exception);
#endif
            NSError * error = [NSError errorWithDomain:@"" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.reason, @"Error", nil]];
            [self.delegate requestFailed:error];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(retrieveMediaCompleted:)])
            [self.delegate retrieveMediaCompleted:_locations];
    }
}

-(void)retrieveAlbumsComplete:(DBMetadata *)metadata
{
    if (_bCancelRequest)
        return;
    
    NSMutableArray * albumsToFetchTracks = [_content objectAtIndex:3];
    
    if (metadata) {
        NSMutableArray * albums = [_content objectAtIndex:2];
        for (DBMetadata * item in metadata.contents) {
            if (item.isDirectory) {
                NSArray * components = [item.path componentsSeparatedByString:@"/"];
                if (components.count > 3) { /* Album */
                    NSString * location = [item.path lowercaseString];
                    NSMutableDictionary * album = [[NSMutableDictionary alloc] initWithCapacity:4];
                    [album setValue:location forKey:@"id"];
                    [album setValue:[components objectAtIndex:components.count - 1] forKey:@"title"];
                    [album setValue:[components objectAtIndex:2] forKey:@"artist"];
                    [album setValue:[[components objectAtIndex:1] lowercaseString] forKey:@"media_type"];
                    [albums addObject:album];
                    [albumsToFetchTracks addObject:location];
                }
            }
        }
    }
    
    if (albumsToFetchTracks.count > 0) {
        NSString * location = [albumsToFetchTracks objectAtIndex:0];
        [albumsToFetchTracks removeObjectAtIndex:0];
        _requestMethod = DropboxRequestMethodRetrieveTracks;
        
        @try {
            NSString * hash = [self getValueForLocation:location forKey:@"hash"];
            [_restClient loadMetadata:location withHash:hash];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"RDDropboxMusicStream - retrieveAlbumsComplete threw exception\nException: %@", exception);
#endif
            NSError * error = [NSError errorWithDomain:@"" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.reason, @"Error", nil]];
            [self.delegate requestFailed:error];
        }
    } else {
        [self retrieveArtistsComplete:nil];
    }
}

-(void)retrieveAlbumTracksComplete:(DBMetadata *)metadata
{
    if (_bCancelRequest)
        return;
    
    __block NSMutableDictionary * currentAlbum = nil;
    NSMutableArray * albums = [_content objectAtIndex:2];
    
    [albums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary * item = (NSMutableDictionary *)obj;
        NSString * path = [item objectForKey:@"id"];
        if ([path compare:metadata.path options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            *stop = YES;
             currentAlbum = item;
        }
    }];
    
    if (currentAlbum) {
        NSMutableArray * tracks = [[NSMutableArray alloc] init];
        for (DBMetadata * item in metadata.contents) {
            if (!item.isDirectory) {
                NSString * path = [item.path lowercaseString];
                if ([path hasSuffix:@".mp3"] || [path hasSuffix:@".m4a"]) {
                    NSArray * components = [item.path componentsSeparatedByString:@"/"];
                    NSString * filename = [components objectAtIndex:components.count - 1];
                    
                    NSMutableDictionary * metadata = [[NSMutableDictionary alloc] init];
                    [metadata setValue:item.path forKey:@"path"];
                    [metadata setValue:[filename substringToIndex:filename.length - 4] forKey:@"name"];
                    [tracks addObject:metadata];
                } else if([path hasSuffix:@".jpg"] || [path hasSuffix:@".jpeg"] || [path hasSuffix:@".png"]) {
                    NSString * albumArt = [currentAlbum objectForKey:@"albumArt"];
                    if (!albumArt)
                        [currentAlbum setValue:item.path forKey:@"albumArt"];
                }
            }
        }
        
        if (tracks.count > 0) {
            [currentAlbum setValue:tracks forKey:@"tracks"];
            if ([self.delegate respondsToSelector:@selector(didReceiveMedia:)])
                [self.delegate didReceiveMedia:currentAlbum];
            
            [albums removeObject:currentAlbum];
            [self setValue:metadata.hash forLocation:metadata.path forKey:@"hash"];
        } else {
            [albums removeObject:currentAlbum];
        }
    }
    //
    // Move to the next album
    //
    [self retrieveAlbumsComplete:nil];
}


- (NSString *)getValueForLocation:(NSString *)location forKey:(NSString *)key
{
    NSDictionary * info = [_locations objectForKey:[location lowercaseString]];
    if (info.count > 0)
        return [info objectForKey:key];
    
    return nil;
}

- (void)setValue:(NSString *)value forLocation:(NSString *)location forKey:(NSString *)key
{
    if (location && location.length > 0) {
        
        NSString * lowercaseLocation = [location lowercaseString];
        NSMutableDictionary * info = [_locations objectForKey:lowercaseLocation];
        if (!info) {
            info = [NSMutableDictionary dictionaryWithDictionary:@{@"hash" : @"", @"location" : lowercaseLocation}];
            [_locations setObject:info forKey:lowercaseLocation];
        }
            
        [info setObject:value forKey:key];
    }
}

@end
