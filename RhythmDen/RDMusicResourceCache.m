//
//  RDMusicResourceCache.m
//  RhythmDen
//
//  Created by Donelle Sanders on 5/26/13.
//
//

#import "RDMusicResourceCache.h"

@implementation RDMusicResourceCache
{
    NSMutableDictionary * _gradientImages;
}

@synthesize missingCoverArtImage = _missingCoverArtImage;
@synthesize tableIndexTrackingColor = _tableIndexTrackingColor;
@synthesize labelTitleTextColor = _labelTitleTextColor;
@synthesize cellSelectionBackColor = _cellSelectionBackColor;
@synthesize cellGradientBackColors = _cellGradientBackColors;
@synthesize cellBorderColor = _cellBorderColor;
@synthesize cellHighlightedBackColor = _cellHighlightedBackColor;
@synthesize transparentImage = _transparentImage;
@synthesize tabBarBackgroundColor = _tabBarBackgroundColor;
@synthesize viewGradientBackColors = _viewGradientBackColors;
@synthesize barTintColor = _barTintColor;
@synthesize darkBackColor = _darkBackColor;
@synthesize lightBackColor = _lightBackColor;
@synthesize buttonBackgroundColor = _buttonBackgroundColor;
@synthesize buttonTextColor = _buttonTextColor;
@synthesize playlistCoverArt = _playlistCoverArt;
@synthesize playlistThumbImage = _playlistThumbImage;

#pragma mark - Properties

- (NSArray *)viewGradientBackColors
{
    if (!_viewGradientBackColors) {
        UIColor
            *topColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1],
            *middleColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1],
            *bottomColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1];
    
        _viewGradientBackColors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[middleColor CGColor], (id)[bottomColor CGColor], nil];
    }
    
    return _viewGradientBackColors;
}

- (UIColor *)cellHighlightedBackColor
{
    if (!_cellHighlightedBackColor)
        _cellHighlightedBackColor = [UIColor colorWithRed:107.0/255.0 green:62.0/255.0 blue:35.0/255.0 alpha:1];
    
    return _cellBorderColor;
}

- (UIColor *)cellBorderColor
{
    if (!_cellBorderColor)
        _cellBorderColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1];
    
    return _cellBorderColor;
}

- (UIColor *)lightBackColor
{
    if (!_lightBackColor)
        _lightBackColor = [UIColor colorWithRed:251.0/255.0 green:251.0/255.0 blue:251.0/255.0 alpha:1.0]; 
    
    return _lightBackColor;
}

- (UIColor *)darkBackColor
{
    if (!_darkBackColor)
        _darkBackColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1];
    return _darkBackColor;
}

- (UIColor *)barTintColor
{
    if (!_barTintColor)
        _barTintColor = [UIColor colorWithRed:149.0/255.0 green:120.0/255.0 blue:101.0/255.0 alpha:1.0];
    
    return _barTintColor;
}

- (UIColor *)tabBarBackgroundColor
{
    if (!_tabBarBackgroundColor)
        _tabBarBackgroundColor = [UIColor colorWithRed:22.0/255.0 green:12.0/255.0 blue:8.0/255.0 alpha:1.0];
    return _tabBarBackgroundColor;
}

- (UIImage *)missingCoverArtImage
{
    if (!_missingCoverArtImage)
        _missingCoverArtImage = [UIImage imageNamed:@"Missing-Art-Cover-Icon"];
    
    return _missingCoverArtImage;
}

- (UIImage *)playlistThumbImage
{
    if (!_playlistThumbImage)
        _playlistThumbImage = [UIImage imageNamed:@"mix-coverart-thumb.jpg"];
    
    return _playlistThumbImage;
}

- (UIImage *)playlistCoverArt
{
    if (!_playlistCoverArt)
        _playlistCoverArt = [UIImage imageNamed:@"mix-coverart.jpg"];
    
    return _playlistCoverArt;
}

- (UIColor *)tableIndexTrackingColor
{
    if (!_tableIndexTrackingColor)
        _tableIndexTrackingColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1];
    
    return _tableIndexTrackingColor;
}

- (UIColor *)buttonBackgroundColor
{
    if (!_buttonBackgroundColor)
        _buttonBackgroundColor = [UIColor colorWithRed:86.0/255.0 green:69.0/255.0 blue:64.0/255.0 alpha:1.0];
    
    return _buttonBackgroundColor;
}

- (UIColor *)buttonTextColor
{
    if (!_buttonTextColor)
        _buttonTextColor = [UIColor colorWithRed:196.0/255.0 green:180.0/255.0 blue:175.0/255.0 alpha:1.0];
    
    return _buttonTextColor;
}


- (UIColor *)labelTitleTextColor
{
    if (!_labelTitleTextColor)
        _labelTitleTextColor = [UIColor colorWithRed:199.0/255.0 green:164.0/255.0 blue:130.0/255.0 alpha:1.0];
    
    return _labelTitleTextColor;
}

- (UIColor *)cellSelectionBackColor
{
    if (!_cellSelectionBackColor)
        _cellSelectionBackColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1.0];
    
    return _cellSelectionBackColor;
}

- (NSArray *)cellGradientBackColors
{
    if (!_cellGradientBackColors) {
        UIColor
            *topColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1],
            *middleColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1],
            *bottomColor = [UIColor colorWithRed:22.0/255.0 green:13.0/255.0 blue:8.0/255.0 alpha:1];
        
        _cellGradientBackColors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[middleColor CGColor], (id)[bottomColor CGColor], nil];
    }
    
    return _cellGradientBackColors;
}


- (UIImage *)transparentImage
{
    if (!_transparentImage)
        _transparentImage = [UIImage imageNamed:@"transparent"];
    
    return _transparentImage;
}


#pragma mark - Instance Methods

-(void)initializeTheme
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setKeyboardAppearance:UIKeyboardAppearanceDark];
    [[UISearchBar appearance] setTintColor:self.barTintColor];
    [[UINavigationBar appearance] setTintColor:self.barTintColor];
    
}

-(UIImage *)gradientImageByKey:(NSString *)key withRect:(CGRect)rect withColors:(NSArray *)colors
{
    UIImage * image = [_gradientImages objectForKey:key];
    if (!image) {
        CAGradientLayer * gradient = [CAGradientLayer layer];
        gradient.frame = rect;
        gradient.shouldRasterize = YES;
        gradient.colors = colors;
        gradient.startPoint = CGPointMake(0.0, 0.5);
        gradient.endPoint = CGPointMake(1.0, 0.5);
        
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        [gradient renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [_gradientImages setObject:image forKey:key];
    }
    
    return image;
}

- (void)clearCache
{
    [_gradientImages removeAllObjects];
    _missingCoverArtImage = nil;
    _tableIndexTrackingColor = nil;
    _labelTitleTextColor = nil;
    _cellGradientBackColors = nil;
    _cellSelectionBackColor = nil;
    _cellHighlightedBackColor = nil;
    _transparentImage = nil;
    _tabBarBackgroundColor = nil;
    _viewGradientBackColors = nil;
    _barTintColor = nil;
    _darkBackColor = nil;
    _lightBackColor = nil;
    _cellBorderColor = nil;
    _buttonBackgroundColor = nil;
    _buttonTextColor = nil;
    _playlistThumbImage = nil;
    _playlistCoverArt = nil;
}


#pragma mark - Class Methods

+ (RDMusicResourceCache *)sharedInstance
{
    static RDMusicResourceCache * instance = nil;
    if (instance == nil)
        instance = [[RDMusicResourceCache alloc] init];
    
    return instance;
}


@end
