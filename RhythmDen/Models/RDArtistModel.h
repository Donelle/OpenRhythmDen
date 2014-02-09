//
//  RDArtistModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/11/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RDAlbumModel;

@interface RDArtistModel : NSManagedObject

@property (nonatomic, retain) NSString * artistiTunesLookupId;
@property (nonatomic, retain) NSString * artistiTunesUrl;
@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSSet *artistAlbums;
@end

@interface RDArtistModel (CoreDataGeneratedAccessors)

- (void)addArtistAlbumsObject:(RDAlbumModel *)value;
- (void)removeArtistAlbumsObject:(RDAlbumModel *)value;
- (void)addArtistAlbums:(NSSet *)values;
- (void)removeArtistAlbums:(NSSet *)values;

@end
