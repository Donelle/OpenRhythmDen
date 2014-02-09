//
//  RDiTunesSearchService.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 11/12/13.
//
//

#import "RDiTunesSearchService.h"
#import "NSString+RhythmDen.h"
#import "JSONKit.h"

#define ITUNES_SEARCH_SONG_QUERY @"https://itunes.apple.com/search?term=%@+%@+%@&media=music&entity=song&at="
#define ITUNES_SEARCH_ALBUM_QUERY @"https://itunes.apple.com/search?term=%@+%@&media=music&entity=album&at="
#define ITUNES_LOOKUP_QUERY @"https://itunes.apple.com/lookup?id=%@&media=music&entity=song&at="

@interface RDiTunesSearchService ()
- (NSDictionary *)parseLookupResults:(NSDictionary *)results;
- (NSDictionary *)parseSearchResults:(NSDictionary *)results withQuery:(NSDictionary *)query;
- (NSString *)stripExtra:(NSString *)text;

@end

@implementation RDiTunesSearchService

- (void)search:(NSDictionary *)query
{
    NSString * requestString = nil;
    NSString * trackName = [query objectForKey:RDiTunesSearchQueryTrackNameKey];
    NSString * albumName = [self stripExtra:[query objectForKey:RDiTunesSearchQueryAlbumNameKey]];
    NSString * artistName = [query objectForKey:RDiTunesSearchQueryArtistNameKey];
    
    if (trackName) {
        requestString =
            [NSString stringWithFormat:ITUNES_SEARCH_SONG_QUERY,
                [trackName urlEscapeString], [albumName urlEscapeString], [artistName urlEscapeString]];
    } else {
        
        requestString =
            [NSString stringWithFormat:ITUNES_SEARCH_ALBUM_QUERY,
                [albumName urlEscapeString], [artistName urlEscapeString]];
    }
    
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSURLSessionDataTask * task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            if (error) {
#ifdef DEBUG
                                                NSLog(@"RDiTunesSearchService(search) - Failed with %@", error);
#endif
                                                [_delegate iTunesSearchServiceFailed:self withError:error];
                                            } else if (data != nil) {
                                                NSDictionary * results = [data objectFromJSONData];
                                                NSDictionary * info = [self parseSearchResults:results withQuery:query];
                                                
                                                [_delegate iTunesSearchService:self didSucceedWith:info];
                                            }
                                        }];
    [task resume];
}

- (void)lookup:(NSDictionary *)query
{
    NSString * lookupId = [query objectForKey:RDiTunesSearchQueryTrackLookupIDKey];
    if (!lookupId) lookupId = [query objectForKey:RDiTunesSearchQueryAlbumLookupIDKey];
    
    NSString * requestString = [NSString stringWithFormat:ITUNES_LOOKUP_QUERY, lookupId];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    
    NSURLSessionDataTask * task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            if (error) {
#ifdef DEBUG
                                                NSLog(@"RDiTunesSearchService(lookup) - Failed with %@", error);
#endif
                                                [_delegate iTunesSearchServiceFailed:self withError:error];
                                            } else if (data != nil) {
                                                NSDictionary * results = [data objectFromJSONData];
                                                NSDictionary * info = [self parseLookupResults:results];
                
                                                [_delegate iTunesSearchService:self didSucceedWith:info];
                                            }
                                        }];
    [task resume];
}


#pragma mark - Helper Methods

