//
//  RDAlbumModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/11/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RDArtistModel, RDTrackModel;

@interface RDAlbumModel : NSManagedObject

@property (nonatomic, retain) NSData * albumArtwork;
@property (nonatomic, retain) NSString * albumArtworkUrl;
@property (nonatomic, retain) NSString * albumiTunesLookupId;
@property (nonatomic, retain) NSString * albumiTunesUrl;
@property (nonatomic) BOOL albumiTunesVerified;
@property (nonatomic, retain) NSString * albumLocation;
@property (nonatomic, retain) NSString * albumPrevTitle;
@property (nonatomic, retain) NSString * albumTitle;
@property (nonatomic, retain) NSData * albumColorScheme;
@property (nonatomic) int16_t albumDiscs;
@property (nonatomic, retain) NSString * albumGenre;
@property (nonatomic, retain) NSData * albumArtworkThumb;
@property (nonatomic) int16_t albumTrackCount;
@property (nonatomic, retain) RDArtistModel *albumArtists;
@property (nonatomic, retain) NSSet *albumTracks;
@end

@interface RDAlbumModel (CoreDataGeneratedAccessors)

- (void)addAlbumTracksObject:(RDTrackModel *)value;
- (void)removeAlbumTracksObject:(RDTrackModel *)value;
- (void)addAlbumTracks:(NSSet *)values;
- (void)removeAlbumTracks:(NSSet *)values;

@end
