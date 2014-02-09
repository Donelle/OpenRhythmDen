//
//  RDMusicPlayer.m
//  RhythmDen
//
//  Created by Donelle Sanders on 2/24/13.
//
//
#import "RDMusicPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Reachability.h"

#import "RDModels.h"
#import "RDDropboxMusicStream.h"
#import "RDMusicRepository.h"
#import "RDDropboxPreference.h"
#import "RDMusicResourceCache.h"
#import "RDInternetDetectionActionSheet.h"
#import "NSObject+RhythmDen.h"
#import "UIApplication+RhythmDen.h"

/* Asset keys */
NSString * const kPlayableKey		= @"playable";
NSString * const kDurationKey       = @"duration";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

/* Observer Key context objects */
static void *AVRateObservationContext = &AVRateObservationContext;
static void *AVStatusObservationContext = &AVStatusObservationContext;
static void *AVCurrentItemObservationContext = &AVCurrentItemObservationContext;



@protocol RDMusicTrackFetcherRequestDelegate <NSObject>
- (void)didFetchCompeted:(AVURLAsset *)asset;
- (void)didFetchFailed;
@end

@interface RDMusicTrackFetcher : NSOperation <RDDropboxMusicStreamDelegate>

- (id)initWithTrack:(RDMusicTrack *)track;
- (void)loadMedia;
@end


@implementation RDMusicTrackFetcher
{
    RDDropboxMusicStream * _service;
    __weak RDMusicTrack * _track;
    CFRunLoopRef _currentRunLoop;
    BOOL _isExecuting, _isFinished;
}

- (id)initWithTrack:(RDMusicTrack *)track
{
    if (self = [super init]) {
        _track = track;
    }
    
    return self;
}

- (void)dealloc
{
    _service = nil;
    _track = nil;
    _currentRunLoop = nil;
}

- (BOOL)isExecuting
{
    return _isExecuting;
}

- (BOOL)isFinished
{
    return _isFinished;
}

#pragma mark - NSOPeration Methods


- (void)noOp
{
    /* NO OP */
}


- (void)main
{
    _isExecuting = YES;
    [self setValue:@(YES) forKeyPath:@"isExecuting"];
    
    @autoreleasepool {
        _currentRunLoop = CFRunLoopGetCurrent();
        //
        // Initialize service
        //
        RDDropboxPreference * preference = [[RDDropboxPreference alloc] init];
        _service = [[RDDropboxMusicStream alloc] initWithUser:preference.userId];
        _service.delegate = self;
        //
        // Determine if we already have a url for this track and if
        // we do go ahead and play the track.
        //
        if (!_track.isStreamExpired) {
            [self loadMedia];
        } else {
#ifdef DEBUG
            NSLog(@"RDMusicTrackFetcher - retrieveMediaURL:%@", _track.streamLocation);
#endif
            [_service retrieveStreamableMediaURLFor:_track.streamLocation];
        }
        
#ifdef DEBUG
        NSLog(@"RDMusicTrackFetcher - Run loop started for fetching %@", _track.name);
#endif
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(noOp) userInfo:nil repeats:YES];
        CFRunLoopRun();
#ifdef DEBUG
        NSLog(@"RDMusicTrackFetcher - Run loop exiting for fetching %@", _track.name);
#endif
        _service.delegate = nil;
        _currentRunLoop = nil;
    }

    _isExecuting = NO;
    [self setValue:@(NO) forKeyPath:@"isExecuting"];
    
     _isFinished = YES;
    [self setValue:@(YES) forKeyPath:@"isFinished"];
}


- (void)loadMedia
{
    __block AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_track.streamURL options:nil];
    __block NSArray * requestedKeys = @[kDurationKey, kPlayableKey];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        //
        // Make sure the properties we requested come back in ready state
        //
        for (NSString * key in requestedKeys) {
            NSError * err = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:key error:&err];
            if (status == AVKeyValueStatusFailed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                    [nc postNotificationName:RDMusicPlayerAssetFailedToLoadNotification object:_track];
                });
#ifdef DEBUG
                NSLog(@"RDMusicTrackFetcher - Asset load failure - Description: %@, Reason: %@", [err localizedDescription], [err localizedFailureReason]);
#endif
                CFRunLoopStop(_currentRunLoop);
                return;
            }
        }
        //
        // Notify the track we loaded the asset
        //
        id<RDMusicTrackFetcherRequestDelegate> delegate = (id<RDMusicTrackFetcherRequestDelegate>)_track;
        [delegate didFetchCompeted:asset];
        //
        // Stop the thread
        //
        CFRunLoopStop(_currentRunLoop);
    }];
}


#pragma mark - RDCloudServiceRequestDelegate Methods

- (void)retrieveMediaCompleted:(id)response
{
#ifdef DEBUG
    NSLog(@"RDMusicTrackFetcher - retrieveMediaCompleted was called with context: %@", response);
#endif
    
    NSDictionary * params = (NSDictionary *)response;
    _track.streamURL = (NSURL *)[params objectForKey:@"url"];
    _track.streamExpireDate = (NSDate *)[params objectForKey:@"expireDate"];
    //
    // Save to repository
    //
    RDMusicRepository * repository = [RDMusicRepository createThreadedInstance];
    RDTrackModel * track = [repository trackByLocation:_track.streamLocation];
    if (track) {
        track.trackUrl = [_track.streamURL absoluteString];
        track.trackFetchDate = [_track.streamExpireDate timeIntervalSince1970];
        [repository saveChanges];
    }
    //
    // Load the stream
    //
    [self loadMedia];
}


- (void)requestFailed:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"RDMusicTrackFetcher - Failed requesting track from Dropbox with error: %@", error);
#endif
    //
    // Display the alert if we have not been cancelled otherwise
    // it would be pointless and confusing to display
    //
    if (!self.isCancelled) {
        //
        // Notify the track we failed
        //
        id<RDMusicTrackFetcherRequestDelegate> delegate = (id<RDMusicTrackFetcherRequestDelegate>)_track;
        [delegate didFetchFailed];
        //
        // Kill the loop
        //
        CFRunLoopStop(_currentRunLoop);
    }
}



@end


@interface RDMusicTrack () <RDMusicTrackFetcherRequestDelegate>

@property (readonly, nonatomic) AVPlayerItem * playerItem;
@property (assign, nonatomic) BOOL isCancelled;
@property (readonly, nonatomic) BOOL isTrackPlayable;
@property (readonly, nonatomic) BOOL isReadyToPlay;

- (id)initWithPlaylist:(RDMusicPlaylist *)playlist model:(RDTrackModel *)model;
- (void)playerItemDidReachEnd:(NSNotification *)notification ;
- (void)playerItemFailedToPlayToEnd:(NSNotification *)notification;
- (void)playerItemStalled:(NSNotification *)notification;
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)setPlayCount;

@end


@implementation RDMusicTrack
{
    AVPlayerItem * _playerItem;
    CMTime _duration;
}