- (NSDictionary *)parseSearchResults:(NSDictionary *)results withQuery:(NSDictionary *)query
{
    __block NSMutableDictionary * parsedResults = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array], RDiTunesTracksKey, [NSMutableArray array], RDiTunesAlbumskey, nil];
    NSArray * records = [results objectForKey:@"results"];
    
    [records enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary * info = (NSDictionary *)obj;
        NSString * artistName = [[info objectForKey:@"artistName"] lowercaseString];
        NSString * albumName = [[info objectForKey:@"collectionName"] lowercaseString];
        
        NSString * wrapperType = [info objectForKey:@"wrapperType"];
        if ([wrapperType isEqualToString:@"collection"]) {
            NSString *queryAristName = [[query objectForKey:RDiTunesSearchQueryArtistNameKey] lowercaseString];
            float artistScore =  [queryAristName scoreAgainst:artistName
                                                    fuzziness:[NSNumber numberWithFloat:1.0]];
            
            NSString *queryAlbumName = [[query objectForKey:RDiTunesSearchQueryAlbumNameKey] lowercaseString];
            float albumScore = [queryAlbumName scoreAgainst:albumName
                                                  fuzziness:[NSNumber numberWithFloat:1.0]];
#ifdef DEBUG
            NSLog(@"RDiTunesSearchService - Query: '{\n%@' = '%@';\n%@' = '%@';\n}'\nAlbumName: '%@'\nArtistName: '%@'\nScores: albumName (%f), artistName (%f)",
                  RDiTunesSearchQueryAlbumNameKey, queryAlbumName, RDiTunesSearchQueryArtistNameKey, queryAristName, albumName, artistName, albumScore, artistScore);
#endif
            NSMutableDictionary * album = [NSMutableDictionary dictionaryWithCapacity:9];
            NSMutableDictionary * scores = [NSMutableDictionary dictionaryWithCapacity:2];
            [scores setObject:@(artistScore != INFINITY ?:0) forKey:RDiTunesArtistNameKey];
            [scores setObject:@(albumScore != INFINITY ?:0) forKey:RDiTunesAlbumNameKey];
            [album setObject:scores forKey:RDiTunesFuzzyScoreKey];
            
            [album setObject:[info objectForKey:@"collectionId"]  forKey:RDiTunesEntityLookupIdKey];
            [album setObject:[info objectForKey:@"collectionName"]  forKey:RDiTunesAlbumNameKey];
            [album setObject:[info objectForKey:@"artistName"]  forKey:RDiTunesArtistNameKey];
            [album setObject:[info objectForKey:@"primaryGenreName"] forKey:RDiTunesGenreKey];
            [album setObject:[[info objectForKey:@"artworkUrl100"] stringByReplacingOccurrencesOfString:@"100x100" withString:@"600x600"] forKey:RDiTunesArtworkUrlKey];
            [album setObject:[info objectForKey:@"collectionViewUrl"] forKey:RDiTunesEntityUrlKey];
            [album setObject:[info objectForKey:@"trackCount"] forKey:RDiTunesTrackCountKey];
            
            NSString * contentRating = [info objectForKey:@"contentAdvisoryRating"];
            if (!contentRating) {
                NSString * explictNess = [info objectForKey:@"collectionExplicitness"];
                contentRating = [explictNess isEqualToString:@"notExplicit"] ? @"Non Explicit" : @"Explicit";
            }
            
            [album setObject:contentRating forKey:RDiTunesAlbumRatingKey];
            
            NSMutableArray * albums = [parsedResults objectForKey:RDiTunesAlbumskey];
            [albums addObject:album];
        } else if ([wrapperType isEqualToString:@"track"]) {
            NSString * trackName = [[info objectForKey:@"trackName"] lowercaseString];
            
            NSString *queryAristName = [[query objectForKey:RDiTunesSearchQueryArtistNameKey] lowercaseString];
            float artistScore = [queryAristName scoreAgainst:artistName fuzziness:[NSNumber numberWithFloat:1.0]];
            
            NSString *queryAlbumName = [[query objectForKey:RDiTunesSearchQueryAlbumNameKey] lowercaseString];
            float albumScore = [queryAlbumName scoreAgainst:albumName fuzziness:[NSNumber numberWithFloat:1.0]];
            
            NSString *queryTrackName = [[query objectForKey:RDiTunesSearchQueryTrackNameKey] lowercaseString];
            float trackScore = [queryTrackName scoreAgainst:trackName
                                       fuzziness:[NSNumber numberWithFloat:1.0]
                                         options:NSStringScoreOptionReducedLongStringPenalty];
#ifdef DEBUG
            NSLog(@"RDiTunesSearchService - Query: '{\n%@' = '%@';\n%@' = '%@';\n%@' = '%@';\n}'\nAlbumName: '%@'\nArtistName: '%@'\nTrackName: '%@'\nScores: albumName (%f), artistName (%f), trackName (%f)",
                  RDiTunesSearchQueryAlbumNameKey, queryAlbumName, RDiTunesSearchQueryArtistNameKey, queryAristName, RDiTunesSearchQueryTrackNameKey, queryTrackName, albumName, artistName, trackName, albumScore, artistScore, trackScore);
#endif
            NSMutableDictionary * track = [NSMutableDictionary dictionaryWithCapacity:10];
            NSMutableDictionary * scores = [NSMutableDictionary dictionaryWithCapacity:2];
            [scores setObject:@(artistScore != INFINITY ?:0) forKey:RDiTunesArtistNameKey];
            [scores setObject:@(albumScore != INFINITY ?:0) forKey:RDiTunesAlbumNameKey];
            [scores setObject:@(trackScore != INFINITY ?:0) forKey:RDiTunesTrackNameKey];
            [track setObject:scores forKey:RDiTunesFuzzyScoreKey];

            [track setObject:[info objectForKey:@"trackId"]  forKey:RDiTunesEntityLookupIdKey];
            [track setObject:[info objectForKey:@"trackName"] forKey:RDiTunesTrackNameKey];
            [track setObject:[info objectForKey:@"trackNumber"] forKey:RDiTunesTrackNumberKey];
            [track setObject:[info objectForKey:@"artistName"] forKey:RDiTunesArtistNameKey];
            [track setObject:[info objectForKey:@"discNumber"] forKey:RDiTunesDiscNumberKey];
            [track setObject:[info objectForKey:@"collectionName"]  forKey:RDiTunesAlbumNameKey];
            [track setObject:[info objectForKey:@"primaryGenreName"] forKey:RDiTunesGenreKey];
            [track setObject:[info objectForKey:@"artworkUrl100"] forKey:RDiTunesArtworkUrlKey];
            [track setObject:[info objectForKey:@"trackViewUrl"] forKey:RDiTunesEntityUrlKey];
            
            NSMutableArray * tracks = [parsedResults objectForKey:RDiTunesTracksKey];
            [tracks addObject:track];
        }
    }];
    return parsedResults;
}


