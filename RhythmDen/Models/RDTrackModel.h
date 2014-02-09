//
//  RDTrackModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/12/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RDAlbumModel, RDPlaylistModel;

@interface RDTrackModel : NSManagedObject

@property (nonatomic) int16_t trackDisc;
@property (nonatomic) NSTimeInterval trackFetchDate;
@property (nonatomic, retain) NSString * trackiTunesLookupId;
@property (nonatomic, retain) NSString * trackiTunesUrl;
@property (nonatomic, retain) NSString * trackLocation;
@property (nonatomic, retain) NSString * trackName;
@property (nonatomic) int32_t trackNumber;
@property (nonatomic) int32_t trackPlayCount;
@property (nonatomic, retain) NSString * trackPrevName;
@property (nonatomic, retain) NSString * trackUrl;
@property (nonatomic, retain) RDAlbumModel *trackAlbums;
@property (nonatomic, retain) NSSet *trackPlaylists;
@end

@interface RDTrackModel (CoreDataGeneratedAccessors)

- (void)addTrackPlaylistsObject:(RDPlaylistModel *)value;
- (void)removeTrackPlaylistsObject:(RDPlaylistModel *)value;
- (void)addTrackPlaylists:(NSSet *)values;
- (void)removeTrackPlaylists:(NSSet *)values;

@end