- (id)initWithPlaylist:(RDMusicPlaylist *)playlist model:(RDTrackModel *)model
{
    if (self = [super init]) {
        _name = model.trackName;
        _number = model.trackNumber;
        _streamLocation = model.trackLocation;
        _playlist = playlist;
        _streamURL = nil;
        _streamExpireDate = [NSDate date];
        _disc = model.trackDisc;
        _playerItem = nil;
        _thumbNail = model.trackAlbums.albumArtworkThumb;
        _duration = kCMTimeInvalid;
        _albumArtist = model.trackAlbums.albumArtists.artistName;
        _albumName = model.trackAlbums.albumTitle;
        _iTunesUrl = [NSURL URLWithString:model.trackiTunesUrl];
        
        if (model.trackFetchDate > 0)
            _streamExpireDate = [NSDate dateWithTimeIntervalSince1970:model.trackFetchDate];
        
        if (model.trackUrl) {
            //
            // Check the expiration date on the last time the track was played
            //
            NSDate * currentDate = [NSDate date];
            if ([currentDate compare:_streamExpireDate] == NSOrderedAscending)
                _streamURL = [NSURL URLWithString:model.trackUrl];
        }
    }

    return self;
}

- (void)dealloc
{
    _playerItem = nil;
}

#pragma mark - Properties


- (NSData *)thumbNail
{
    if(!_thumbNail)
        return _playlist.thumbNail;
    
    return _thumbNail;
}

- (NSData *)coverArt
{
    if (!_coverArt)
        return _playlist.coverArt;
    
    return _coverArt;
}

- (AVPlayerItem *)playerItem
{
    return _playerItem;
}


- (CMTime)duration
{
	return _duration;
}


- (BOOL)isCurrentTrack
{
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (player)
        return [self isEqualToTrack:player.currentTrack];
    
    return NO;
}

- (BOOL)isStreamExpired
{
    if (_streamExpireDate != nil && _streamURL != nil) {
        //
        // Check the expiration date on the last time the track was played
        //
        NSDate * currentDate = [NSDate date];
        return ([currentDate compare:_streamExpireDate] != NSOrderedAscending);
    }
    
    return YES;
}

- (BOOL)isTrackPlayable
{
    return _playerItem != nil && !self.isStreamExpired;
}

- (BOOL)isReadyToPlay
{
    if (_playerItem)
        return _playerItem.status == AVPlayerItemStatusReadyToPlay;
    
    return NO;
}


#pragma mark - Instance Methods

- (BOOL)isEqualToTrack:(RDMusicTrack *)track
{
    if(track) 
        return [self.streamLocation isEqual:track.streamLocation];
    
    return NO;
}


- (void)setPlayCount
{
    RDMusicRepository * repository =[RDMusicRepository sharedInstance];
    RDTrackModel * track = [repository trackByLocation:self.streamLocation];
    track.trackPlayCount = track.trackPlayCount + 1;
    [repository saveChanges];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                //
                // Capture the duration
                //
                _duration = [_playerItem duration];
                //
                // Send notification that the track is ready to play
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetReadyToPlayNotification object:self];
                break;
            }
                
            case AVPlayerItemStatusFailed:
            {
                _playerItem = nil;
                //
                // Send notification that something went wrong
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetFailedToLoadNotification object:self];
                break;
            }
                
            default:
                NSLog(@"Recieved AVPlayerItemStatusUnknown message");
                break;
        }
    }
}



#pragma mark - Notifications


- (void)playerItemDidReachEnd:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDMusicTrack - Track titled '%@' finished playing", _name);
#endif
    _playerItem = nil;
    //
    // Send notification that we reached the end
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetPlayedToEndNotification object:self];
}


- (void)playerItemFailedToPlayToEnd:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDMusicTrack - Track titled '%@' failed to finish playing", _name);
#endif
    _playerItem = nil;
    //
    // Send notification that we reached the end
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetFailedToPlayToEndNotification object:self];
}

- (void)playerItemStalled:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDMusicTrack - Track titled '%@' stalled", _name);
#endif
    //
    // Send notification that we reached the end
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetStalledNotification object:self];
}

#pragma mark - RDMusicTrackFetcherRequestDelegate Implementation

- (void)didFetchCompeted:(AVURLAsset *)asset
{
    __block NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    //
    // Use the AVAsset playable property to detect whether the asset can be played.
    //
    if (asset.playable) {
        //
        // Create a new instance of AVPlayerItem from the now successfully loaded AVAsset.
        //
        _playerItem = [AVPlayerItem playerItemWithAsset:asset];
        //
        // Subscribe to player item notifications
        //
        [nc addObserver:self
               selector:@selector(playerItemDidReachEnd:)
                   name:AVPlayerItemDidPlayToEndTimeNotification
                 object:_playerItem];
        
        [nc addObserver:self
               selector:@selector(playerItemFailedToPlayToEnd:)
                   name:AVPlayerItemFailedToPlayToEndTimeNotification
                 object:_playerItem];
        
        [nc addObserver:self
               selector:@selector(playerItemStalled:)
                   name:AVPlayerItemPlaybackStalledNotification
                 object:_playerItem];
        
        //
        // Observe the player item "status" key
        //
        [_playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionNew
                         context:AVStatusObservationContext];
        //
        // Let the player know the track is playable
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            // Let the player know we are playable
            //
            [nc postNotificationName:RDMusicPlayerAssetPlayableNotification object:self];
        });
    } else {
        _playerItem = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            // Let the player know we can't play
            //
            [nc postNotificationName:RDMusicPlayerAssetFailedToLoadNotification object:self];
        });
#ifdef DEBUG
        NSLog(@"RDMusicTrack - Asset load failure - Description: unable to load track from %@", asset.URL);
#endif

    }
}


- (void)didFetchFailed
{
#ifdef DEBUG
    NSLog(@"RDMusicTrack - Failed fetching Track titled '%@'", _name);
#endif
    _playerItem = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        // Let the player know if its still visible
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerAssetFailedToLoadNotification object:self];
    });
}

@end


#pragma mark - RDMusicPlaylist Implementation

@interface RDMusicPlaylist ()

- (void)setPreloaded:(BOOL)loaded;

@end

@implementation RDMusicPlaylist {
    NSMutableDictionary * _tracklist;
}


- (id)init
{
    if (self = [super init]) {
        _tracklist = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"RDMusicPlaylist - dealloc was called");
#endif
    [_tracklist removeAllObjects];
    _tracklist = nil;
}


#pragma mark - Instance Properties

- (int)discs
{
    return _tracklist.count;
}

- (int)tracksTotal
{
    __block int tracks = 0;
    [_tracklist enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        tracks += [obj count];
    }];
    
    return tracks;
}


- (NSData *)coverArt
{
    if (!_coverArt) {
        UIImage * image = [[RDMusicResourceCache sharedInstance] missingCoverArtImage];
        _coverArt = [NSData dataWithData:UIImagePNGRepresentation(image)];
    }
    
    return _coverArt;
}


