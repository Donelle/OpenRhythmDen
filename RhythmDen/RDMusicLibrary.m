//
//  RDMusicLibrary.m
//  RhythmDen
//
//  Created by Donelle Sanders on 4/28/13.
//
//

#import "RDMusicLibrary.h"
#import "RDAppPreference.h"
#import "RDDropboxPreference.h"
#import "RDDropboxSyncService.h"
#import "RDMusicRepository.h"
#import "NSObject+RhythmDen.h"

@interface RDMusicLibrary () <RDDropboxSyncServiceRequestDelegate>

- (void)startSyncAt:(NSString *)folderPath;

@end

@implementation RDMusicLibrary
{
    RDAppPreference * _preferences;
    NSOperation * _dropboxService;
    NSString * _lastLocation;
    NSMutableArray * _albums;
    BOOL _bPauseRequest;
}

-(id)init
{
    if (self = [super init]) {
        _preferences = [[RDAppPreference alloc] init];
        _albums = [NSMutableArray array];
    }
    
    return self;
}

-(void)syncronize
{
    _isSyncronizing = YES;
    _isOnPause = NO;
    _bPauseRequest = NO;
    [_albums removeAllObjects];
    [self startSyncAt:@"/"];
}

- (void)cancelSynchronization
{
    [_albums removeAllObjects];
    [_dropboxService cancel];
}

- (void)pauseSynchronization
{
    _bPauseRequest = YES;
    [_dropboxService cancel];
}

- (void)resumeSynchronization
{
    _bPauseRequest = NO;
    [self startSyncAt:_lastLocation];
}

- (void)startSyncAt:(NSString *)folderPath
{
    RDDropboxSyncService * service = [[RDDropboxSyncService alloc] init];
    service.delegate = self;
    service.startLocation = folderPath;
    
    _dropboxService = service;
    [self performBlockInBackground:^{
        [_dropboxService start];
    }];

}

#pragma mark - RDCloudServiceRequestDelegate Protocol

- (void)dropboxSyncRequestStatus:(RDDropboxSyncStatus)status withContext:(id)context
{
    if (status == RDDropboxSyncStatusStarted) {
#ifdef DEBUG
        NSLog(@"RDMusicLibrary - Dropbox Cloud Service syncronization started");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotification * notification = [NSNotification notificationWithName:RDMusicLibrarySyncStartedNotification object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        });
    }
    else if (status == RDDropboxSyncStatusCancelled) {
#ifdef DEBUG
        NSLog(@"RDMusicLibrary - Dropbox Cloud Service syncronization cancelled");
#endif
        _isSyncronizing = NO;
        //
        // Parse out the location where we need to start fetching from
        //
        if (_bPauseRequest) {
            NSArray * albumLocations = (NSArray *)context;
            [_albums addObjectsFromArray:albumLocations];
            
            NSArray * components = [[albumLocations lastObject] componentsSeparatedByString:@"/"];
            if (components.count > 3)
                _lastLocation = [NSString stringWithFormat:@"%@/%@/%@", [components objectAtIndex:0], [components objectAtIndex:1], [components objectAtIndex:2]];
            
            _isSyncronizing = YES;
            _isOnPause = YES;
        }
        
        ((RDDropboxSyncService *)_dropboxService).delegate = nil;
        _dropboxService = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotification * notification = [NSNotification notificationWithName:RDMusicLibrarySyncCancelledNotification object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        });
    }
}


- (void)dropboxSyncRequestCompleted:(id)context
{
#ifdef DEBUG
    NSLog(@"RDMusicLibrary - Dropbox Cloud Service syncronization completed");
#endif
    [_albums addObjectsFromArray:context];
    //
    // Sync the repository
    //
    RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
    [repository synchronizeRepository:_albums];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ((RDDropboxSyncService *)_dropboxService).delegate = nil;
        _dropboxService = nil;
        _isSyncronizing = NO;
        _isOnPause = NO;
        _bPauseRequest = NO;
        [_albums removeAllObjects];
        //
        // Update our preferences
        //
        _preferences.lastSyncronized = [NSDate date];
        //
        // Notify subscribers we are finished syncronizing
        //
        NSNotification * notification = [NSNotification notificationWithName:RDMusicLibrarySyncCompleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    });
}


- (void)dropboxSyncRequestFailed:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"RDMusicLibrary - Dropbox Cloud Service syncronization failed");
    NSLog(@"RDMusicLibrary - Error: %@ , Reason: %@", error, error.debugDescription);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        ((RDDropboxSyncService *)_dropboxService).delegate = nil;
        _dropboxService = nil;
        _isSyncronizing = NO;
        _isOnPause = NO;
        _bPauseRequest = NO;
        [_albums removeAllObjects];
        
        NSNotification * notification = [NSNotification notificationWithName:RDMusicLibrarySyncFailedNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    });
}



#pragma mark - Class Method

+ (RDMusicLibrary *)sharedInstance
{
    static RDMusicLibrary * instance = nil;
    if (instance == nil)
        instance = [[RDMusicLibrary alloc] init];
    
    return instance;
}


@end
