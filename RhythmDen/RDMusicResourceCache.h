//
//  RDMusicResourceCache.h
//  RhythmDen
//
//  Created by Donelle Sanders on 5/26/13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define ResourceCacheCellBackColorKey @"ResourceCacheCellBackColor"
#define ResourceCacheCellHighlightedBackColorKey @"ResourceCacheCellHighlightedBackColor"
#define ResourceCacheViewBackColorKey @"ResourceCacheViewBackColor"


@interface RDMusicResourceCache : NSObject

@property (readonly, nonatomic) UIImage * transparentImage;
@property (readonly, nonatomic) UIImage * missingCoverArtImage;
@property (readonly, nonatomic) UIImage * playlistThumbImage;
@property (readonly, nonatomic) UIImage * playlistCoverArt;
@property (readonly, nonatomic) NSArray * viewGradientBackColors;
@property (readonly, nonatomic) NSArray * cellGradientBackColors;
@property (readonly, nonatomic) UIColor * darkBackColor;
@property (readonly, nonatomic) UIColor * lightBackColor;

/* UI Control Colors */

@property (readonly, nonatomic) UIColor * tabBarBackgroundColor;
@property (readonly, nonatomic) UIColor * labelTitleTextColor;
@property (readonly, nonatomic) UIColor * cellHighlightedBackColor;
@property (readonly, nonatomic) UIColor * cellSelectionBackColor;
@property (readonly, nonatomic) UIColor * cellBorderColor;
@property (readonly, nonatomic) UIColor * tableIndexTrackingColor;
@property (readonly, nonatomic) UIColor * barTintColor;
@property (readonly, nonatomic) UIColor * buttonBackgroundColor;
@property (readonly, nonatomic) UIColor * buttonTextColor;

- (void)initializeTheme;
- (void)clearCache;
-(UIImage *)gradientImageByKey:(NSString *)key withRect:(CGRect)rect withColors:(NSArray *)colors;

+ (RDMusicResourceCache *)sharedInstance;

@end