- (NSData *)thumbNail
{
    if (!_thumbNail) {
        UIImage * image = [[RDMusicResourceCache sharedInstance] missingCoverArtImage];
        _thumbNail = [NSData dataWithData:UIImagePNGRepresentation(image)];
    }
    
    return _thumbNail;
}


- (NSDictionary *)colorScheme
{
    if (!_colorScheme) {
        _colorScheme = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIColor colorWithRed:23.0/255.0 green:20.0/255.0 blue:19.0/255.0 alpha:1.0],@"BackgroundColor",
                                [UIColor colorWithRed:111.0/255.0 green:100.0/255.0 blue:94.0/255.0 alpha:1.0],@"PrimaryTextColor",
                                [UIColor whiteColor],@"SecondaryTextColor", nil];
    }
    
    return _colorScheme;
}

- (void)setPreloaded:(BOOL)loaded
{
    _preloaded = loaded;
}

#pragma mark - Instance Methods

- (BOOL)isEqualToPlaylist:(RDMusicPlaylist *)playlist
{
    do {
        if ((self.isMix && !playlist.isMix) || (!self.isMix && playlist.isMix))
            break;
        
        NSDictionary * otherId = (NSDictionary *)playlist.playlistId;
        if (!otherId) break;
        
        NSDictionary * myId = (NSDictionary *)self.playlistId;
        if (!myId) break;
        
        if ([myId count] != [otherId count])
            break;
        
        if (self.isMix) {
            NSDate * other_createDate = [otherId objectForKey:@"createDate"];
            NSString * other_name = [otherId objectForKey:@"name"];
            NSDate * createDate = [myId objectForKey:@"createDate"];
            NSString * name = [myId objectForKey:@"name"];
            return [other_createDate isEqualToDate:createDate] && [other_name isEqualToString:name];
        } else {
            NSString * other_location = [otherId objectForKey:@"streamLocation"];
            NSString * location = [myId objectForKey:@"streamLocation"];
            return [other_location isEqualToString:location];
        }
    }while (false);
    
    return NO;
}

- (void)addTrackModels:(NSArray *)models
{
    [models enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[RDTrackModel class]]) {
            [self addTrack:[[RDMusicTrack alloc] initWithPlaylist:self model:obj]];
        } else if ([obj isKindOfClass:[RDMusicTrack class]]) {
            [self addTrack:obj];
        }
    }];
}

- (void)addTrack:(RDMusicTrack *)track
{
    NSIndexPath * path = [self indexPathFromTrack:track];
    if (!path) {
        NSString *key = [NSString stringWithFormat:@"%i", track.disc];
        NSMutableArray * tracks = [_tracklist objectForKey:key];
        if (!tracks) {
            tracks = [NSMutableArray array];
            [_tracklist setValue:tracks forKey:key];
        }
        
        [tracks addObject:track];
        //
        // Resort the list
        //
        [_tracklist enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSMutableArray * tracks = (NSMutableArray *)obj;
            
            [tracks sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                RDMusicTrack * track1 = (RDMusicTrack *)obj1;
                RDMusicTrack * track2 = (RDMusicTrack *)obj2;
                
                if (track1.number > track2.number) {
                    return NSOrderedDescending;
                } else if (track1.number < track2.number) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedSame;
                }
            }];
        }];
    }
}


- (void)removeTrack:(RDMusicTrack *)track
{
    NSString * key = [NSString stringWithFormat:@"%i", track.disc];
    NSMutableArray * tracks = [_tracklist objectForKey:key];
    if (tracks) {
        [tracks removeObject:track];
        track.playlist = nil;
        track = nil;
        //
        // Resort the list
        //
        [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RDMusicTrack * item = (RDMusicTrack *)obj;
            item.number = idx + 1;
        }];
    }
}


- (int)trackCountForDisc:(int)disc
{
    NSString * key = [NSString stringWithFormat:@"%i", disc];
    return [[_tracklist objectForKey:key] count];
}

- (RDMusicTrack *)trackAtIndex:(NSIndexPath *)indexPath
{
    NSString * key = [NSString stringWithFormat:@"%i", indexPath.section];
    NSArray * disc = [_tracklist objectForKey:key];
    if (disc && disc.count > indexPath.row)
        return (RDMusicTrack *) [disc objectAtIndex:indexPath.row];
    
    return nil;
}

- (NSArray *)tracksForDisc:(int)disc
{
    NSString * key = [NSString stringWithFormat:@"%i", disc];
    return [_tracklist objectForKey:key];
}

- (NSIndexPath *)indexPathFromTrack:(RDMusicTrack *)track
{
    NSIndexPath * path = nil;
    for (int disc = 0; disc < _tracklist.count; disc++) {
        BOOL bFound = NO;
        NSString * key = [NSString stringWithFormat:@"%i", disc + 1];
        NSArray * tracks = [_tracklist objectForKey:key];
        for (int row = 0; row < tracks.count; row++) {
            RDMusicTrack * item = (RDMusicTrack *)[tracks objectAtIndex:row];
            if ([item isEqualToTrack:track]) {
                path = [NSIndexPath indexPathForRow:row inSection:disc + 1];
                bFound = YES;
                break;
            }
        }
        
        if (bFound) break;
    }
    
    return path;
}

@end




#pragma mark - RDMusicPlayer Implemtation

NSString * const RDCurrentTrackKey          = @"currentTrack";
NSString * const RDQueuedTrackKey           = @"queuedTrack";
NSString * const RDQueuedTrackRequestsKey   = @"queuedTrackRequests";

#define MAX_PLAY_ATTEMPTS 5

typedef enum {
    RDMusicPlayerStateNone = 0,
    RDMusicPlayerStatePlaying = 1,
    RDMusicPlayerStatePaused = 2,
    RDMusicPlayerStateStopped = 3,
    RDMusicPlayerStateLoading = 4,
    RDMusicPlayerStateBuffering = 5
} RDMUsicPlayerState;


@interface RDMusicPlayer ()

- (void)initialize;
- (void)activateSession;
- (void)audioSessionInterrupted:(NSNotification *)notification;
- (void)audioSessionRouteChanged:(NSNotification *)notification;
- (void)networkConnectionChanged:(NSNotification *)notification;
- (void)playerItemPlayable:(NSNotification *)notification;
- (void)playerItemReadyToPlay:(NSNotification *)notification;
- (void)playerItemFailedToLoad:(NSNotification *)notification;
- (void)playerItemPlayedToEnd:(NSNotification *)notification;
- (void)playerEnteredBackground:(NSNotification *)notification;
- (void)playerEnteredForeground:(NSNotification *)notification;
- (void)playerItemStalled:(NSNotification *)notification;
- (void)observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)setCurrentTrackMetaData:(AVPlayerItem *)playerItem;
- (void)playItem:(AVPlayerItem *)playerItem;
- (void)initPlayerTimerObserver;
- (void)removePlayerTimeObserver;
- (void)updateMediaCenter;
- (BOOL)trackInFetchQueue:(RDMusicTrack *)track;
- (void)preloadPlaylist:(RDMusicTrack *)priorityTrack;
- (void)startBackgroundRequest;
- (void)endBackgroundRequest;

