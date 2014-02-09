//
//  RDMusicLibrary.h
//  RhythmDen
//
//  Created by Donelle Sanders on 4/28/13.
//
//

#import <Foundation/Foundation.h>

#define RDMusicLibrarySyncCompleteNotification @"MusicLibrarySyncCompleteNotification"
#define RDMusicLibrarySyncStartedNotification @"MusicLibrarySyncStartedNotification"
#define RDMusicLibrarySyncCancelledNotification @"MusicLibrarySyncCancelledNotification"
#define RDMusicLibrarySyncFailedNotification @"MusicLibrarySyncFailedNotification"
#define RDMusicLibraryClearedNotification @"MusicLibraryClearedNotification"


@interface RDMusicLibrary : NSObject

@property (readonly, nonatomic) BOOL isSyncronizing;
@property (readonly, nonatomic) BOOL isOnPause;

- (void)syncronize;
- (void)cancelSynchronization;
- (void)pauseSynchronization;
- (void)resumeSynchronization;

+ (RDMusicLibrary *)sharedInstance;

@end
