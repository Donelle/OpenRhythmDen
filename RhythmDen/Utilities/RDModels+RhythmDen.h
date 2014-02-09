//
//  RDAlbumModel+RhythmDen.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/21/13.
//
//

#import <UIKit/UIKit.h>
#import "RDModels.h"

@interface RDAlbumModel (RhythmDen)
@property (nonatomic, readonly) NSString * firstLetter;

- (void)setColorSchemeWith:(NSDictionary *)colorsDictionary;
- (NSDictionary *)getColorSchemeDictionary;

@end

@interface RDArtistModel (RhythmDen)
@property (nonatomic, readonly) NSString * firstLetter;

- (NSArray *) sortedAlbums;

@end