@end

@implementation RDMusicPlayer
{
    id _timeObserver;
    NSMutableDictionary * _metaPlayerInfo;
    AVQueuePlayer * _audioPlayer;
    NSOperationQueue * _queuedTrackRequests;
    Reachability * _reachability;
    BOOL _bInBackground;
    BOOL _bIsShowingNetworkChangedActionSheet;
    CMTime _currentTrackPosition;
    RDMUsicPlayerState _state;
    NSBlockOperation * _loadPlaylistOp;
    UIBackgroundTaskIdentifier _backgroundTaskID, _fetchBackgroundTaskID;
    NSUInteger _playAttempts;
}


-(id)init
{
    if (self = [super init]) {
        _queuedTrackRequests = [[NSOperationQueue alloc] init];
        _queuedTrackRequests.name = @"Player Track Queue";
        _queuedTrackRequests.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _metaPlayerInfo = [NSMutableDictionary dictionary];
        _state = RDMusicPlayerStateNone;
    }
    
    return self;
}


#pragma mark - Properties


- (RDMusicTrack *)currentTrack
{
    return [_metaPlayerInfo objectForKey:RDCurrentTrackKey];
}

- (RDMusicTrack *)queuedTrack
{
    return [_metaPlayerInfo objectForKey:RDQueuedTrackKey];
}

- (BOOL)isPlaying
{
    return _state == RDMusicPlayerStatePlaying;
}

- (BOOL)isPaused
{
    return _state == RDMusicPlayerStatePaused;
}

- (BOOL)hasStopped
{
    return  _state == RDMusicPlayerStateStopped;
}

- (BOOL)isLoading
{
    return _state == RDMusicPlayerStateLoading;
}

- (BOOL)inBackgroundMode
{
    return _bInBackground;
}

- (void)setPosition:(Float64)position
{
    _currentTrackPosition = CMTimeMakeWithSeconds(position, 10000);
}

- (Float64)position
{
    return CMTimeGetSeconds(_currentTrackPosition);
}

#pragma mark - Instance Methods

- (void)startBackgroundRequest
{
    //
    // lets see what mode we are in.
    //
    if (_bInBackground && _backgroundTaskID == UIBackgroundTaskInvalid) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - registering background task");
#endif
        _backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
#ifdef DEBUG
            NSLog(@"RDMusicPlayer - Background Time:%f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
#endif
            if (_backgroundTaskID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                _backgroundTaskID = UIBackgroundTaskInvalid;
            }
        }];
    }
}


- (void)endBackgroundRequest
{
    if (_backgroundTaskID != UIBackgroundTaskInvalid) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - unregistering the background task");
#endif
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
        _backgroundTaskID = UIBackgroundTaskInvalid;
    }
}

- (BOOL)trackInFetchQueue:(RDMusicTrack *)track
{
    NSMutableArray * requests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
    for (int ndx = 0; ndx < requests.count; ndx++) {
        NSString * streamLocation = (NSString *)[requests objectAtIndex:ndx];
        if ([streamLocation isEqual:track.streamLocation]) {
            return YES;
        }
    }
    
    return NO;
}


- (void)preloadPlaylist:(RDMusicTrack *)priorityTrack
{
    //
    // Cancel all previous requests
    //
    if (_loadPlaylistOp && [[_loadPlaylistOp executionBlocks] count] > 0)
        [_loadPlaylistOp cancel];
    //
    // Queue new track
    //
    RDMusicTrackFetcher * fetchOp = [[RDMusicTrackFetcher alloc] initWithTrack:priorityTrack];
    [_queuedTrackRequests addOperation:fetchOp];
    //
    // Set the queued track
    //
    [_metaPlayerInfo setValue:priorityTrack forKey:RDQueuedTrackKey];
    //
    // Let the UI know we are already fetching this
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackLoadingNotification object:priorityTrack];
    //
    // Add the track to our request list
    //
    NSMutableArray * requests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
    [requests addObject:priorityTrack.streamLocation];
    //
    // Clear old track
    //
    [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
    //
    // Now queue up this entire playlist
    //
    [self performBlockInBackground:^{
        _loadPlaylistOp = [NSBlockOperation blockOperationWithBlock:^{
            NSMutableArray * requests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
            for (int i =0; i < _playlist.discs; i++) {
                NSArray * tracks = [_playlist tracksForDisc:i + 1];
                [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    RDMusicTrack * track = obj;
                    if (![track isEqualToTrack:priorityTrack]) {
                        NSLog(@"Queuing track %@", track.name);
                        //
                        // Queue new track
                        //
                        RDMusicTrackFetcher * fetchOp = [[RDMusicTrackFetcher alloc] initWithTrack:track];
                        [_queuedTrackRequests addOperation:fetchOp];
                        //
                        // Add the track to our request list
                        //
                        [requests addObject:track.streamLocation];
                    }
                }];
            }
        }];
        
        [_loadPlaylistOp start];
    }];
    
    //
    // Flag the playlist as preloaded
    //
    _playlist.preloaded = YES;
}


- (void)playTrack:(RDMusicTrack *)track
{
    //
    // Guards remote control events
    //
    if(![self safeToPlay]) {
        //
        // They opt'd out so lets stop the track
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerWillNotPlayOnCellularNotification object:track];
        //
        // If we are in background mode let the user know
        //
        if (_bInBackground)
            [[UIApplication sharedApplication] postNotificationMessage:@"Sorry, your settings does not allow playback on your cellular network"];
        
        return;
    }
    //
    // If we are in background mode we request a task
    // so we can continue playing
    //
    if (_bInBackground)
        [self startBackgroundRequest];
    //
    // Stop the current track if its playing
    //
    [self stop];
    //
    // Change the state to loading
    //
    _state = RDMusicPlayerStateLoading;
    //
    // See if we've preloaded the list
    //
    //NetworkStatus status = [_reachability currentReachabilityStatus];
    //if (!_playlist.preloaded && status == ReachableViaWiFi && !_playlist.isMix) {
        //
        // Preload the playlist and give the current track priority
        // 
    //    [self preloadPlaylist:track];
    //    return;
    //}
    //
    // Before we do anything make sure the track we are requesting
    // does not exist or already in the queue
    //
    if ([self trackInFetchQueue:track]) {
        //
        // Set the queued track
        //
        [_metaPlayerInfo setValue:track forKey:RDQueuedTrackKey];
        //
        // Let the UI know we are already fetching this
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackLoadingNotification object:track];
        return;
    }
    //
    // Check to see if we already played this track and if the track
    // hasn't expired since the last play.
    //
    if (!track.isTrackPlayable) {
        //
        // Queue new track
        //
        RDMusicTrackFetcher * fetchOp = [[RDMusicTrackFetcher alloc] initWithTrack:track];
        [_queuedTrackRequests addOperation:fetchOp];
        //
        // Set the queued track
        //
        [_metaPlayerInfo setValue:track forKey:RDQueuedTrackKey];
        //
        // Notify UI we are loading this new track
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackLoadingNotification object:track];
        //
        // Add the track to our request list
        //
        NSMutableArray * requests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
        [requests addObject:track.streamLocation];
        //
        // Clear old track
        //
        [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
    } else {
        //
        // Set the queued track
        //
        [_metaPlayerInfo setValue:track forKey:RDQueuedTrackKey];
        //
        // Let the UI know we are already fetching this
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackLoadingNotification object:track];
        //
        // Clear old track
        //
        [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
        //
        // Set the new player item
        //
        [_audioPlayer replaceCurrentItemWithPlayerItem:track.playerItem];
        [track.playerItem seekToTime:kCMTimeZero];
        //
        // Play track
        //
        [self playItem:track.playerItem];
    }
}

