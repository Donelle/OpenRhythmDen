//
//  RDAlbumModel+RhythmDen.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/21/13.
//
//

#import "RDModels+RhythmDen.h"
#import "RDMusicRepository.h"


@implementation RDAlbumModel (RhythmDen)

- (NSString *)firstLetter
{
    NSString *aString = [self.albumTitle uppercaseString];
    return [aString substringWithRange:[aString rangeOfComposedCharacterSequenceAtIndex:0]];
}

- (void)setColorSchemeWith:(NSDictionary *)colorsDictionary
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:colorsDictionary forKey:@"colorScheme"];
    [archiver finishEncoding];
    
    self.albumColorScheme = data;
}


- (NSDictionary *)getColorSchemeDictionary
{
    NSDictionary * colorsDicitionary = nil;
    
    if (self.albumColorScheme) {
        NSData *data = [NSMutableData dataWithData:self.albumColorScheme];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        colorsDicitionary = [unarchiver decodeObjectForKey:@"colorScheme"];
        [unarchiver finishDecoding];
    }
    
    return colorsDicitionary;
}


@end

@implementation RDArtistModel (RhythmDen)

- (NSString *)firstLetter
{
    NSString *aString = [self.artistName uppercaseString];
    return  [aString substringWithRange:[aString rangeOfComposedCharacterSequenceAtIndex:0]];
}

- (NSArray *)sortedAlbums
{
    NSSortDescriptor * sortOption =
        [NSSortDescriptor sortDescriptorWithKey:@"albumTitle"
                                      ascending:YES
                                     comparator:^NSComparisonResult(id obj1, id obj2) {
                                         NSString * title1 = (NSString *)obj1;
                                         NSString * title2 = (NSString *)obj2;
                                         
                                         return [title1 compare:title2];
                                         
                                     }];
    return [self.artistAlbums sortedArrayUsingDescriptors:@[sortOption]];
}

@end

