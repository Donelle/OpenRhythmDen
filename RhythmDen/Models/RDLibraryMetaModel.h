//
//  RDLibraryMetaModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/17/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RDLibraryMetaModel : NSManagedObject

@property (nonatomic) int32_t totalAlbums;
@property (nonatomic) double totalPlayTime;
@property (nonatomic) int32_t totalTracks;
@property (nonatomic, retain) NSString * version;

@end