- (void)playNextTrack
{
    //
    // Play next track can be called in three different scenerios:
    //  #1 After a previous track has ended
    //  #2 While a current track is playing, paused, or stopped
    //  #3 While a track is being fetched by RDFetchTrackRequest object
    //
    // So we need to account for all three scenerios and process each
    // by the most frequent to least likely.
    //
    
    //
    // Scenerio #3: When the user is cycling through tracks
    //
    if (self.queuedTrack) {
        NSArray * tracks = [self.playlist tracksForDisc:self.queuedTrack.disc];
        int ndx = [tracks indexOfObject:self.queuedTrack] + 1;
        //
        // See if we can get the next track on the same disc
        //
        if (ndx < tracks.count) {
            [self playTrack:[tracks objectAtIndex:ndx]];
        } else {
            //
            // We might be at the last track or the next track is on the next disc
            //
            tracks = [_playlist tracksForDisc:self.queuedTrack.disc + 1];
            if (tracks) {
                [self playTrack:[tracks objectAtIndex:0]];
            } else {
                //
                // Only perform these set of instruction if we are in background mode.
                // This will happen when we are skipping through tracks that failed to load.
                //
                if (_bInBackground) {
                    [self stop];
                    //
                    // Reset everything
                    //
                    [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
                    [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
                    //
                    // Send the user a notification
                    //
                    [[UIApplication sharedApplication] postNotificationMessage:[NSString stringWithFormat:@"You've reached the end of %@ . Let's play another one!", _playlist.name]];
                    //
                    // Notify the UI we reached the end of the playlist
                    //
                    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerEndOfPlaylistNotification object:nil];
                }
            }
        }
    }
    //
    // Scenario #1 amd #2
    //
    else if (self.currentTrack) {
        NSArray * tracks = [_playlist tracksForDisc:self.currentTrack.disc];
        int ndx = [tracks indexOfObject:self.currentTrack] + 1;
        //
        // See if we can get the next track on the same disc
        //
        if (ndx < tracks.count) {
            [self playTrack:[tracks objectAtIndex:ndx]];
        } else {
            //
            // We might be at the last track or the next track is on the next disc
            //
            tracks = [_playlist tracksForDisc:self.currentTrack.disc + 1];
            if (tracks) {
                [self playTrack:[tracks objectAtIndex:0]];
            } else {
                //
                // Before we try to reset anything lets make sure we
                // have completely stopped
                //
                if (self.hasStopped && self.currentTrack) {
                    //
                    // Reset everything
                    //
                    [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
                    [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
                }
                //
                // If we are in background mode we send the user an alert
                // in the notification center
                //
                if (_bInBackground)
                    [[UIApplication sharedApplication] postNotificationMessage:[NSString stringWithFormat:@"You've reached the end of %@ . Let's play another one!", _playlist.name]];
                //
                // Notify the UI we reached the end of the playlist
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerEndOfPlaylistNotification object:nil];
            }
        }
    }
}

- (void)playPrevTrack
{
    //
    // Play next track can be called in three different scenerios:
    //  #1 After a previous track has ended
    //  #2 While a current track is playing, paused, or stopped
    //  #3 While a track is being fetched by RDFetchTrackRequest object
    //
    // So we need to account for all three scenerios and process each
    // by the most frequent to least likely.
    //
    
    //
    // Scenerio #3: When the user is cycling through tracks
    //
    if (self.queuedTrack) {
        NSArray * tracks = [_playlist tracksForDisc:self.queuedTrack.disc];
        int ndx = [tracks indexOfObject:self.queuedTrack] - 1;
        //
        // See if we can get the next track on the same disc
        //
        if (ndx > -1) {
            [self playTrack:[tracks objectAtIndex:ndx]];
        } else {
            //
            // We might be at the first track or the first track of the next disc
            //
            tracks = [_playlist tracksForDisc:self.queuedTrack.disc - 1];
            if (tracks) {
                [self playTrack:[tracks lastObject]];
            } else {
                //
                // Nope we are the first track
                //
                tracks = [_playlist tracksForDisc:self.queuedTrack.disc];
                [self playTrack:[tracks objectAtIndex:0]];
            }
        }
    }
    //
    // Scenario #1 and #2
    //
    else if (self.currentTrack) {
        NSArray * tracks = [_playlist tracksForDisc:self.currentTrack.disc];
        int ndx = [tracks indexOfObject:self.currentTrack] - 1;
        //
        // See if we can get the next track on the same disc
        //
        if (ndx > -1) {
            [self playTrack:[tracks objectAtIndex:ndx]];
        } else {
            //
            // We might be at the last track or the next track is on the next disc
            //
            tracks = [_playlist tracksForDisc:self.currentTrack.disc - 1];
            if (tracks) {
                [self playTrack:[tracks lastObject]];
            } else {
                //
                // Nope we are the first track
                //
                tracks = [_playlist tracksForDisc:self.currentTrack.disc];
                [self playTrack:[tracks objectAtIndex:0]];
            }
        }
    }
}


- (void)pause
{
    if (_state != RDMusicPlayerStatePaused)
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackPausedNotification object:self.currentTrack];
        
    _state = RDMusicPlayerStatePaused;
    [_audioPlayer pause];
}

- (void)resume
{
    if(![self safeToPlay])
        return;
    
    if (_state != RDMusicPlayerStatePlaying)
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackResumeNotification object:self.currentTrack];
    
    _state = RDMusicPlayerStatePlaying;
    [_audioPlayer play];
}

- (void)stop
{
    _state = RDMusicPlayerStateStopped;
    //
    // Remove the the time observer
    //
    [self removePlayerTimeObserver];
    [_audioPlayer pause];
}


- (void)seekTo:(Float64)position
{
    if (_audioPlayer) {
        if (position > 0) {
            [_audioPlayer seekToTime:CMTimeMakeWithSeconds(position, 10)];
        } else {
            [_audioPlayer seekToTime:kCMTimeZero];
        }
    }
}