- (NSDictionary *)parseLookupResults:(NSDictionary *)results
{
    __block NSMutableDictionary * parsedResults = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:RDiTunesTracksKey];
    NSArray * records = [results objectForKey:@"results"];
    
    [records enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary * info = (NSDictionary *)obj;
        NSString * wrapperType = [info objectForKey:@"wrapperType"];
        
        if ([wrapperType isEqualToString:@"collection"]) {
            [parsedResults setObject:[info objectForKey:@"collectionId"]  forKey:RDiTunesEntityLookupIdKey];
            [parsedResults setObject:[info objectForKey:@"collectionName"]  forKey:RDiTunesAlbumNameKey];
            [parsedResults setObject:[info objectForKey:@"artistName"]  forKey:RDiTunesArtistNameKey];
            [parsedResults setObject:[info objectForKey:@"primaryGenreName"] forKey:RDiTunesGenreKey];
            [parsedResults setObject:[[info objectForKey:@"artworkUrl100"] stringByReplacingOccurrencesOfString:@"100x100" withString:@"600x600"] forKey:RDiTunesArtworkUrlKey];
            [parsedResults setObject:[info objectForKey:@"collectionViewUrl"] forKey:RDiTunesEntityUrlKey];
            [parsedResults setObject:[info objectForKey:@"trackCount"] forKey:RDiTunesTrackCountKey];
            
        } else if ([wrapperType isEqualToString:@"track"]) {
            NSMutableDictionary * track = [NSMutableDictionary dictionaryWithCapacity:9];
            
            [track setObject:[info objectForKey:@"trackId"]  forKey:RDiTunesEntityLookupIdKey];
            [track setObject:[info objectForKey:@"trackName"] forKey:RDiTunesTrackNameKey];
            [track setObject:[info objectForKey:@"trackNumber"] forKey:RDiTunesTrackNumberKey];
            [track setObject:[info objectForKey:@"artistName"] forKey:RDiTunesArtistNameKey];
            [track setObject:[info objectForKey:@"discNumber"] forKey:RDiTunesDiscNumberKey];
            [track setObject:[info objectForKey:@"collectionName"]  forKey:RDiTunesAlbumNameKey];
            [track setObject:[info objectForKey:@"primaryGenreName"] forKey:RDiTunesGenreKey];
            [track setObject:[info objectForKey:@"artworkUrl100"] forKey:RDiTunesArtworkUrlKey];
            [track setObject:[info objectForKey:@"trackViewUrl"] forKey:RDiTunesEntityUrlKey];
            
            NSMutableArray * tracks = [parsedResults objectForKey:RDiTunesTracksKey];
            [tracks addObject:track];
        }
    }];
    return parsedResults;
}


- (NSString *)stripExtra:(NSString *)text
{
    NSRange range = [text rangeOfString:@"(deluxe version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    range = [text rangeOfString:@"(deluxe edition)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    range = [text rangeOfString:@"(remastered)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    range = [text rangeOfString:@"(bonus track version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    range = [text rangeOfString:@"(bonus digital booklet version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    range = [text rangeOfString:@"(bonus video version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }

    range = [text rangeOfString:@"(expanded version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }

    range = [text rangeOfString:@"(clean version)" options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) {
        return [text substringToIndex:range.location - 1];
    }
    
    return text;
}
@end
