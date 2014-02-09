//
//  RDiTunesSearchService.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 11/12/13.
//
//

#import <Foundation/Foundation.h>
#import "RDMusicPlayer.h"

#define RDiTunesSearchQueryAlbumNameKey @"iTunesSearchQueryAlbumName"
#define RDiTunesSearchQueryAlbumLookupIDKey @"RDiTunesSearchQueryAlbumLookupID"
#define RDiTunesSearchQueryArtistNameKey @"iTunesSearchQueryArtistNameKey"
#define RDiTunesSearchQueryArtistLookupIDKey @"RDiTunesSearchQueryArtistLookupID"
#define RDiTunesSearchQueryTrackNameKey @"iTunesSearchQueryTrackNameKey"
#define RDiTunesSearchQueryTrackLookupIDKey @"RDiTunesSearchQueryTrackLookupID"

#define RDiTunesAlbumNameKey @"RDiTunesAlbumName"
#define RDiTunesAlbumRatingKey @"RDiTunesAlbumRating"
#define RDiTunesArtistNameKey @"RDiTunesArtistName"
#define RDiTunesTrackNameKey @"RDiTunesTrackName"
#define RDiTunesTrackNumberKey @"RDiTunesTrackNumber"
#define RDiTunesTrackCountKey @"RDiTunesTrackCount"
#define RDiTunesArtworkUrlKey @"RDiTunesArtworkUrl"
#define RDiTunesEntityUrlKey @"RDiTunesEntityUrl"
#define RDiTunesEntityLookupIdKey @"RDiTunesEntityLookupId"
#define RDiTunesGenreKey @"RDiTunesGenre"
#define RDiTunesDiscNumberKey @"RDiTunesDiscNumber"

#define RDiTunesTracksKey @"RDiTunesTracks"
#define RDiTunesAlbumskey @"RDiTunesAlbums"
#define RDiTunesFuzzyScoreKey @"RDiTunesFuzzyScore"

@class RDiTunesSearchService;

@protocol RDiTunesSearchServiceDelegate <NSObject>
- (void)iTunesSearchServiceFailed:(RDiTunesSearchService *)service withError:(NSError *)error;

@optional
- (void)iTunesSearchService:(RDiTunesSearchService *)service didSucceedWith:(NSDictionary *)info;
@end

@interface RDiTunesSearchService : NSObject

@property (weak, nonatomic) id<RDiTunesSearchServiceDelegate> delegate;
- (void)search:(NSDictionary *)query;
- (void)lookup:(NSDictionary *)query;

@end