-(void)initPlayerTimerObserver
{
    _currentTrackPosition = kCMTimeZero;
    _timeObserver =
        [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                   queue:dispatch_get_main_queue()
                                              usingBlock:^(CMTime time) {
                                                  Float64 interval = CMTimeGetSeconds(time);
                                                  if (interval != NAN && interval > 0.0f) {
                                                      //
                                                      // Set the current position
                                                      //
                                                      [[RDMusicPlayer sharedInstance] setPosition:interval];
                                                      //
                                                      // Update the media center
                                                      //
                                                      [[RDMusicPlayer sharedInstance] updateMediaCenter];
                                                      //
                                                      // Send notification
                                                      //
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackUpdateNotification object:@(interval)];
                                                  }
                                              }];
}

- (void)removePlayerTimeObserver
{
	if (_timeObserver) {
		[_audioPlayer removeTimeObserver:_timeObserver];
		_timeObserver = nil;
	}
}


- (void)setCurrentTrackMetaData:(AVPlayerItem *)playerItem
{
    __block BOOL bFound = NO;
    
    for (int i = 0; i < _playlist.discs; i++) {
        NSArray * tracks = [_playlist tracksForDisc:i + 1];
    
        [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RDMusicTrack * track = (RDMusicTrack *)obj;
            AVURLAsset * asset1 = (AVURLAsset *)[track.playerItem asset];
            AVURLAsset * asset2 = (AVURLAsset *)[playerItem asset];
            if ([asset1.URL isEqual:asset2.URL]) {
                [track setPlayCount];
                [_metaPlayerInfo setValue:track forKey:RDCurrentTrackKey];
                *stop = bFound = YES;
            }
        }];
        
        if (bFound) break;
    }
}


- (void)playItem:(AVPlayerItem *)playerItem
{
    //
    // Set the current track
    //
    [self setCurrentTrackMetaData:playerItem];
    //
    // initialize the timmer
    //
    [self initPlayerTimerObserver];
    //
    // Play the track
    //
    _audioPlayer.volume = 1.0f;
    [_audioPlayer play];
    //
    // Clear the queue
    //
    [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
    //
    // Reset the play attempts
    //
    _playAttempts = 0;
}


- (void)updateMediaCenter
{
    RDMusicTrack * track = self.currentTrack;
    if (track) {
        NSMutableDictionary *songInfo =
                [NSMutableDictionary dictionaryWithDictionary:@{ MPMediaItemPropertyTitle : track.name ,
                                                                 MPMediaItemPropertyAlbumTitle : track.albumName,
                                                                 MPMediaItemPropertyArtist : track.albumArtist }];
        
        
        NSNumber * trackCount = [NSNumber numberWithInt:track.playlist.tracksTotal];
        if (trackCount)
            [songInfo setValue:trackCount forKey:MPMediaItemPropertyAlbumTrackCount];

        NSNumber * elapsed = [NSNumber numberWithInt:self.position];
        if (elapsed)
            [songInfo setValue:elapsed forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        NSNumber * duration = [NSNumber numberWithInt:CMTimeGetSeconds(track.duration)];
        if (duration)
            [songInfo setValue:duration forKey:MPMediaItemPropertyPlaybackDuration];
        
        NSNumber * trackNumber = [NSNumber numberWithInt:track.number];
        if (trackNumber)
            [songInfo setValue:trackNumber forKey:MPMediaItemPropertyAlbumTrackNumber];

        NSNumber * discCount = [NSNumber numberWithInt:track.playlist.discs];
        if (discCount)
            [songInfo setValue:discCount forKey:MPMediaItemPropertyDiscCount];

        NSNumber * discNumber = [NSNumber numberWithInt:track.disc];
        if (discNumber)
            [songInfo setValue:discNumber forKey:MPMediaItemPropertyDiscNumber];

        MPMediaItemArtwork * artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageWithData:track.coverArt]];
        [songInfo setValue:artwork forKey:MPMediaItemPropertyArtwork];
       
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = songInfo;
    }
}

- (void)initialize
{
    _backgroundTaskID = UIBackgroundTaskInvalid;
    AVAudioSession * session = [AVAudioSession sharedInstance];
    
    NSError * errors = nil;
    BOOL bSuccess = [session setCategory:AVAudioSessionCategoryPlayback error:&errors];
    if (!bSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                             message:@"An error occured initializing your audio please restart this app"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            [alert show];
        });
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Failed to initialize audio services with: %@", errors);
#endif
        return;
    }
    
    NSTimeInterval bufferDuration = 0.005;
    bSuccess = [session setPreferredIOBufferDuration:bufferDuration error:&errors];
    if (!bSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                             message:@"An error occured initializing your audio please restart this app"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            [alert show];
        });
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Failed to initialize audio services with: %@", errors);
#endif
        return;
    }
    [self activateSession];
    //
    // Get a handle to our internet connection and start monitoring
    //
    _reachability = [Reachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    //
    // Initialize our metadata
    //
    [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
    [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
    [_metaPlayerInfo setValue:[NSMutableArray array] forKey:RDQueuedTrackRequestsKey];
    _playAttempts = 0;
    //
    // Setup player
    //
    // We do this because if we duck to background on first play the player
    // acts wonky. There is something wrong with playing the first play item on a
    // background task. For some reason it completely disables the player
    // altogether, you end up having to restart the entire app to get it
    // working again. So for now we just force the user to start atleast
    // one track in the foreground in order to play other tracks in the background.
    //
    NSString * path = [[NSBundle mainBundle] pathForResource:@"blank" ofType:@"mp3"];
    AVPlayerItem * blankItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:path]];
    _audioPlayer = [AVPlayer playerWithPlayerItem:blankItem];
    _audioPlayer.allowsExternalPlayback = NO;
    [_audioPlayer play];
    //
    // Observe the AVPlayer "currentItem" property to find out when any
    // AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did occur.
    //
    [_audioPlayer addObserver:self
                   forKeyPath:kCurrentItemKey
                      options:NSKeyValueObservingOptionNew
                      context:AVCurrentItemObservationContext];
    //
    // Observer the AVAPlayer "rate" property to see when the track start/stops playing
    //
    [_audioPlayer addObserver:self
                   forKeyPath:kRateKey
                      options:NSKeyValueObservingOptionNew
                      context:AVRateObservationContext];
    //
    // Subscribe to notifications
    //
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(audioSessionRouteChanged:)
               name:AVAudioSessionRouteChangeNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(audioSessionInterrupted:)
               name:AVAudioSessionInterruptionNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerEnteredBackground:)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerEnteredForeground:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(networkConnectionChanged:)
               name:kReachabilityChangedNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(playerItemReadyToPlay:)
               name:RDMusicPlayerAssetReadyToPlayNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerItemPlayable:)
               name:RDMusicPlayerAssetPlayableNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerItemFailedToLoad:)
               name:RDMusicPlayerAssetFailedToLoadNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerItemPlayedToEnd:)
               name:RDMusicPlayerAssetPlayedToEndNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(playerItemStalled:)
               name:RDMusicPlayerAssetStalledNotification
             object:nil];
    
}

- (void)activateSession
{
    NSError *activationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    if (!success) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Failed to activating audio services with error: %@", activationError);
#endif
    }
}


