//
//  RDPlaylistModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/12/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RDTrackModel;

@interface RDPlaylistModel : NSManagedObject

@property (nonatomic, retain) NSData * colorScheme;
@property (nonatomic) NSTimeInterval createDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * thumb;
@property (nonatomic, retain) NSSet *playlistTracks;
@end

@interface RDPlaylistModel (CoreDataGeneratedAccessors)

- (void)addPlaylistTracksObject:(RDTrackModel *)value;
- (void)removePlaylistTracksObject:(RDTrackModel *)value;
- (void)addPlaylistTracks:(NSSet *)values;
- (void)removePlaylistTracks:(NSSet *)values;

@end
