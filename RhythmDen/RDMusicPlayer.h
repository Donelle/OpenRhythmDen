//
//  RDMusicPlayer.h
//  RhythmDen
//
//  Created by Donelle Sanders on 2/24/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define RDMusicPlayerAssetFailedToLoadNotification @"AssetFailedToLoadNotification"
#define RDMusicPlayerAssetPlayableNotification @"AssetPlayableNotification"
#define RDMusicPlayerAssetReadyToPlayNotification @"AssetReadyToPlayNotification"
#define RDMusicPlayerAssetStartedPlayingNotification @"AssetStartedPlayingNotification"
#define RDMusicPlayerAssetPlayedToEndNotification @"AssetPlayedToEndNotification"
#define RDMusicPlayerAssetFailedToPlayToEndNotification @"AssetFailedToPlayToEndNotification"
#define RDMusicPlayerAssetStalledNotification @"AssetStalledNotification"
#define RDMusicPlayerTrackLoadingNotification @"TrackLoadingNotification"
#define RDMusicPlayerTrackStartedNotification @"TrackStartedNotification"
#define RDMusicPlayerTrackEndedNotification @"TrackEndedNotification"
#define RDMusicPlayerTrackUpdateNotification @"TrackUpdateNotification"
#define RDMusicPlayerTrackInterruptedNotification @"TrackInterruptedNotification"
#define RDMusicPlayerTrackFailedToLoadNotification @"TrackFailedToLoadNotification"
#define RDMusicPlayerTrackPausedNotification @"TrackPausedNotification"
#define RDMusicPlayerTrackResumeNotification @"TrackResumeNotification"
#define RDMusicPlayerTrackBufferingNotification @"TrackBufferingNotification"
#define RDMusicPlayerEndOfPlaylistNotification @"EndOfPlaylistNotification"
#define RDMusicPlayerConnectionInterruptionNotification @"ConnectionInterruptionNotification"
#define RDMusicPlayerWillNotPlayOnCellularNotification @"WillNotPlayOnCellularNotification"

@class RDMusicPlaylist;

@interface RDMusicTrack : NSObject

@property (strong, nonatomic) NSData * coverArt;
@property (strong, nonatomic) NSData * thumbNail;
@property (assign, nonatomic) int disc;
@property (assign, nonatomic) int number;
@property (copy, nonatomic) NSString * name;
@property (readonly, nonatomic) CMTime duration;
@property (strong, nonatomic) NSURL * streamURL;
@property (strong, nonatomic) NSDate * streamExpireDate;
@property (copy, nonatomic) NSString * streamLocation;
@property (copy, nonatomic) NSString * albumName;
@property (copy, nonatomic) NSString * albumArtist;
@property (strong, nonatomic) NSURL * iTunesUrl;
@property (weak, nonatomic) RDMusicPlaylist * playlist;
@property (assign, nonatomic) BOOL repeat;
@property (readonly, nonatomic) BOOL isCurrentTrack;
@property (readonly, nonatomic) BOOL isStreamExpired;

- (BOOL)isEqualToTrack:(RDMusicTrack *)track;

@end


@interface RDMusicPlaylist : NSObject

@property (strong, nonatomic) id playlistId;
@property (copy, nonatomic) NSString * name;
@property (copy, nonatomic) NSString * artist;
@property (strong, nonatomic) NSData * coverArt;
@property (strong, nonatomic) NSData * thumbNail;
@property (strong, nonatomic) NSDictionary * colorScheme;
@property (readonly, nonatomic) int tracksTotal;
@property (readonly, nonatomic) int discs;
@property (assign, nonatomic) BOOL isMix;
@property (assign, nonatomic) BOOL iTunesVerified;
@property (readonly, nonatomic) BOOL preloaded;

- (BOOL)isEqualToPlaylist:(RDMusicPlaylist *)playlist;
- (void)addTrackModels:(NSArray *)models;
- (void)addTrack:(RDMusicTrack *)track;
- (void)removeTrack:(RDMusicTrack *)track;
- (int)trackCountForDisc:(int)disc;
- (RDMusicTrack *)trackAtIndex:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathFromTrack:(RDMusicTrack *)track;
- (NSArray *)tracksForDisc:(int)disc;

@end


@interface RDMusicPlayer : NSObject

@property (readonly, nonatomic) BOOL isLoading;
@property (readonly, nonatomic) BOOL isPlaying;
@property (readonly, nonatomic) BOOL isPaused;
@property (readonly, nonatomic) BOOL hasStopped;
@property (readonly, nonatomic) BOOL inBackgroundMode;
@property (readonly, nonatomic) RDMusicTrack * currentTrack;
@property (readonly, nonatomic) RDMusicTrack * queuedTrack;
@property (readonly, nonatomic) Float64 position;
@property (assign, nonatomic) BOOL playerIsVisible;
@property (assign, nonatomic) BOOL continuePlayingOnCellular;
@property (strong, nonatomic) RDMusicPlaylist * playlist;

- (void)playTrack:(RDMusicTrack *)track;
- (void)playNextTrack;
- (void)playPrevTrack;
- (void)pause;
- (void)resume;
- (void)seekTo:(Float64)position;
- (void)stop;
- (BOOL)safeToPlay;

+ (RDMusicPlayer *)sharedInstance;

@end