- (BOOL)safeToPlay
{
    //
    // If we are already showing the actionsheet then return
    //
    if (_bIsShowingNetworkChangedActionSheet)
        return NO;
                    
    NetworkStatus status = [_reachability currentReachabilityStatus];
    if (status == ReachableViaWWAN) {
        RDAppPreference * preferences = [[RDAppPreference alloc] init];
        if (preferences.alertNotOnWifi && !_continuePlayingOnCellular) {
             _bIsShowingNetworkChangedActionSheet = YES;
            
            id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
            UITabBarController * tabController = (UITabBarController *)appDelegate.window.rootViewController;
            UIView * presentInView = tabController.tabBar;
            
            if (!presentInView.window) {
                UINavigationController * navController = (UINavigationController *)tabController.selectedViewController;
                presentInView = navController.visibleViewController.view;
            }
            //
            // Ask the user if they would like to continue
            //
            RDInternetDetectionActionSheet * alert = [[RDInternetDetectionActionSheet alloc] init];
            if (![alert showInView:presentInView])
                return _bIsShowingNetworkChangedActionSheet = NO;

            _bIsShowingNetworkChangedActionSheet = NO;
            _continuePlayingOnCellular = YES;
        }
    }
    
    return YES;
}


#pragma mark - Notifications

- (void)networkConnectionChanged:(NSNotification *)notification
{
    __block NetworkStatus status = [_reachability currentReachabilityStatus];
#ifdef DEBUG
    NSString * strStatus;
    switch (status) {
        case ReachableViaWWAN:
            strStatus = @"Cellular Network";
            break;
        case ReachableViaWiFi:
            strStatus = @"Wifi";
            break;
        default:
            strStatus = @"Offline";
            break;
    }
    NSLog(@"RDMusicPlayer - Internet connection changed to %@", strStatus);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        //
        // See if we are currently playing a track and if our status
        // changed to Cellular as well
        //
        if (self.isPlaying && status == ReachableViaWWAN) {
            //
            // We are so lets see if we care if we stream on cellular
            //
            RDAppPreference * preferences = [[RDAppPreference alloc] init];
            if (preferences.alertNotOnWifi && !_continuePlayingOnCellular) {
                //
                // We do so lets pause the app and send an alert
                //
                [self pause];
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerConnectionInterruptionNotification object:self.currentTrack];
                
                [self performBlock:^{
                    //
                    // Lets see if we are in the background and if so we will send a
                    // notification to get the user's attention.
                    //
                    if (_bInBackground)
                        [[UIApplication sharedApplication] postNotificationMessage:@"We've paused your music because your network connection has changed from WIFI to Cellular"];
                    

                    if ([self safeToPlay]) {
                        //
                        // They want to continue so lets keep going
                        //
                        [self resume];
                        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackResumeNotification object:self.currentTrack];
                    } else {
                        //
                        // Before we continue lets see if the network has changed
                        // because if they are on wifi now then don't bother sending
                        // the will not play on cellular notification
                        //
                        NetworkStatus status = [_reachability currentReachabilityStatus];
                        if (status != ReachableViaWiFi) {
                            //
                            // They opt'd out so lets stop the track
                            //
                            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerWillNotPlayOnCellularNotification object:self.currentTrack];
                        }
                    }
                } afterDelay:1.0];
            }
        } else if (self.isPlaying && status == NotReachable) {
            [self stop];
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerConnectionInterruptionNotification object:self.currentTrack];
        }
    });
}

- (void)audioSessionInterrupted:(NSNotification *)notification
{
    static BOOL bWasPlaying = NO;
    
    NSNumber *key = [[notification userInfo] objectForKey: AVAudioSessionInterruptionTypeKey];
    if (key.unsignedIntValue == AVAudioSessionInterruptionTypeBegan) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Session was interrupted");
#endif
        bWasPlaying = self.isPlaying;
        if (bWasPlaying) {
            //
            // Something interrupted us so pause it
            //
            [self pause];
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackInterruptedNotification object:nil];
        }
    } else if (key.unsignedIntValue == AVAudioSessionInterruptionTypeEnded) {
        NSNumber * option = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
        if (option.unsignedIntValue == AVAudioSessionInterruptionOptionShouldResume) {
#ifdef DEBUG
            NSLog(@"RDMusicPlayer - Session is resumming");
#endif
            //
            // Now see if we were already paused because if we then
            // we will just skip it otherwise lets automatically resume
            //
            if (bWasPlaying) {
                //
                // Resume play
                //
                [self resume];
                //
                // Notify the UI
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackResumeNotification object:nil];
            };
        }
    }
}


- (void)audioSessionRouteChanged:(NSNotification *)notification
{
    static BOOL bWasPlaying = NO;
    
    NSNumber *key = [[notification userInfo] objectForKey: AVAudioSessionRouteChangeReasonKey];
    if (key.unsignedIntValue == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Headset was unplgged");
#endif
        bWasPlaying = self.isPlaying;
        if (bWasPlaying) {
            //
            // Something interrupted us so pause it
            //
            [self pause];
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackInterruptedNotification object:nil];
        }
    } else if (key.unsignedIntValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - Headset plugged in");
#endif
        //
        // Now see if we were already paused because if we then
        // we will just skip it otherwise lets automatically resume
        //
        if (bWasPlaying) {
            bWasPlaying = NO;
            //
            // Resume play
            //
            [self resume];
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackResumeNotification object:nil];
        };

    }
}


- (void)playerItemPlayable:(NSNotification *)notification
{
    RDMusicTrack * readyTrack = (RDMusicTrack *)[notification object];
#ifdef DEBUG
    NSLog(@"RDMusicPlayer - playerItemPlayable  Track title '%@' is playable", readyTrack.name);
#endif
    //
    // See if this item is the last queued item and if so lets observe and play
    //
    @try {
        if ([readyTrack isEqualToTrack:self.queuedTrack])
            [_audioPlayer replaceCurrentItemWithPlayerItem:readyTrack.playerItem];
    }
    @catch (NSException *exception) {
        //
        // Occassionally this fails so we just eat it and move on
        //
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - playerItemPlayable threw an exception: %@", exception.reason);
#endif
        [self playerItemFailedToLoad:notification];
        return;
    }
    
    //
    // Remove the track from the queued requests
    //
    NSMutableArray * queuedTrackRequests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
    for (int ndx =0; ndx < queuedTrackRequests.count; ndx++) {
        NSString * streamLocation = [queuedTrackRequests objectAtIndex:ndx];
        if ([streamLocation isEqualToString:readyTrack.streamLocation]) {
            [queuedTrackRequests removeObject:streamLocation];
            break;
        }
    }

}

- (void)playerItemReadyToPlay:(NSNotification *)notification
{
    RDMusicTrack * track = (RDMusicTrack *)[notification object];
#ifdef DEBUG
    NSLog(@"RDMusicPlayer - playerItemReadyToPlay - Track title '%@' ready to play", track.name);
#endif
    [self playItem:track.playerItem];
}


- (void)playerItemStalled:(NSNotification *)notification
{
    _state = RDMusicPlayerStateBuffering;
#ifdef DEBUG
    RDMusicTrack * track = (RDMusicTrack *)[notification object];
    NSLog(@"RDMusicPlayer - playerItemStalled - Track title '%@' stalled", track.name);
#endif
    //
    // Let the UI know we are buffering and we will try again
    // to play in 5 secs
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackBufferingNotification object:nil];
    //
    // Request some time if we are in the background
    //
    if (_bInBackground)
        [self startBackgroundRequest];
    
    [self performBlock:^{
        //
        // Make sure we are in the same state
        //
        if (_state == RDMusicPlayerStateBuffering) {
            [self resume];
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackResumeNotification object:nil];
        }
        //
        // Kill the task
        //
        if (_bInBackground)
            [self endBackgroundRequest];
        
    } afterDelay:5.0];
}


- (void)playerItemFailedToLoad:(NSNotification *)notification
{
    
    RDMusicTrack * track = (RDMusicTrack *)[notification object];
#ifdef DEBUG
    NSLog(@"RDMusicPlayer - playerItemFailedToLoad - Track title '%@' failed to load", track.name);
#endif
    //
    // Only report this if the track that failed to load is current or queued track
    // otherwise this probably happened while we were preloading the tracks in @setPlayList()
    //
    if ([track isEqualToTrack:self.queuedTrack]) {
        //
        // Detect if we are in the background so we can proceed to the
        // next track instead of stalling out
        //
        if (_bInBackground) {
            //
            // Check the threshold for sending this alert so we don't spam the user
            //
            if (++_playAttempts < MAX_PLAY_ATTEMPTS) {
                //
                // Notify the user that we're playing the next track because this one stalled
                //
                NSString * message = [NSString stringWithFormat:@"Sorry, track #%i '%@' failed to load so we're skipping on to the next track", track.number, track.name];
                [[UIApplication sharedApplication] postNotificationMessage:message];
                
                [self playNextTrack];
            } else {
                //
                // Let the user know we are going to stop trying because there is probably
                // and issue going on with the connection to Dropbox
                //
                NSString * message = @"We've skipped too many tracks please check your Dropbox connection settings.";
                [[UIApplication sharedApplication] postNotificationMessage:message];
            }
        } else {
            //
            // Set the state
            //
            _state = RDMusicPlayerStateStopped;
            //
            // Notify the UI
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackFailedToLoadNotification  object:nil];
        }
    }
    //
    // Remove the track from the queued requests
    //
    NSMutableArray * queuedTrackRequests = [_metaPlayerInfo objectForKey:RDQueuedTrackRequestsKey];
    for (int ndx =0; ndx < queuedTrackRequests.count; ndx++) {
        NSString * streamLocation = [queuedTrackRequests objectAtIndex:ndx];
        if ([streamLocation isEqualToString:track.streamLocation]) {
            [queuedTrackRequests removeObject:streamLocation];
            //
            // Check to see if this is queued too
            //
            if ([streamLocation isEqualToString:self.queuedTrack.streamLocation])
                [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
            
            break;
        }
    }
    //
    // Check to see if we have any requests in the queue
    //
    if (queuedTrackRequests.count == 0)
        _loadPlaylistOp = nil;
}

- (void)playerItemPlayedToEnd:(NSNotification *)notification
{
    //
    // Stop/Start background task
    //
    [self endBackgroundRequest];
    [self startBackgroundRequest];
    //
    // Update the play count
    //
    double totalSeconds = CMTimeGetSeconds(self.currentTrack.duration);
    [[RDMusicRepository sharedInstance] updatePlayTime:totalSeconds];
    //
    // Figure out if we need to put this track on repeat
    //
    if (self.currentTrack.repeat) {
        //
        // Reset the track and play it again
        //
        [self seekTo:0.5];
        [self playTrack:self.currentTrack];
    } else {
        [self stop];
        //
        // Broadcast a message to the UI that the track ended
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackEndedNotification object:nil];
        //
        // Play the next track
        //
        [self playNextTrack];
    }
}


- (void)playerEnteredBackground:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDMusicPlayer - Player entered background");
#endif
    _bInBackground = YES;
    //
    // See if we have any requests going in the background
    // that way we can ask for time to complete
    //
    if (_fetchBackgroundTaskID == UIBackgroundTaskInvalid && _playlist) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - registering background task");
#endif
        _fetchBackgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
#ifdef DEBUG
            NSLog(@"RDMusicPlayer - Background Time:%f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
#endif
            if (_fetchBackgroundTaskID != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:_fetchBackgroundTaskID];
                _fetchBackgroundTaskID = UIBackgroundTaskInvalid;
            }
        }];
    }
}


- (void)playerEnteredForeground:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDMusicPlayer - Player entered foreground");
#endif
    _bInBackground = NO;
    if (_fetchBackgroundTaskID != UIBackgroundTaskInvalid) {
#ifdef DEBUG
        NSLog(@"RDMusicPlayer - unregistering the background task");
#endif
        [[UIApplication sharedApplication] endBackgroundTask:_fetchBackgroundTaskID];
        _fetchBackgroundTaskID = UIBackgroundTaskInvalid;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCurrentItemObservationContext) {
        if (_audioPlayer.currentItem) {
            //
            // Called when the AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did occur.
            //
            [self removePlayerTimeObserver];
        }

    } else if (context == AVRateObservationContext) {
        //
        // Check the status on the player
        //
        if (_audioPlayer.rate == 1.0 && self.currentTrack) {
            //
            // We are officially playing
            //
            RDMUsicPlayerState oldState = _state;
            _state = RDMusicPlayerStatePlaying;
            //
            // Check to make sure we have a valid duration time
            //
            Float64 duration = CMTimeGetSeconds(self.currentTrack.duration);
            if (duration == NAN) {
                RDMusicTrack * currentTrack = self.currentTrack;
                //
                // Reset
                //
                [self stop];
                [_metaPlayerInfo setValue:nil forKey:RDCurrentTrackKey];
                [_metaPlayerInfo setValue:nil forKey:RDQueuedTrackKey];
                //
                // Notify the UI
                //
                [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackFailedToLoadNotification object:currentTrack];
            } else {
                //
                // Check to see if the state was loading so we can send the UI a notification
                // that the track has started playing
                //
                if (oldState == RDMusicPlayerStateLoading) {
                    //
                    // Set the media player content
                    //
                    [self updateMediaCenter];
                    //
                    // Notify the UI
                    //
                    [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackStartedNotification object:self.currentTrack];
                }
            }
        }
    }
}



#pragma mark - Class Method

+ (RDMusicPlayer *)sharedInstance
{
    static RDMusicPlayer * instance = nil;
    if (instance == nil)
    {
        NSThread * currentThread = [NSThread currentThread];
        NSThread * mainThread = [NSThread mainThread];
        //
        // We won't initialize this shared instance unless its on
        // the main thread
        //
        if (mainThread == currentThread) {
            instance = [[RDMusicPlayer alloc] init];
            [instance initialize];
        }
    }
    
    return instance;
}


@end

