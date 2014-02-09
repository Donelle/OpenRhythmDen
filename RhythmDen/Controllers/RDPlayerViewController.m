//
//  RDPlayerViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/17/13.
//
//

#import "RDPlayerViewController.h"
#import "RDPlayerTutorialViewController.h"
#import "RDMusicPlayer.h"
#import "RDMusicResourceCache.h"
#import "RDMusicRepository.h"
#import "RDMusicLibrary.h"
#import "RDInternetDetectionActionSheet.h"
#import "RDSwipeableTableViewCell.h"
#import "RDiTunesSearchService.h"
#import "RDModels+RhythmDen.h"
#import "RDFrostView.h"
#import "RDAlertView.h"
#import "NSObject+RhythmDen.h"
#import "NSArray+RhythmDen.h"
#import "UIImage+RhythmDen.h"
#import "UIColor+RhythmDen.h"
#import "NSString+RhythmDen.h"
#import "LEColorPicker.h"
#import "ActionSheetStringPicker.h"
#import "TKAlertCenter.h"
#import "Reachability.h"
#import "DETAnimatedTransitionController.h"
#import "GPUImageSDK.h"
#import "BitlySDK.h"
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>




#define SECTION_HEIGHT 40.0
#define SELF_VIEW_TAG 64643
#define SCRUBBER_VIEW_TAG 100
#define ALBUMCOVER_VIEW_TAG 101
#define ALBUMCOVER_SCROLLVIEW_TAG 102
#define PLAYER_FROSTVIEW_TAG 103
#define LOADING_VIEW_TAG 104
#define SEARCH_RESULTS_VIEW 105
#define FACEBOOK_BUTTON_ID 200
#define TWITTER_BUTTON_ID 201


#pragma mark - RDPlaylistUpdateDelegate Implementation

typedef enum  { RDPlaylistUpdateTypeNew = 1, RDPlaylistUpdateTypeUpdated = 2 } RDPlaylistUpdateType;

@protocol RDPlaylistUpdateDelegate <NSObject>
- (void)playlist:(RDMusicPlaylist *)playlist didUpdate:(RDPlaylistUpdateType)updateType;
@end


#pragma mark - RDPlayerAlbumVerifyCell Implementation

@interface RDPlayerAlbumVerifyCell : UITableViewCell
@property (strong, nonatomic) NSDictionary * albumInfo;
@end


@implementation RDPlayerAlbumVerifyCell {
    UILabel * _albumArtist;
    UILabel * _albumTitle;
    UILabel * _albumSongs;
    UILabel * _albumRating;
    UIImageView * _albumArtwork;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _albumArtwork = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10, 65, 65)];
        _albumArtwork.clipsToBounds = YES;
        _albumArtwork.layer.cornerRadius = 10.0;
        [self addSubview:_albumArtwork];
        
        _albumTitle = [[UILabel alloc] initWithFrame:CGRectMake(79, 10, 221, 21)];
        _albumTitle.font = [UIFont boldSystemFontOfSize:16.0];
        _albumTitle.textColor = [UIColor colorWithRed:115.0/255.0 green:51.0/255.0 blue:21.0/255.0 alpha:1];
        _albumTitle.textAlignment = NSTextAlignmentLeft;
        _albumTitle.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumTitle.backgroundColor = [UIColor clearColor];
        [self addSubview:_albumTitle];
        
        UIColor * fontColor = [UIColor colorWithRed:150.0/255.0 green:121.0/255.0 blue:101.0/255.0 alpha:1];
        
        _albumArtist = [[UILabel alloc] initWithFrame:CGRectMake(79, 29, 221, 21)];
        _albumArtist.font = [UIFont boldSystemFontOfSize:13.0];
        _albumArtist.textColor = fontColor;
        _albumArtist.textAlignment = NSTextAlignmentLeft;
        _albumArtist.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumArtist.backgroundColor = [UIColor clearColor];
        [self addSubview:_albumArtist];
        
        _albumSongs = [[UILabel alloc] initWithFrame:CGRectMake(80, 49, 100, 21)];
        _albumSongs.font = [UIFont systemFontOfSize:13.0];
        _albumSongs.textColor = fontColor;
        _albumSongs.textAlignment = NSTextAlignmentLeft;
        _albumSongs.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumSongs.backgroundColor = [UIColor clearColor];
        [self addSubview:_albumSongs];
        
        _albumRating = [[UILabel alloc] initWithFrame:CGRectMake(150, 49, 233, 21)];
        _albumRating.font = [UIFont boldSystemFontOfSize:13];
        _albumRating.textColor = fontColor;
        _albumRating.textAlignment = NSTextAlignmentLeft;
        _albumRating.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumRating.backgroundColor = [UIColor clearColor];
        [self addSubview:_albumRating];
        
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        self.backgroundColor = [UIColor colorWithPatternImage:[cache gradientImageByKey:ResourceCacheCellBackColorKey
                                                                               withRect:self.bounds
                                                                             withColors:cache.cellGradientBackColors]];
        
        self.layer.borderColor = cache.cellBorderColor.CGColor;
        self.layer.borderWidth = 0.4f;
    }
    return self;
}

- (void)setAlbumInfo:(NSDictionary *)albumInfo
{
    _albumInfo = albumInfo;

    _albumTitle.text = [albumInfo objectForKey:RDiTunesAlbumNameKey];
    _albumArtist.text = [albumInfo objectForKey:RDiTunesArtistNameKey];
    _albumSongs.text = [NSString stringWithFormat:@"%@ Tracks", [albumInfo objectForKey:RDiTunesTrackCountKey]];
    _albumRating.text = [NSString stringWithFormat:@"(%@ Version)", [albumInfo objectForKey:RDiTunesAlbumRatingKey]];
    _albumArtwork.image = [[RDMusicResourceCache sharedInstance] missingCoverArtImage];
    //
    // Load image
    //
    [self performBlockInBackground:^{
        NSData * artworkData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[albumInfo objectForKey:RDiTunesArtworkUrlKey]]];
        UIImage * albumArt = [[UIImage imageWithData:artworkData] shrink:CGSizeMake(65, 65)];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _albumArtwork.image = albumArt;
        });
    }];
}


@end


#pragma mark - RDPlayerAlbumVerifyController Implementation

@class RDPlayerViewController;
@interface RDPlayerAlbumVerifyController : NSObject <RDiTunesSearchServiceDelegate, UITableViewDataSource, UITableViewDelegate> {
    RDiTunesSearchService * _service;
    __weak RDPlayerViewController * _contentController;
    NSArray * _albums;
    BOOL _bLookupRequest;
}
- (id)initWithContentController:(RDPlayerViewController *)controller;
- (void)search:(NSDictionary *) query;
- (void)didPressCancel:(id)sender;

- (void)close;

@end

@implementation RDPlayerAlbumVerifyController

- (id)initWithContentController:(RDPlayerViewController *)controller
{
    if (self = [super init]) {
        _contentController = controller;
        _service = [RDiTunesSearchService new];
        _service.delegate = self;
    }
    return self;
}


- (void)search:(NSDictionary *)query
{
    //
    // Snapshot what we look like and blur it
    //
    UIGraphicsBeginImageContextWithOptions(_contentController.view.bounds.size,YES,0.0f);
    [_contentController.view drawViewHierarchyInRect:_contentController.view.bounds afterScreenUpdates:YES];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //
    // Blur it
    //
    GPUImageiOSBlurFilter *blurFilter = [GPUImageiOSBlurFilter new];
    blurFilter.blurRadiusInPixels = 5.0f;
    //
    // Display the loading screen while we retreive data
    //
    CGRect frameRect = _contentController.view.frame;
    
    UIView * loadingView = [[UIView alloc] initWithFrame:frameRect];
    loadingView.tag = LOADING_VIEW_TAG;
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:frameRect];
    imageView.image = [blurFilter imageByFilteringImage:snapshotImage];
    [loadingView addSubview:imageView];
    
    UIView * fadeView = [[UIView alloc] initWithFrame:frameRect];
    fadeView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    [loadingView addSubview:fadeView];
    
    UIActivityIndicatorView * activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activity.frame = CGRectMake((frameRect.size.width / 2) - (activity.bounds.size.width + 35), (frameRect.size.height / 2) - activity.bounds.size.height,
                                activity.bounds.size.width, activity.bounds.size.height);
    [activity startAnimating];
    [loadingView addSubview:activity];
    
    CGRect activityRect = activity.frame;
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(activityRect.origin.x + activityRect.size.width + 10, activityRect.origin.y - 30, 100, 100)];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor whiteColor];
    label.text = @"Please wait";
    [loadingView addSubview:label];
    
    [_contentController.view addSubview:loadingView];
    [_service search:query];
}

- (void)close
{
    UIView * view = [_contentController.view viewWithTag:LOADING_VIEW_TAG];
    [view removeFromSuperview];
    
    view = [_contentController.view viewWithTag:SEARCH_RESULTS_VIEW];
    [view removeFromSuperview];
    
    //
    // Force ARC to release us
    //
    _contentController = nil;
    _service.delegate = nil;
    _service = nil;
}


#pragma mark - RDiTunesSearchServiceDelegate Protocol

- (void)iTunesSearchService:(RDiTunesSearchService *)service didSucceedWith:(NSDictionary *)info
{
    if (!_bLookupRequest) {
        _albums = [info objectForKey:RDiTunesAlbumskey];
        if (!_albums || _albums.count == 0) {
            [self iTunesSearchServiceFailed:service withError:nil];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
            UIImage * background = [cache gradientImageByKey:ResourceCacheViewBackColorKey withRect:_contentController.view.bounds withColors:cache.viewGradientBackColors];

            UIView * view = [[UIView alloc] initWithFrame:_contentController.view.bounds];
            view.tag = SEARCH_RESULTS_VIEW;
            view.backgroundColor = [UIColor colorWithPatternImage:background];
            [_contentController.view addSubview:view];
            
            UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, view.frame.size.width, 20)];
            titleLabel.text = @"Search Results";
            titleLabel.textAlignment = NSTextAlignmentLeft;
            titleLabel.font = [UIFont boldSystemFontOfSize:15];
            titleLabel.textColor = cache.labelTitleTextColor;
            [view addSubview:titleLabel];
            
            UIButton * cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(view.frame.size.width - 90, 10, 100, 20)];
            cancelButton.backgroundColor = [UIColor clearColor];
            [cancelButton setTitleColor:cache.buttonTextColor forState:UIControlStateNormal];
            [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
            [cancelButton addTarget:self action:@selector(didPressCancel:) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:cancelButton];
            

            UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 40, view.frame.size.width, view.frame.size.height - 20) style:UITableViewStylePlain];
            tableView.delegate = self;
            tableView.dataSource = self;
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            tableView.backgroundColor = [UIColor clearColor];
            tableView.contentInset = UIEdgeInsetsMake(0, 0, 15, 0);
            [view addSubview:tableView];
            
            [tableView reloadData];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            RDMusicRepository * repository = [RDMusicRepository sharedInstance];
            NSString * location = [_contentController.playlist.playlistId objectForKey:@"streamLocation"];
            
            RDAlbumModel * album = [repository albumModelByLocation:location];
            album.albumTitle = [info objectForKey:RDiTunesAlbumNameKey];
            album.albumiTunesVerified = YES;
            album.albumiTunesUrl = [info objectForKey:RDiTunesEntityUrlKey];
            album.albumiTunesLookupId = [[info objectForKey:RDiTunesEntityLookupIdKey] stringValue];
            album.albumArtworkUrl = [info objectForKey:RDiTunesArtworkUrlKey];
            album.albumGenre = [info objectForKey:RDiTunesGenreKey];
            album.albumTrackCount = [[info objectForKey:RDiTunesTrackCountKey] shortValue];
            //
            // Generate thumbnail
            //
            NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:album.albumArtworkUrl]];
            UIImage * image = [UIImage imageWithData:data], * thumbNail = [image shrink:CGSizeMake(65, 65)];
            
            album.albumArtworkThumb = UIImagePNGRepresentation(thumbNail);
            album.albumArtwork = UIImagePNGRepresentation([image shrink:CGSizeMake(320.0, 320.0)]);
            //
            // Generate a color scheme based off the image
            //
            LEColorPicker * picker = [LEColorPicker new];
            LEColorScheme * colorScheme = [picker colorSchemeFromImage:thumbNail];
            NSDictionary *colorsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                              colorScheme.backgroundColor,@"BackgroundColor",
                                              colorScheme.primaryTextColor,@"PrimaryTextColor",
                                              colorScheme.secondaryTextColor,@"SecondaryTextColor", nil];
            [album setColorSchemeWith:colorsDictionary];
            //
            // Update track info
            //
            NSArray * tracksInfo = [info objectForKey:RDiTunesTracksKey];
            [album.albumTracks enumerateObjectsUsingBlock:^(id trackObj, BOOL *trackStop) {
                RDTrackModel * track = trackObj;
                for (int i = 0; i < tracksInfo.count; i++) {
                    NSDictionary * tinfo = [tracksInfo objectAtIndex:i];
                    int trackNum = [[tinfo objectForKey:RDiTunesTrackNumberKey] intValue];
                    short discNum = [[tinfo objectForKey:RDiTunesDiscNumberKey] shortValue];
                    if (track.trackNumber == trackNum && track.trackDisc == discNum) {
                        track.trackiTunesLookupId = [[tinfo objectForKey:RDiTunesEntityLookupIdKey] stringValue];
                        track.trackiTunesUrl = [tinfo objectForKey:RDiTunesEntityUrlKey];
                        track.trackName = [tinfo objectForKey:RDiTunesTrackNameKey];
                        break;
                    }
                }
            }];
            
            [repository saveChanges];
            //
            // Create a new playlist
            //
            RDMusicPlaylist * playlist = [RDMusicPlaylist new];
            playlist.playlistId = @{@"streamLocation" : album.albumLocation};
            playlist.name = album.albumTitle;
            playlist.artist = album.albumArtists.artistName;
            playlist.coverArt = album.albumArtwork;
            playlist.thumbNail = album.albumArtworkThumb;
            playlist.iTunesVerified = album.albumiTunesVerified;
            playlist.colorScheme = [album getColorSchemeDictionary];
            [playlist addTrackModels:[album.albumTracks allObjects]];
            //
            // Make the update
            //
            id<RDPlaylistUpdateDelegate> delegate = (id<RDPlaylistUpdateDelegate>) _contentController;
            [delegate playlist:playlist didUpdate:RDPlaylistUpdateTypeUpdated];
            
            [self close];
        });
    }
}

- (void)iTunesSearchServiceFailed:(RDiTunesSearchService *)service withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * message = @"Sorry, we were unable to find this album in iTunes";
        if (error.code == -1001)
            message = @"iTunes Search timed out please try your search again";
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
        [self close];
    });
}

#pragma mark - UITableViewDataSource Protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _albums.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identity = @"Cell";
    
    RDPlayerAlbumVerifyCell * cell =(RDPlayerAlbumVerifyCell *)[tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil)
        cell = [[RDPlayerAlbumVerifyCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identity];
    
    cell.albumInfo = [_albums objectAtIndex:indexPath.row];
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = [[RDMusicResourceCache sharedInstance] cellSelectionBackColor];
    cell.selectedBackgroundView = selectionView;
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIView * view = [_contentController.view viewWithTag:SEARCH_RESULTS_VIEW];
    [view removeFromSuperview];
    
    _bLookupRequest = YES;
    [self performBlock:^{
        
        NSDictionary * albumInfo = [_albums objectAtIndex:indexPath.row];
        [_service lookup:@{ RDiTunesSearchQueryAlbumLookupIDKey : [albumInfo objectForKey:RDiTunesEntityLookupIdKey] }];
        
    } afterDelay:1.0];
    
}

#pragma mark - UI Events

- (void)didPressCancel:(id)sender
{
    [self close];
}

@end


#pragma mark - RDPlaylistScrollView Implemenation

@interface RDPlaylistScrollView : UIControl<UIScrollViewDelegate>

@property (weak, nonatomic) id<RDPlaylistUpdateDelegate> delegate;

- (void)setPlaylists:(NSArray *)playlists;
- (BOOL)scrollToPlaylist:(RDMusicPlaylist *)playlist;
- (void)updateCoverArtFor:(RDMusicPlaylist *)playlist;

@end


@implementation RDPlaylistScrollView
{
    UIScrollView * _scrollView;
    UIPageControl * _pageControlView;
    NSMutableArray * _playlists;
    CGSize _imageScaleSize;
    BOOL _isMix;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageScaleSize = (CGSize) { 320, 320 };
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _scrollView.delegate = self;
        [self addSubview:_scrollView];
        
        _pageControlView = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [self addSubview:_pageControlView];
    }
    
    return self;
}

- (void)setPlaylists:(NSArray *)playlists
{
    _playlists = [NSMutableArray arrayWithArray:playlists];
    [self setNeedsLayout];
}


- (BOOL)scrollToPlaylist:(RDMusicPlaylist *)playlist
{
    //
    // Before we cycle lets see if this is the current one
    //
    RDMusicPlaylist * currentPlaylist = _playlists[_pageControlView.currentPage];
    if ([currentPlaylist isEqualToPlaylist:playlist])
        return YES;
    
    __block BOOL bScrolledToPos = NO;
    [_playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToPlaylist:playlist]) {
            CGRect artworkRect = CGRectMake(idx * self.frame.size.width, 0, _imageScaleSize.width, _imageScaleSize.height);
            [_scrollView scrollRectToVisible:artworkRect animated:YES];
            *stop = bScrolledToPos = YES;
        }
    }];
    
    return bScrolledToPos;
}

- (void)updateCoverArtFor:(RDMusicPlaylist *)playlist
{
    [_playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqualToPlaylist:playlist]) {
            UIImageView * imageView = (UIImageView *)[_scrollView viewWithTag:idx + 1];
            imageView.image = [UIImage imageWithData:playlist.coverArt];
            *stop = YES;
        }
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    //
    // Clear everything first
    //
    [[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    //
    // Now refresh our setup
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    CGRect viewRect = self.frame;
    NSUInteger playlistCount = [_playlists count];
    
    _scrollView.contentOffset = CGPointMake(0, 0);
    _scrollView.contentSize = CGSizeMake(_imageScaleSize.width * playlistCount, _imageScaleSize.height);
    _scrollView.pagingEnabled = playlistCount > 1;
    _scrollView.bounces = NO;
    _pageControlView.hidden = !_scrollView.pagingEnabled;
    _pageControlView.frame = CGRectMake((viewRect.size.width / 2) - ((playlistCount * 10) / 2), 5, playlistCount * 10, 10);
    _pageControlView.numberOfPages = playlistCount;
    _pageControlView.pageIndicatorTintColor = cache.darkBackColor;
    _pageControlView.currentPage = 0;
    //
    // Create our artwork views
    //
    for (int i = 0; i < playlistCount; ++i) {
        UIImageView * artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(i * viewRect.size.width, 0, _imageScaleSize.width, _imageScaleSize.height)];
        artworkView.image = [UIImage imageWithData:[_playlists[i] coverArt]];
        artworkView.tag = i + 1;
        [_scrollView addSubview:artworkView];
    }
}


#pragma mark - UIScrollViewDelegate Protocol

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page != _pageControlView.currentPage) {
        _pageControlView.currentPage = page;
        RDMusicPlaylist * playlist = _playlists[page];
        //
        // Check to see if we have valid colors if it's zero then we
        // never processed this album's artwork because sync for this
        // album was done in the background.
        //
        if (playlist.colorScheme.count == 0 && !playlist.isMix) {
            UIImage * thumbNail = [UIImage imageWithData:playlist.coverArt];
            //
            // Generate a color scheme based off the image
            //
            LEColorPicker * picker = [LEColorPicker new];
            LEColorScheme * colorScheme = [picker colorSchemeFromImage:thumbNail];
            playlist.colorScheme = [NSDictionary dictionaryWithObjectsAndKeys:
                                              colorScheme.backgroundColor,@"BackgroundColor",
                                              colorScheme.primaryTextColor,@"PrimaryTextColor",
                                              colorScheme.secondaryTextColor,@"SecondaryTextColor", nil];
            //
            // Save to repository
            //
            RDMusicRepository * repository = [RDMusicRepository sharedInstance];
            RDAlbumModel * album = [repository albumModelByLocation:[playlist.playlistId objectForKey:@"streamLocation"]];
            [album setColorSchemeWith:playlist.colorScheme];
            [repository saveChanges];
        }
        
        [_delegate playlist:playlist didUpdate:RDPlaylistUpdateTypeNew];
    }
}


@end



#pragma mark - RDPlayerViewCell Implementation

@interface RDPlayerViewCell : RDSwipeableTableViewCell

@property (weak, nonatomic) RDMusicTrack * track;
@property (weak, nonatomic) LEColorScheme * colorScheme;

@end


@implementation RDPlayerViewCell
{
    UILabel * _trackNumber;
    UILabel * _trackName;
    UIImageView * _nowPlayingImage;
    BOOL _touched;
}
@synthesize track = _track;
@synthesize colorScheme = _colorScheme;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        _trackNumber = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 30, 20)];
        _trackNumber.font = [UIFont fontWithName:@"Bebas" size:17.0];
        _trackNumber.textColor = [UIColor colorWithRed:115.0/255.0 green:51.0/255.0 blue:21.0/255.0 alpha:1];
        _trackNumber.textAlignment = NSTextAlignmentLeft;
        _trackNumber.lineBreakMode = NSLineBreakByTruncatingTail;
        _trackNumber.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_trackNumber];
        
        _trackName = [[UILabel alloc] initWithFrame:CGRectMake(40, 17, 250, 20)];
        _trackName.font = [UIFont fontWithName:@"Ubuntu Condensed" size:17.0];
        _trackName.textColor = [UIColor colorWithRed:115.0/255.0 green:51.0/255.0 blue:21.0/255.0 alpha:1];
        _trackName.textAlignment = NSTextAlignmentLeft;
        _trackName.lineBreakMode = NSLineBreakByTruncatingTail;
        _trackName.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_trackName];
        
        _nowPlayingImage = [[UIImageView alloc] initWithFrame:CGRectMake(11, 19, 16, 16)];
        _nowPlayingImage.hidden = NO;
        [self.contentView addSubview:_nowPlayingImage];
    
    }
    return self;
}

- (void)setTrack:(RDMusicTrack *)track
{
    _track = track;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = self.colorScheme.backgroundColor;
    
    _nowPlayingImage.hidden = YES;
    _trackNumber.hidden = NO;
    _trackNumber.textColor = self.colorScheme.primaryTextColor;
    _trackNumber.text = [NSString stringWithFormat:@"%.2d", _track.number];
    _trackName.font = [UIFont fontWithName:@"Ubuntu Condensed" size:17.0];
    _trackName.textColor = self.colorScheme.secondaryTextColor;
    _trackName.text = _track.name;
    
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (_track.isCurrentTrack && (player.isPlaying || player.isPaused))
    {
        _trackNumber.hidden = YES;
        _nowPlayingImage.hidden = NO;
        _nowPlayingImage.image = [[UIImage imageNamed:@"now-playing"] tintColor:self.colorScheme.primaryTextColor];
        self.backgroundColor = [self.colorScheme.backgroundColor lighterColor];
    }
}

@end



#pragma mark - RDPlayerViewController Implementation

@interface RDPlayerViewController () <RDPlaylistUpdateDelegate,RDSwipeableTableViewCellDelegate,RDPlayerTutorialDelegate,RDiTunesSearchServiceDelegate,BitlyURLShortenerDelegate>

@property (readonly, nonatomic) UIImage * playerIconPlay;
@property (readonly, nonatomic) UIImage * playerIconPause;
@property (readonly, nonatomic) UIImage * playerIconSync;
@property (readonly, nonatomic) UIImage * playerIconStop;
@property (readonly, nonatomic) RDiTunesSearchService * iTunesService;

- (void)didReceiveTrackLoadingNotification:(NSNotification *)notification;
- (void)didReceiveTrackFailedToLoadNotification:(NSNotification *)notification;
- (void)didReceiveTrackStartedNotification:(NSNotification *)notification;
- (void)didReceiveTrackUpdateNotification:(NSNotification *)notification;
- (void)didReceiveTrackInterruptedNotification:(NSNotification *)notification;
- (void)didReceiveTrackResumeNotification:(NSNotification *)notification;
- (void)didReceiveTrackBufferingNotification:(NSNotification *)notification;
- (void)didReceiveTrackPausedNotification:(NSNotification *)notification;
- (void)didReceiveConnectionInterruptionNotification:(NSNotification *)notification;
- (void)didReceiveAppInForegroundNotification:(NSNotification *)notification;
- (void)didReceiveEndOfPlaylistNotification:(NSNotification *)notification;
- (void)didReceiveWillNotPlayOnCellularNotification:(NSNotification *)notification;

- (void)didTapPlayerPlayPause;
- (void)didDoubleTapPlayer;
- (void)didSwipePlayerNextPrev:(UIGestureRecognizer *)gesture;
- (void)didLongSwipePlayer:(UIGestureRecognizer *)gesture;
- (void)didPressFavorite:(UIButton *)sender;
- (void)didPressRemoveFavorite:(UIButton *)sender;
- (void)didPressRepeat:(UIButton *)sender;
- (void)didPressShare:(UIButton *)sender;
- (void)didPressRevertTrack:(UIButton *)sender;

- (void)updateUI:(RDMusicPlaylist *)playlist;
- (void)playTrack:(RDMusicTrack *)track;
- (void)playNextTrack;
- (void)playPreviousTrack;
- (void)syncTrackLength:(Float64)duration;
- (void)animate;
- (void)stopAnimating;
- (void)displayPlayer;
- (void)reset;
- (NSArray *)getRelatedPlaylists;

@end

@implementation RDPlayerViewController
{
    BOOL _bConnectionWasInterrupted;
    BOOL _bContinueAnimating;
    LEColorScheme * _artworkColorScheme;
    Float32 _infoBoxYOffset;
    CGPoint _swipePoint;
    id<UIViewControllerAnimatedTransitioning> _animationController;
    NSUInteger _socialNetworkId;
    NSIndexPath * _sharedTrackIndex;
    BitlyURLShortener * _bitlyShortener;
    RDiTunesSearchService * _iTunesService;
    RDPlayerAlbumVerifyController * _verifyController;
}


@synthesize playerIconPause = _playerIconPause;
@synthesize playerIconPlay = _playerIconPlay;
@synthesize playerIconStop = _playerIconStop;
@synthesize playerIconSync = _playerIconSync;

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    // Setup bitly
    //
    _bitlyShortener = [BitlyURLShortener new];
    _bitlyShortener.delegate = self;
    //
    // Setup itunes
    //
    _iTunesService = [RDiTunesSearchService new];
    _iTunesService.delegate = self;
    //
    // Subscribe to player notifications
    //
    [self registerForNotificationWith:@selector(didReceiveAppInForegroundNotification:) forName:UIApplicationDidBecomeActiveNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackLoadingNotification:) forName:RDMusicPlayerTrackLoadingNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackFailedToLoadNotification:) forName:RDMusicPlayerTrackFailedToLoadNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackStartedNotification:) forName:RDMusicPlayerTrackStartedNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackUpdateNotification:) forName:RDMusicPlayerTrackUpdateNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackInterruptedNotification:) forName:RDMusicPlayerTrackInterruptedNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackPausedNotification:) forName:RDMusicPlayerTrackPausedNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackResumeNotification:) forName:RDMusicPlayerTrackResumeNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackBufferingNotification:) forName:RDMusicPlayerTrackBufferingNotification];
    [self registerForNotificationWith:@selector(didReceiveConnectionInterruptionNotification:) forName:RDMusicPlayerConnectionInterruptionNotification];
    [self registerForNotificationWith:@selector(didReceiveEndOfPlaylistNotification:) forName:RDMusicPlayerEndOfPlaylistNotification];
    [self registerForNotificationWith:@selector(didReceiveWillNotPlayOnCellularNotification:) forName:RDMusicPlayerWillNotPlayOnCellularNotification];
    //
    // Initialize our cache
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    //
    // Setup our color scheme
    //
    if (self.playlist.isMix) {
        UIImage * image= [UIImage imageWithData:self.playlist.coverArt];
        LEColorPicker * picker = [LEColorPicker new];
        _artworkColorScheme = [picker colorSchemeFromImage:image];
    } else {
        _artworkColorScheme = [LEColorScheme new];
        _artworkColorScheme.backgroundColor = [_playlist.colorScheme objectForKey:@"BackgroundColor"];
        _artworkColorScheme.primaryTextColor = [_playlist.colorScheme objectForKey:@"PrimaryTextColor"];
        _artworkColorScheme.secondaryTextColor = [_playlist.colorScheme objectForKey:@"SecondaryTextColor"];
    }
    
    self.view.backgroundColor = _artworkColorScheme.backgroundColor;
    CGRect viewFrame = self.view.frame;
    //
    // Setup hide button
    //
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    self.closeButton.tintColor = [UIColor whiteColor];
    self.closeButton.backgroundColor = [UIColor blackColor];
    self.closeButton.layer.opacity = 0.75;
    self.closeButton.layer.cornerRadius = 5.0f;
    self.closeButton.layer.borderColor = [UIColor lightTextColor].CGColor;
    self.closeButton.layer.borderWidth = 0.5f;
    //
    // Add the artwork view to the container
    //
    RDPlaylistScrollView * scrollView = [[RDPlaylistScrollView alloc] initWithFrame:CGRectMake(0, 0, viewFrame.size.width, viewFrame.size.height)];
    scrollView.delegate = self;
    scrollView.backgroundColor = _artworkColorScheme.backgroundColor;
    scrollView.tag = ALBUMCOVER_SCROLLVIEW_TAG;
    [scrollView setPlaylists:[self getRelatedPlaylists]];
    [self.view insertSubview:scrollView belowSubview:self.closeButton];
    //
    // Setup info box
    //
    self.infoView.layer.opacity = 0.8;
    self.infoView.layer.cornerRadius = 6.0;
    self.infoView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.infoView.layer.shadowOpacity = 0.5f;
    self.infoView.layer.shadowRadius = 5.0f;
    self.infoView.layer.shadowOffset = CGSizeMake(3, 3);
    self.infoView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.infoView.layer.bounds].CGPath;
    self.infoView.backgroundColor = [UIColor blackColor];
    _infoBoxYOffset = self.infoView.frame.origin.y;
    //
    // Setup info
    //
    self.infoAlbumTitle.textColor = cache.labelTitleTextColor;
    self.infoAlbumTitle.text = _playlist.name;
    self.infoArtist.text = _playlist.artist;
    self.infoArtist.textColor = [UIColor whiteColor];
    self.infoTracks.textColor = [UIColor whiteColor];;
    
    if (_playlist.discs > 1) {
        self.infoTracks.text = [NSString stringWithFormat:@"%i Discs %i Tracks", _playlist.discs, _playlist.tracksTotal];
    } else {
        self.infoTracks.text = [NSString stringWithFormat:@"%i Tracks", _playlist.tracksTotal];
    }
    //
    // Setup verification
    //
    UIColor * tintColor = _playlist.iTunesVerified ? [[UIColor greenColor] lighterColor]: [UIColor lightGrayColor];
    NSString * title = _playlist.iTunesVerified ? @"iTunes Verified" : @"Update Album Info";
    [self.verifyButton setImage:[[UIImage imageNamed:@"verify"] tintColor:tintColor] forState:UIControlStateNormal];
    [self.verifyButton setTitle:title forState:UIControlStateNormal];
    self.verifyButton.hidden = _playlist.isMix;
    //
    // load up the track list
    //
    self.trackListView.backgroundColor = _playlist.tracksTotal > 2 ? [UIColor clearColor] : _artworkColorScheme.backgroundColor;
    self.trackListView.rowHeight = 50.0f;
    [self.trackListView reloadData];
    [self.view insertSubview:self.trackListView aboveSubview:scrollView];
    //
    // Setup the player
    //
    CGRect playerRect = self.playerView.frame;
    self.playerView.backgroundColor = [UIColor clearColor];
    self.playerView.hidden = YES;
    self.playerView.frame = CGRectMake(0, self.view.frame.size.height + 1, playerRect.size.width, playerRect.size.height);
    [self.view insertSubview:self.playerView aboveSubview:self.trackListView];
    
    self.playerAlbumName.text = @"";
    self.playerTrackName.text = @"";
    self.playerTrackLength.text = @"";
    self.playerStatus.text = @"";
    //
    // Setup the artwork
    //
    self.playerArtworkView.clipsToBounds = YES;
    self.playerArtworkView.layer.cornerRadius = 5.0f;
    //
    // Add frost layer
    //
    RDFrostView *frostView = [[RDFrostView alloc] initWithFrame:self.playerView.bounds];
    frostView.blurImage = [UIImage imageWithData:self.playlist.coverArt];
    frostView.tag = PLAYER_FROSTVIEW_TAG;
    [self.playerView insertSubview:frostView atIndex:0];
    //
    // Setup the floating duration view
    //
    UIView * scrubbleView = [[UIView alloc] initWithFrame:CGRectMake((viewFrame.size.width / 2) - 25, self.playerView.frame.origin.y - 25, 50, 25)];
    scrubbleView.hidden = YES;
    scrubbleView.tag = SCRUBBER_VIEW_TAG;
    scrubbleView.clipsToBounds = YES;
    scrubbleView.backgroundColor = [UIColor blackColor];
    scrubbleView.layer.cornerRadius = 7.0f;
    scrubbleView.layer.shadowColor = [UIColor blackColor].CGColor;
    scrubbleView.layer.shadowOpacity = 0.80f;
    scrubbleView.layer.shadowRadius = 5.0f;
    scrubbleView.layer.shadowOffset = CGSizeMake(5, 5);
    scrubbleView.layer.shadowPath = [UIBezierPath bezierPathWithRect:scrubbleView.layer.bounds].CGPath;
    [self.view insertSubview:scrubbleView aboveSubview:self.playerView];
    
    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 50, 15)];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    [scrubbleView addSubview:timeLabel];
    //
    // Setup gestures gesture
    //
    UIView * gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, playerRect.size.width, playerRect.size.height)];
    [self.playerView insertSubview:gestureView atIndex:self.playerView.subviews.count - 1];
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPlayerPlayPause)];
    tapGesture.delegate = self;
    [gestureView addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapPlayer)];
    doubleTapGesture.delegate = self;
    doubleTapGesture.numberOfTouchesRequired = 2;
    doubleTapGesture.numberOfTapsRequired = 2;
    [gestureView addGestureRecognizer:doubleTapGesture];
    
    UISwipeGestureRecognizer * swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipePlayerNextPrev:)];
    swipeLeftGesture.delegate =self;
    swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [gestureView addGestureRecognizer:swipeLeftGesture];
    
    UISwipeGestureRecognizer * swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipePlayerNextPrev:)];
    swipeRightGesture.delegate =self;
    swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [gestureView addGestureRecognizer:swipeRightGesture];
    
    UILongPressGestureRecognizer * longSwipeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongSwipePlayer:)];
    longSwipeGesture.delegate = self;
    [gestureView addGestureRecognizer:longSwipeGesture];
    //
    // Turn off continuous play while the player is first responder
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    player.playerIsVisible = YES;
    //
    // If there is another playlist loaded then display the player at the bottom
    // as long as the current track state is loading, playing, or paused
    //
    if (player.playlist && (player.isPlaying || player.isPaused || player.isLoading)) {
        RDMusicTrack * currentTrack = [player currentTrack];
    
        self.playerView.hidden = NO;
        self.playerView.frame = CGRectMake(0, viewFrame.size.height - playerRect.size.height, playerRect.size.width, playerRect.size.height);;
        self.playerTrackName.text = currentTrack.name;
        self.playerArtworkView.image = [UIImage imageWithData:player.playlist.thumbNail];
        self.playerAlbumName.text = player.playlist.name;
        self.trackListView.contentInset = UIEdgeInsetsMake(0, 0, playerRect.size.height, 0);
        //
        // See if the track is on repeat
        //
        if (currentTrack.repeat) {
            self.playerRepeatView.hidden = NO;
            CGRect statusRect = self.playerStatus.frame;
            self.playerStatus.frame = CGRectMake(self.playerRepeatView.frame.origin.x + self.playerRepeatView.frame.size.width,
                                             statusRect.origin.y, statusRect.size.width, statusRect.size.height);
        }
        
        if (player.isPlaying) {
            self.playerArtworkView.image = [UIImage imageWithData:currentTrack.thumbNail];
            self.playerStatusView.image = self.playerIconPlay;
            self.playerStatus.text = @"Now Playing";
            if ([_playlist isEqualToPlaylist:player.playlist]) {
                //
                // Scroll to the track thats playing
                //
                NSIndexPath * index = [player.playlist indexPathFromTrack:player.currentTrack];
                [_trackListView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index.row inSection:index.section - 1]
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
            }
        } else if (player.isPaused) {
            self.playerArtworkView.image = [UIImage imageWithData:currentTrack.thumbNail];
            self.playerStatusView.image = self.playerIconPause;
            self.playerStatus.text = @"Paused";
        } else if (player.isLoading) {
            [self displayPlayer];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //
    // Check to see if the user has seen the tutorial yet
    //
    RDAppPreference * appPref = [RDAppPreference new];
    if (!appPref.shownPlayerTutorial) {
        [self performBlock:^{
            _animationController = [[DETAnimatedTransitionController alloc] init];
            //
            // Present the tutorial
            //
            RDPlayerTutorialViewController * tutorialController = (RDPlayerTutorialViewController *)[[self storyboard] instantiateViewControllerWithIdentifier:@"PlayerTutorial"];
            tutorialController.delegate = self;
            tutorialController.transitioningDelegate = self;
            [self presentViewController:tutorialController animated:YES completion:nil];
            
        } afterDelay:1.0];
    }
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder) {
        _iTunesService.delegate = nil;
        _iTunesService = nil;
        _bitlyShortener.delegate = nil;
        _bitlyShortener = nil;
        _playerIconPause = nil;
        _playerIconPlay = nil;
        _playerIconStop = nil;
        _playerIconSync = nil;
        _playlist = nil;
        _artworkColorScheme = nil;
        self.view = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
}


#pragma mark - Instance Properties

- (UIImage *)playerIconPlay
{
    if (!_playerIconPlay)
        _playerIconPlay = [UIImage imageNamed:@"play"];
    
    return _playerIconPlay;
}

- (UIImage *)playerIconPause
{
    if (!_playerIconPause)
        _playerIconPause = [UIImage imageNamed:@"pause"];
    
    return _playerIconPause;
}

- (UIImage *)playerIconSync
{
    if (!_playerIconSync)
        _playerIconSync = [UIImage imageNamed:@"sync"];
    
    return _playerIconSync;
}

- (UIImage *)playerIconStop
{
    if (!_playerIconStop)
        _playerIconStop = [UIImage imageNamed:@"stop"];
    
    return _playerIconStop;
}


#pragma mark - Instance Methods

- (void)playTrack:(RDMusicTrack *)track
{
    //
    // Play the track we are interested in
    //
    [[RDMusicPlayer sharedInstance] playTrack:track];
}

- (void)playNextTrack
{
    [[RDMusicPlayer sharedInstance] playNextTrack];
}

- (void)playPreviousTrack
{
    [[RDMusicPlayer sharedInstance] playPrevTrack];
}

- (void)displayPlayer
{
    RDMusicTrack * track = [[RDMusicPlayer sharedInstance] queuedTrack];
    if (track) {
#ifdef DEBUG
        NSLog(@"RDPlayerViewController - Loading track: %@", track.name);
#endif
        if (_playerView.hidden) {
            _playerView.hidden = NO;
            _playerView.frame = CGRectMake(0, self.view.frame.size.height + 1, _playerView.frame.size.width, _playerView.frame.size.height);
            
            CGRect playerRect = _playerView.frame;
            [UIView animateWithDuration:0.5f animations:^{
                _playerView.frame = CGRectMake(0, self.view.frame.size.height - playerRect.size.height, playerRect.size.width, playerRect.size.height);
            }];
        }
    
        if (_playlist.tracksTotal > 5)
            _trackListView.contentInset = UIEdgeInsetsMake(0, 0, _playerView.bounds.size.height, 0);
        
        _playerArtworkView.image = [UIImage imageWithData:track.thumbNail];
        _playerAlbumName.text = track.albumName;
        _playerTrackName.text = track.name;
        _playerTrackLength.hidden = YES;
        _playerRepeatView.hidden = YES;
        
        CGRect statusRect = _playerStatus.frame;
        _playerStatus.frame = CGRectMake(_playerRepeatView.frame.origin.x + 5, statusRect.origin.y, statusRect.size.width, statusRect.size.height);
        _playerStatus.text = [NSString stringWithFormat:@"Loading Track %.2d", track.number];
        //
        // Animate our progress
        //
        [self stopAnimating];
        [self animate];
        //
        // Make sure we are the same playlist before messing with anything
        //
        if ([_playlist isEqualToPlaylist:track.playlist]) {
            //
            // Loop through and reset the state in the track list
            //
            NSArray * cells = [_trackListView indexPathsForVisibleRows];
            [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSIndexPath * path = (NSIndexPath *) obj;
                RDPlayerViewCell * cell = (RDPlayerViewCell *)[self.trackListView cellForRowAtIndexPath:path];
                [cell setNeedsLayout];
            }];
        }
    }
    
}

- (void)syncTrackLength:(Float64)duration
{
    NSUInteger dTotalSeconds = duration;
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
    
    _playerTrackLength.hidden = NO;
    _playerTrackLength.text = [NSString stringWithFormat:@"-%02i:%02i", dMinutes, dSeconds];
}

- (void)animate
{
    if (!_bContinueAnimating) {
        //
        // Set up our load media animation
        //
        _playerStatusView.image = self.playerIconSync;
        _bContinueAnimating = YES;
        //
        // Start animation
        //
        CATransform3D rotationTransform = CATransform3DMakeRotation(2.0f * M_PI, 0, 0, 1.0);
        CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.toValue = [NSValue valueWithCATransform3D:rotationTransform];
        animation.duration = 1.5f;
        animation.cumulative = YES;
        animation.repeatCount = 100.0f;
        [_playerStatusView.layer addAnimation:animation forKey:nil];
    }
}

- (void)stopAnimating
{
    if (_bContinueAnimating) {
        _bContinueAnimating = NO;
        //
        // Reset everything
        //
        [_playerStatusView.layer removeAllAnimations];
    }
}

- (void)reset
{
    [self stopAnimating];
    
    if (!_playerView.hidden) {
        CGRect playerRect = _playerView.frame;
        _playerView.frame = CGRectMake(0, self.view.frame.size.height + 1, playerRect.size.width, playerRect.size.height);
        _playerView.hidden = YES;
        _trackListView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    _playerAlbumName.Text = @"";
    _playerTrackName.text = @"";
    _playerTrackLength.text = @"--:--";
    _playerRepeatView.hidden = YES;
    
    CGRect statusRect = _playerStatus.frame;
    _playerStatus.frame = CGRectMake(_playerRepeatView.frame.origin.x, statusRect.origin.y, statusRect.size.width, statusRect.size.height);
    //
    // Unhighlight the track that is being played in the playlist
    //
    NSArray * cells = [_trackListView indexPathsForVisibleRows];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath * path = (NSIndexPath *) obj;
        RDPlayerViewCell * cell = (RDPlayerViewCell *)[_trackListView cellForRowAtIndexPath:path];
        [cell setNeedsLayout];
    }];
}

- (void)updateUI:(RDMusicPlaylist *)playlist
{
    //
    // Reload the current view with the currently playing playlist
    //
    _infoAlbumTitle.text = playlist.name;
    _infoArtist.text = playlist.artist;
    
    if (_playlist.discs > 1) {
        _infoTracks.text = [NSString stringWithFormat:@"%i Discs %i Tracks", playlist.discs, playlist.tracksTotal];
    } else {
        _infoTracks.text = [NSString stringWithFormat:@"%i Tracks", playlist.tracksTotal];
    }
    
    UIColor * tintColor = playlist.iTunesVerified ? [[UIColor greenColor] lighterColor]: [UIColor lightGrayColor];
    NSString * title = playlist.iTunesVerified ? @"iTunes Verified" : @"Update Album Info";
    [self.verifyButton setImage:[[UIImage imageNamed:@"verify"] tintColor:tintColor] forState:UIControlStateNormal];
    [self.verifyButton setTitle:title forState:UIControlStateNormal];
    
    _artworkColorScheme = [LEColorScheme new];
    _artworkColorScheme.backgroundColor = [playlist.colorScheme objectForKey:@"BackgroundColor"];
    _artworkColorScheme.primaryTextColor = [playlist.colorScheme objectForKey:@"PrimaryTextColor"];
    _artworkColorScheme.secondaryTextColor = [playlist.colorScheme objectForKey:@"SecondaryTextColor"];
    self.view.backgroundColor = _artworkColorScheme.backgroundColor;
    
    RDFrostView * frostView = (RDFrostView *) [_playerView viewWithTag:PLAYER_FROSTVIEW_TAG];
    frostView.blurImage =[UIImage imageWithData:playlist.coverArt];
    
    RDPlaylistScrollView * scrollView = (RDPlaylistScrollView *)[self.view viewWithTag:ALBUMCOVER_SCROLLVIEW_TAG];
    scrollView.backgroundColor = _artworkColorScheme.backgroundColor;
    [scrollView scrollToPlaylist:playlist];
    //
    // Reload the list
    //
    _trackListView.backgroundColor = playlist.tracksTotal > 2 ? [UIColor clearColor] : _artworkColorScheme.backgroundColor;
    [_trackListView reloadData];
    //
    // Make sure we are the same playlist before messing with anything
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (![playlist isEqualToPlaylist:player.playlist]) {
        //
        // Scroll to the first track
        //
        [_trackListView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
        if (player.currentTrack && (player.isPlaying || player.isPaused)) {
            //
            // Scroll to the track thats playing
            //
            NSIndexPath * index = [player.playlist indexPathFromTrack:player.currentTrack];
            [_trackListView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index.row inSection:index.section - 1]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:YES];
        } else if (player.hasStopped) {
            //
            // Hide the player
            //
            [self reset];
        }
    }
}

- (void)shareWithUrl:(NSURL *)url
{
    RDMusicTrack * track = [_playlist trackAtIndex:_sharedTrackIndex];
    NSString * messageText = [NSString stringWithFormat:@"Checkout this track \"%.2d - %@\" on album %@ #rhythmdenapp", track.number, track.name, track.albumName];
    
    if (track.isCurrentTrack)
        messageText = [NSString stringWithFormat:@"Rock'in to track \"%.2d - %@\" on album %@ #rhythmdenapp", track.number, track.name, track.albumName];

    NSString * socialNetwork = _socialNetworkId == FACEBOOK_BUTTON_ID ? SLServiceTypeFacebook : SLServiceTypeTwitter;
    SLComposeViewController * viewController = [SLComposeViewController composeViewControllerForServiceType:socialNetwork];
    [viewController addURL:url];
    [viewController setInitialText:messageText];
    [viewController setCompletionHandler:^(SLComposeViewControllerResult result) {
        UIView * loadingView = [self.view viewWithTag:LOADING_VIEW_TAG];
        [loadingView removeFromSuperview];
    }];
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (NSArray *)getRelatedPlaylists
{
    NSMutableArray * playlists = [NSMutableArray arrayWithObject:_playlist];
    
    if (!_playlist.isMix) {
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        NSArray * artists = [repository artistModelsByName:_playlist.artist];
        if (artists.count > 0) {
            RDArtistModel * artist = [artists objectAtIndex:0];
            [artist.artistAlbums enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                RDAlbumModel * album = (RDAlbumModel *)obj;
                if (![album.albumTitle isEqualToString:_playlist.name]) {
                    RDMusicPlaylist * playlist = [RDMusicPlaylist new];
                    playlist.playlistId = @{@"streamLocation" : album.albumLocation};
                    playlist.name = album.albumTitle;
                    playlist.artist = album.albumArtists.artistName;
                    playlist.coverArt = album.albumArtwork;
                    playlist.thumbNail = album.albumArtworkThumb;
                    playlist.colorScheme = [album getColorSchemeDictionary];
                    playlist.iTunesVerified = album.albumiTunesVerified;
                    [playlist addTrackModels:[album.albumTracks allObjects]];
                    [playlists addObject:playlist];
                }
            }];
        }
    }
    
    return playlists;
}

#pragma mark - MusicPlayer Notifications

- (void)didReceiveAppInForegroundNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - App returned to foreground");
#endif
    //
    // Now lets figure out what to do next
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (player.isPaused) {
        //
        // Stop animation if there is any
        //
        [self stopAnimating];
        //
        // Set the name in the track
        //
        _playerTrackName.text = player.currentTrack.name;
        _playerStatus.text = @"Paused";
        //
        // Reset the pause/play button
        //
        _playerStatusView.image = self.playerIconPause;
        //
        // Update the thumbnail
        //
        _playerArtworkView.image = [UIImage imageWithData:player.currentTrack.thumbNail];
    } else if (player.isPlaying) {
        //
        // Stop animation if there is any
        //
        [self stopAnimating];
        //
        // Set the name in the track
        //
        _playerTrackName.text = player.currentTrack.name;
        _playerStatus.text = @"Now Playing";
        //
        // Change play button state
        //
        _playerStatusView.image = self.playerIconPlay;
        //
        // Update the thumbnail
        //
        _playerArtworkView.image = [UIImage imageWithData:player.currentTrack.thumbNail];
    } else if (player.isLoading) {
        //
        // Continue loading the track
        //
        [self displayPlayer];
    } else {
        //
        // See if the player is atleast visible
        //
        if (_playerView.hidden)
            return;
        
        //
        // Reset the player only if the current player matches
        // our playlist because we don't want to hide the player
        // if we are browsing another playlist or album
        //
        if ([_playlist isEqualToPlaylist:player.playlist]) {
            //
            // Assume that track stopped so reset everything
            //
            [self reset];
            //
            // Scroll to the first track
            //
            [_trackListView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:YES];
        } else {
            //
            // Well we are another playlist/album so lets just set
            // the player to stopped mode
            //
            _playerStatusView.image = self.playerIconStop;
            _playerStatus.text = @"Stopped";
            
        }
        return;
    }
    //
    // Make the track in the play list visible
    //
    if ([_playlist isEqualToPlaylist:player.playlist]) {
        //
        // Reset the cells that are visibile
        //
        NSArray * cells = [_trackListView indexPathsForVisibleRows];
        [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath * path = (NSIndexPath *) obj;
            RDPlayerViewCell * cell = (RDPlayerViewCell *)[_trackListView cellForRowAtIndexPath:path];
            [cell setNeedsLayout];
        }];
        
        if (player.isPlaying || player.isPaused) {
            //
            // Scroll to the visible one
            //
            NSUInteger maxRow = [(NSIndexPath *)cells.lastObject row] - 2;
            NSIndexPath * index = [player.playlist indexPathFromTrack:player.currentTrack];
            NSIndexPath * correctIndex = [NSIndexPath indexPathForRow:index.row inSection:index.section - 1];
            if (![_trackListView.indexPathsForVisibleRows containsObject:correctIndex] || correctIndex.row > maxRow)
                [_trackListView scrollToRowAtIndexPath:correctIndex
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
        }
    }
}


- (void)didReceiveWillNotPlayOnCellularNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - didReceiveWillNotPlayOnCellularNotification called");
#endif
}


- (void)didReceiveTrackLoadingNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - didReceiveTrackLoadingNotification called");
#endif
    [self displayPlayer];
}


- (void)didReceiveTrackFailedToLoadNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Failed to load asset");
#endif
    [self reset];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                     message:@"An error occured trying to load the track please try again"
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}


- (void)didReceiveTrackStartedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Track started");
#endif
    //
    // Before we try to do anything lets make sure we have the focus
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (!player.inBackgroundMode) {
        RDMusicTrack * track = (RDMusicTrack *)[notification object];
        //
        // Set track name & length
        //
        Float64 duration = CMTimeGetSeconds(track.duration);
        if (duration != NAN) duration = 0.0f;
        [self syncTrackLength:duration];
        //
        // Stop animation
        //
        [self stopAnimating];
        
        _playerTrackLength.hidden = NO;
        _playerStatusView.image = self.playerIconPlay;
        _playerStatusView.layer.opacity = 0;
        _playerArtworkView.image = [UIImage imageWithData:track.thumbNail];
        //
        // See if the track is on repeat
        //
        if (track.repeat) {
            _playerRepeatView.hidden = NO;
            CGRect statusRect = _playerStatus.frame;
            _playerStatus.frame = (CGRect){ _playerRepeatView.frame.origin.x + _playerRepeatView.frame.size.width + 3, statusRect.origin.y, statusRect.size };
        }
        
        [UIView animateWithDuration:1.5
                         animations:^{
                             _playerStatusView.layer.opacity = 1.0;
                             _playerTrackLength.layer.opacity =1.0;
                         } completion:^(BOOL finished) {
                         }];
        //
        // Set the name in the track
        //
        _playerTrackName.text = track.name;
        //
        // Change play button state
        //
        _playerStatusView.image = self.playerIconPlay;
        _playerStatus.text = @"Now Playing";
        //
        // Reset the playlist if we are the same play list as the player
        //
        if ([_playlist isEqualToPlaylist:player.playlist]) {
            //
            // Highlight the track that is being played in the playlist
            //
            NSArray * cells = [_trackListView indexPathsForVisibleRows];
            [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSIndexPath * path = (NSIndexPath *) obj;
                RDPlayerViewCell * cell = (RDPlayerViewCell *)[_trackListView cellForRowAtIndexPath:path];
                [cell setNeedsLayout];
            }];
            //
            // Scroll to the visible one
            //
            NSUInteger maxRow = [(NSIndexPath *)cells.lastObject row] - 2;
            NSIndexPath * index = [player.playlist indexPathFromTrack:player.currentTrack];
            NSIndexPath * correctIndex = [NSIndexPath indexPathForRow:index.row inSection:index.section - 1];
            if (![_trackListView.indexPathsForVisibleRows containsObject:correctIndex] || correctIndex.row > maxRow)
                [_trackListView scrollToRowAtIndexPath:correctIndex
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:YES];
        }
    }
}


- (void)didReceiveTrackUpdateNotification:(NSNotification *)notification
{
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    Float64 currentTrackDuration = CMTimeGetSeconds(player.currentTrack.duration);
    Float64 duration = [notification.object floatValue];
    
    [self syncTrackLength:(currentTrackDuration - duration)];
#ifdef DEBUG
    //NSLog(@"RDPlayerViewControler - Track getting an update with time: %f and %f", duration, player.position);
#endif

}

- (void)didReceiveTrackInterruptedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Track interrupted");
#endif
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    //
    // Update the status
    //
    [self stopAnimating];
    _playerStatusView.image = player.isPaused ? self.playerIconPause : self.playerIconStop;
    _playerStatus.text = @"Track Interrupted";
    //
    // We clear the track list
    //
    if ([_playlist isEqualToPlaylist:player.playlist] ) {
        NSArray * cells = [_trackListView indexPathsForVisibleRows];
        [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath * path = (NSIndexPath *) obj;
            RDPlayerViewCell * cell = (RDPlayerViewCell *)[_trackListView cellForRowAtIndexPath:path];
            [cell setNeedsLayout];
        }];
    }
}


-(void)didReceiveTrackPausedNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Track paused");
#endif
    //
    // Update the status
    //
    [self stopAnimating];
    _playerStatusView.image = self.playerIconPause;
    _playerStatus.text = @"Paused";

}

- (void)didReceiveTrackResumeNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Track resumed");
#endif
    //
    // Update the status
    //
    [self stopAnimating];
    _playerStatusView.image = self.playerIconPlay;
    _playerStatus.text = @"Now Playing";
    _playerTrackLength.hidden = NO;
}


- (void)didReceiveTrackBufferingNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Track Buffering");
#endif
    //
    // Update the status
    //
    [self animate];
    _playerStatus.text = @"Buffering...";
}


- (void)didReceiveConnectionInterruptionNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewControler - Connection Interrupted");
#endif
    //
    // Change play button state
    //
    _playerStatusView.image = self.playerIconStop;
    _playerStatus.text = @"Internet Connection Interrupted";
}


- (void)didReceiveEndOfPlaylistNotification:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewController - Reached end of playlist");
#endif
    //
    // We receive this message in two scenarios:
    //
    // #1 - The player just finished playing the last track (the state is stopped)
    // #2 - The user swiped the visual player to go to the next track while the track is
    //      is still playing.
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (player.hasStopped) {
        //
        // Reset the track list
        //
        if ([_playlist isEqualToPlaylist:player.playlist]) {
            player.playlist = nil;
            //
            // Hide the player
            //
            [self reset];
            //
            // Clear the track list scroll to first track
            //
            NSArray * cells = [_trackListView indexPathsForVisibleRows];
            [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSIndexPath * path = (NSIndexPath *) obj;
                RDPlayerViewCell * cell = (RDPlayerViewCell *)[_trackListView cellForRowAtIndexPath:path];
                [cell setNeedsLayout];
            }];
            
            [_trackListView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:YES];
        } else {
            //
            // Clear current track info
            //
            _playerTrackName.text = @"";
            _playerTrackLength.hidden = YES;
            _playerStatusView.image = self.playerIconStop;
            _playerStatus.text = player.playlist.isMix ?  @"End of Playlist" : @"End of Album";
        }
    }
}

#pragma mark - BitlyURLShortenerDelegate Protocol

-(void)bitlyURLShortenerDidShortenURL:(BitlyURLShortener *)shortener longURL:(NSURL *)longURL shortURLString:(NSString *)shortURLString
{
    [self shareWithUrl:[NSURL URLWithString:shortURLString]];
}

- (void)bitlyURLShortener:(BitlyURLShortener *)shortener
        didFailForLongURL:(NSURL *)longURL
               statusCode:(NSInteger)statusCode
               statusText:(NSString *)statusText
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewController(bitlyURLShortenerDidShortenURL) - Failed with status: %@", statusText);
#endif
    UIView * loadingView = [self.view viewWithTag:LOADING_VIEW_TAG];
    [loadingView removeFromSuperview];
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                     message:@"An error occured creating url for your track please try again."
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}


#pragma mark - RDiTunesSearchServiceDelegate Protocol

- (void)iTunesSearchService:(RDiTunesSearchService *)service didSucceedWith:(NSDictionary *)info
{
    NSArray * tracks = [info objectForKey:RDiTunesTracksKey];
    if (tracks) {
        __block BOOL bFound = NO;
        //
        // loop through the results to find the highest rating
        //
        [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary * scores = [obj objectForKey:RDiTunesFuzzyScoreKey];
            float artistScore = [[scores objectForKey:RDiTunesArtistNameKey] floatValue];
            float albumScore = [[scores objectForKey:RDiTunesAlbumNameKey] floatValue];
            float trackScore = [[scores objectForKey:RDiTunesTrackNameKey] floatValue];
            //
            // If they get the album and track right then we in good shape
            //
            if (artistScore >= .9 && albumScore >= .9 && trackScore >= .7) {
                NSURL * url = [NSURL URLWithString:[obj objectForKey:RDiTunesEntityUrlKey]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_bitlyShortener shortenURL:url];
                });
                *stop = bFound = YES;
            }
        }];
        
        if (bFound) return;
        
    }
    
    [self iTunesSearchServiceFailed:service withError:nil];
}

- (void)iTunesSearchServiceFailed:(RDiTunesSearchService *)service withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performBlock:^{
            UIView * loadingView = [self.view viewWithTag:LOADING_VIEW_TAG];
            [loadingView removeFromSuperview];
            
            NSString * message = @"An error occured retreiving track information from iTunes.";
            if (!_playlist.iTunesVerified && !_playlist.isMix)
                message = @"An error occured retreiving track information from iTunes. It might be helpful if you try updating the album's info.";
            
            message = [NSString stringWithFormat:@"%@ Would you like to continue sharing anyways?", message];
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rhythm Den"
                                                             message:message
                                                            delegate:nil
                                                   cancelButtonTitle:@"NO"
                                                   otherButtonTitles:@"YES", nil];
            RDAlertView * modalView = [[RDAlertView alloc] initWithAlert:alert];
            [modalView show];
            
            if (!modalView.cancelled)
                [self shareWithUrl:nil];
        } afterDelay:0.1];
    });
}

#pragma mark - RDPlayerTutorialDelegate Protocol


- (void)playlerTutorialDismissViewController:(RDPlayerTutorialViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
        controller.transitioningDelegate = nil;
    }];
}

#pragma mark - RDPlaylistUpdateDelegate Protocol

- (void)playlist:(RDMusicPlaylist *)playlist didUpdate:(RDPlaylistUpdateType)updateType
{
#ifdef DEBUG
    NSLog(@"RDPlayerViewController(playlistDidUpdate) called for playlist: %@", playlist.name);
#endif
    if (updateType == RDPlaylistUpdateTypeUpdated) {
        //
        // Check to see if this the current playlist in the player and
        // if so update it with the new info
        //
        RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
        if ([playlist isEqualToPlaylist:player.playlist])
            _playlist = player.playlist;
        //
        // We can't overwrite the property because its in use
        // so we walk through the playlist updating the data on
        // object itself. If we tried to set the playlist property
        // on the player explicity then all the tracks associated with
        // the playlist will be garbage collected in dealloc (see RDMusicPlaylist).
        //
        _playlist.name = playlist.name;
        _playlist.artist = playlist.artist;
        _playlist.coverArt = playlist.coverArt;
        _playlist.thumbNail = playlist.thumbNail;
        _playlist.colorScheme = playlist.colorScheme;
        _playlist.iTunesVerified = YES;
        
        for (int i =0; i < playlist.discs; i++) {
            NSArray * tracks = [playlist tracksForDisc:i+1];
            [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSIndexPath * ndx = [NSIndexPath indexPathForRow:idx inSection:i+1];
                RDMusicTrack * track = [_playlist trackAtIndex:ndx];
                track.name = ((RDMusicTrack *)obj).name;
                track.iTunesUrl = ((RDMusicTrack *)obj).iTunesUrl;
                track.thumbNail = ((RDMusicTrack *)obj).thumbNail;
                track.albumArtist = ((RDMusicTrack *)obj).albumArtist;
                track.albumName = ((RDMusicTrack *)obj).albumName;
            }];
        }
        //
        // Update the cover art
        //
        RDPlaylistScrollView * scrollView = (RDPlaylistScrollView *)[self.view viewWithTag:ALBUMCOVER_SCROLLVIEW_TAG];
        [scrollView updateCoverArtFor:_playlist];
    } else {
        _playlist = playlist;
    }
    
    [self updateUI:_playlist];
}


#pragma mark - UIScrollViewDelegate Protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrollOffset = scrollView.contentOffset.y;
    
    //
    // Detect scroll for info view
    //
    CGRect headerImageFrame = self.infoView.frame;
    
    if (scrollOffset < 0)
        headerImageFrame.origin.y = _infoBoxYOffset - ((scrollOffset / 3));
    
    self.infoView.frame = headerImageFrame;

}

#pragma mark - UIGestureRecognizerDelegate Protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    DETAnimatedTransitionController * controller = (DETAnimatedTransitionController *)_animationController;
    controller.reverse = NO;
    
    return _animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    DETAnimatedTransitionController * controller = (DETAnimatedTransitionController *)_animationController;
    controller.reverse = YES;
    
    return _animationController;
}



#pragma mark - UIScrollViewDelegate Protocol

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSArray * cells = [_trackListView indexPathsForVisibleRows];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath * path = (NSIndexPath *) obj;
        RDSwipeableTableViewCell * item = (RDSwipeableTableViewCell *)[_trackListView cellForRowAtIndexPath:path];
        [item resetToOriginalState];
    }];
}


#pragma mark - RDSwipeableTableViewCellDelage Protocol

- (void)tableView:(UITableView *)tableView
willBeginCellSwipe:(RDSwipeableTableViewCell *)cell
      inDirection:(RDSwipeableTableViewCellRevealDirection)direction
{
    CGRect cellRect = cell.frame;
    int buttons = 1, buttonDistance = 55, padding = 5;
    
    if (direction == RDSwipeableTableViewCellRevealDirectionRight) {
        //
        // See what kind of play this is
        //
        if (_playlist.isMix) {
            NSMutableArray * colors = [NSMutableArray arrayWithArray:@[[[UIColor redColor] darkerColor], [[UIColor greenColor] darkerColor],
                                                                       [[UIColor blueColor] lighterColor], [[UIColor purpleColor] darkerColor],
                                                                       [[UIColor orangeColor] darkerColor]]];
            [colors shuffle];
            //
            // We are a mix so add a delete button instead
            //
            UIButton * deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
            deleteButton.tintColor = [UIColor whiteColor];
            deleteButton.frame = CGRectMake(cellRect.size.width - (buttonDistance + padding), 0, 65, cellRect.size.height);
            [deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
            [deleteButton addTarget:self action:@selector(didPressRemoveFavorite:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.revealView.backgroundColor = [colors lastObject];
            [cell.revealView addSubview:deleteButton];
        } else {
            UIButton * favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
            favoriteButton.backgroundColor = [UIColor clearColor];
            favoriteButton.tintColor = _artworkColorScheme.secondaryTextColor;
            favoriteButton.frame = CGRectMake(cellRect.size.width - (buttonDistance + padding), 0, 65, cellRect.size.height);
            [favoriteButton setImage:[UIImage imageNamed:@"favorite"] forState:UIControlStateNormal];
            [favoriteButton addTarget:self action:@selector(didPressFavorite:) forControlEvents:UIControlEventTouchUpInside];
            
            [cell.revealView addSubview:favoriteButton];
        }
        //
        // Add Repeat
        //
        UIButton * repeatButton = [UIButton buttonWithType:UIButtonTypeSystem];
        repeatButton.backgroundColor = [UIColor clearColor];
        repeatButton.tintColor = _artworkColorScheme.secondaryTextColor;
        repeatButton.frame = CGRectMake(cellRect.size.width - (buttonDistance * ++buttons), 0, 65, cellRect.size.height);
        [repeatButton setImage:[UIImage imageNamed:@"repeat"] forState:UIControlStateNormal];
        [repeatButton addTarget:self action:@selector(didPressRepeat:) forControlEvents:UIControlEventTouchUpInside];
        [cell.revealView addSubview:repeatButton];
        //
        // Add facebook
        //
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            UIButton * facebookButton = [UIButton buttonWithType:UIButtonTypeSystem];
            facebookButton.backgroundColor = [UIColor clearColor];
            facebookButton.tintColor = _artworkColorScheme.secondaryTextColor;
            facebookButton.frame = CGRectMake(cellRect.size.width - (buttonDistance * ++buttons), 0, 65, cellRect.size.height);
            facebookButton.tag = FACEBOOK_BUTTON_ID;
            [facebookButton setImage:[UIImage imageNamed:@"facebook"] forState:UIControlStateNormal];
            [facebookButton addTarget:self action:@selector(didPressShare:) forControlEvents:UIControlEventTouchUpInside];
            [cell.revealView addSubview:facebookButton];
        }
        //
        // Add Twitter
        //
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            UIButton * twitterButton = [UIButton buttonWithType:UIButtonTypeSystem];
            twitterButton.backgroundColor = [UIColor clearColor];
            twitterButton.tintColor = _artworkColorScheme.secondaryTextColor;
            twitterButton.tag = TWITTER_BUTTON_ID;
            [twitterButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
            [twitterButton addTarget:self action:@selector(didPressShare:) forControlEvents:UIControlEventTouchUpInside];
            twitterButton.frame = CGRectMake(cellRect.size.width - (buttonDistance * ++buttons), 0, 65, cellRect.size.height);
            [cell.revealView addSubview:twitterButton];
        }
        
        cell.revealDistance = [cell.revealView.subviews count] * buttonDistance + padding;
        cell.revealView.backgroundColor = _artworkColorScheme.backgroundColor.darkerColor;
        
    } else if (direction == RDSwipeableTableViewCellRevealDirectionLeft) {
        //
        // Add Revert
        //
        UIButton * revertButton = [UIButton buttonWithType:UIButtonTypeSystem];
        revertButton.backgroundColor = [UIColor clearColor];
        revertButton.tintColor = [UIColor whiteColor];
        revertButton.frame = CGRectMake(0, 0, 90, cellRect.size.height);
        [revertButton setImage:[UIImage imageNamed:@"revert"] forState:UIControlStateNormal];
        [revertButton setTitle:@"Revert" forState:UIControlStateNormal];
        [revertButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        [revertButton addTarget:self action:@selector(didPressRevertTrack:) forControlEvents:UIControlEventTouchUpInside];
        [cell.revealView addSubview:revertButton];
        //
        // Add Text description
        //
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(91, 0, 200, cellRect.size.height)];
        label.text = @"back to original track name";
        label.textColor = [UIColor whiteColor];
        label.font = revertButton.titleLabel.font;
        [cell.revealView addSubview:label];
        
        cell.revealDistance = 285;
        cell.revealView.backgroundColor = [[UIColor redColor] darkerColor];
    }
    //
    // Reset all the other cells
    //
    NSArray * cells = [_trackListView indexPathsForVisibleRows];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath * path = (NSIndexPath *) obj;
        RDSwipeableTableViewCell * item = (RDSwipeableTableViewCell *)[_trackListView cellForRowAtIndexPath:path];
        if (![item isEqual:cell]) [item resetToOriginalState];
    }];
}

- (void)tableView:(UITableView *)tableView didCellReset:(RDSwipeableTableViewCell *)cell
{
    [cell.revealView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}


#pragma mark - UITableViewDataSource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _playlist.discs;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return _playlist.discs > 1 ? SECTION_HEIGHT : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_playlist trackCountForDisc:section + 1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identity = @"trackListCell";
    
    RDPlayerViewCell * cell = (RDPlayerViewCell *) [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil)
        cell = [[RDPlayerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
    
    NSIndexPath * trackIndex = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section + 1];
    cell.track = [_playlist trackAtIndex:trackIndex];
    cell.colorScheme = _artworkColorScheme;
    cell.delegate = self;
    cell.backgroundColor = _artworkColorScheme.backgroundColor;
    cell.revealDirection = _playlist.iTunesVerified ? RDSwipeableTableViewCellRevealDirectionLeft | RDSwipeableTableViewCellRevealDirectionRight : RDSwipeableTableViewCellRevealDirectionRight;

    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = [_artworkColorScheme.backgroundColor lighterColor];
    cell.selectedBackgroundView = selectionView;
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
    // If the controls are visible don't allow cell interaction
    //
    RDPlayerViewCell * cell = (RDPlayerViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.revealViewVisible) return;
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    //
    // See if this is the current playlist and if the track is playing or paused
    //
    if (cell.track.isCurrentTrack && (player.isPaused || player.isPlaying)) {
        if (player.isPlaying) {
            //
            // Pause the stream
            //
            [player pause];
        }
        else if (player.isPaused) {
            //
            // Resume the stream
            //
            [player resume];
        }
    } else {
        //
        // Set the playlist (it might be the same instance)
        //
        player.playlist = _playlist;
        //
        // Play the selected track
        //
        NSIndexPath * trackIndex = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section + 1];
        RDMusicTrack * track = [_playlist trackAtIndex:trackIndex];
        [self playTrack:track];
    }

}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView * headerView = nil;
    
    if (self.playlist.discs > 1) {
        CGRect headerRect = CGRectMake(0, 0, tableView.bounds.size.width, SECTION_HEIGHT);
        headerView = [[UIView alloc] initWithFrame:headerRect];
        headerView.backgroundColor = _artworkColorScheme.primaryTextColor;
        
        UIView * cellheaderLabelView = [[UIView alloc] initWithFrame:headerRect];
        [headerView addSubview:cellheaderLabelView];
        
        UILabel * discTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 7, 210, 25)];
        discTitle.font = [UIFont fontWithName:@"Ubuntu Condensed" size:22];
        discTitle.textColor = _artworkColorScheme.backgroundColor;
        discTitle.text = [NSString stringWithFormat:@"Disc %i", section + 1];
        discTitle.backgroundColor = [UIColor clearColor];
        [cellheaderLabelView addSubview:discTitle];
    }
    
    return headerView;
}


#pragma mark - UI Events

- (void)didPressRevertTrack:(UIButton *)sender
{
    RDPlayerViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDPlayerViewCell class]]) {
            cell = (RDPlayerViewCell *)superView;
            break;
        }
        superView = [superView superview];
    }while (superView);
    
    RDMusicRepository * repository = [RDMusicRepository sharedInstance];
    RDTrackModel * trackModel = [repository trackByLocation:cell.track.streamLocation];
    //
    // Let's ask if they really want to do this just incase it was an accident
    //
    NSString * message = [NSString stringWithFormat:@"Are you sure you want to revert track '%@' back to '%@'", cell.track.name, trackModel.trackPrevName];
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Revert Album Track"
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Revert", nil];
    
    RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
    [modalAlert show];
    //
    // See if they pressed the Delete button
    //
    if (modalAlert.cancelled)
        return;
    //
    // Get the model
    //
    trackModel.trackName = trackModel.trackPrevName;
    trackModel.trackiTunesUrl = nil;
    trackModel.trackiTunesLookupId = nil;
    [repository saveChanges];
    //
    // Update the track name
    //
    NSIndexPath * path = [_trackListView indexPathForCell:cell];
    cell.track = [_playlist trackAtIndex:[NSIndexPath indexPathForItem:path.row inSection:path.section + 1]];
    cell.track.name = trackModel.trackName;

    [cell resetToOriginalState];
}

- (void)didPressShare:(UIButton *)sender
{
    RDPlayerViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDPlayerViewCell class]]) {
            cell = (RDPlayerViewCell *)superView;
            break;
        }
        superView = [superView superview];
    }while (superView);
    //
    // We need to figure out how to get to the
    // model associated with the track
    //
    NSIndexPath * path = [_trackListView indexPathForCell:cell];
    _sharedTrackIndex = [NSIndexPath indexPathForItem:path.row inSection:path.section + 1];
    
    RDMusicTrack * track = [_playlist trackAtIndex:_sharedTrackIndex];
    _socialNetworkId = sender.tag;
    //
    // Clear the cell
    //
    [cell resetToOriginalState];
    //
    // This does a connectivity check to see if we are on wifi
    // or not. It also hold the settings that determines if the user
    // decided to continue playing on their data plan. That way we
    // wouldn't be displaying an alert that they've already agreed upon.
    //
    if ([[RDMusicPlayer sharedInstance] safeToPlay]) {
        //
        // Snapshot what we look like and blur it
        //
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size,YES,0.0f);
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        GPUImageiOSBlurFilter *blurFilter = [GPUImageiOSBlurFilter new];
        blurFilter.blurRadiusInPixels = 5.0f;
        
        CGRect frameRect = self.view.frame;
        
        UIView * loadingView = [[UIView alloc] initWithFrame:frameRect];
        loadingView.tag = LOADING_VIEW_TAG;
        
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:frameRect];
        imageView.image = [blurFilter imageByFilteringImage:snapshotImage];
        [loadingView addSubview:imageView];
        
        UIView * fadeView = [[UIView alloc] initWithFrame:frameRect];
        fadeView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
        [loadingView addSubview:fadeView];
        
        UIActivityIndicatorView * activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.frame = CGRectMake((frameRect.size.width / 2) - (activity.bounds.size.width + 35), (frameRect.size.height / 2) - activity.bounds.size.height,
                                    activity.bounds.size.width, activity.bounds.size.height);
        [activity startAnimating];
        [loadingView addSubview:activity];
        
        CGRect activityRect = activity.frame;
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(activityRect.origin.x + activityRect.size.width + 10, activityRect.origin.y - 30, 100, 100)];
        label.font = [UIFont boldSystemFontOfSize:17.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"Please wait";
        [loadingView addSubview:label];
        
        [self.view addSubview:loadingView];
        //
        // Detect if the track has an itunes url
        //
        if (track.iTunesUrl) {
            [_bitlyShortener shortenURL:track.iTunesUrl];
        } else {
            //
            // Fetch the track info
            //
            NSDictionary * query =  @{ RDiTunesSearchQueryTrackNameKey : track.name,
                                       RDiTunesSearchQueryArtistNameKey : track.albumArtist,
                                       RDiTunesSearchQueryAlbumNameKey : track.albumName };
            
            [_iTunesService search:query];
        }
    }
}

- (void)didPressRepeat:(UIButton *)sender
{
    RDPlayerViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDPlayerViewCell class]]) {
            cell = (RDPlayerViewCell *)superView;
            break;
        }
        superView = [superView superview];
    }while (superView);
    //
    // We need to figure out how to get to the
    // model associated with the track
    //
    NSIndexPath * path = [_trackListView indexPathForCell:cell];
    RDMusicTrack * track = [_playlist trackAtIndex:[NSIndexPath indexPathForItem:path.row inSection:path.section + 1]];
    track.repeat = !track.repeat;
    //
    // Clear the cell
    //
    [cell resetToOriginalState];
    //
    // Check to see if the player is playing this track
    //
    if (track.isCurrentTrack) {
        //
        // See if the track is on repeat
        //
        if (track.repeat) {
            _playerRepeatView.hidden = NO;
            CGRect statusRect = _playerStatus.frame;
            _playerStatus.frame = (CGRect){ _playerRepeatView.frame.origin.x + _playerRepeatView.frame.size.width + 3, statusRect.origin.y, statusRect.size };
        } else {
            _playerRepeatView.hidden = YES;
            CGRect statusRect = _playerStatus.frame;
            _playerStatus.frame = (CGRect){ _playerRepeatView.frame.origin.x + 5, statusRect.origin.y, statusRect.size };
        }
    }
}

- (void)didPressFavorite:(UIButton *)sender
{
    RDPlayerViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDPlayerViewCell class]]) {
            cell = (RDPlayerViewCell *)superView;
            break;
        }
        superView = [superView superview];
    }while (superView);
    //
    // Create the anonymous function to process the selection
    //
    void (^ processSelection)(RDPlaylistModel *) ;
    processSelection = ^(RDPlaylistModel * playlistModel)
    {
        NSArray * tracks = [playlistModel.playlistTracks allObjects];
        __block BOOL bFound = NO;
        //
        // See if the track already exists
        //
        [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RDTrackModel * track = obj;
            if ([track.trackLocation isEqualToString:cell.track.streamLocation]) {
                *stop = bFound = YES;
            }
        }];
        
        if (!bFound) {
            RDMusicRepository * repository = [RDMusicRepository sharedInstance];
            //
            // It wasn't found so lets add the track to the playlist
            //
            RDTrackModel * trackModel = [repository trackByLocation:cell.track.streamLocation];
            [playlistModel addPlaylistTracksObject:trackModel];
            [repository saveChanges];
            //
            // Now lets see if the playlist we updated is the current playlist in the player
            //
            RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
            if ([playlistModel.name isEqualToString:player.playlist.name]) {
                //
                // It is so let append this album to the end of the list
                //
                RDMusicTrack * track = [RDMusicTrack new];
                track.disc = 1;
                track.number = player.playlist.tracksTotal + 1;
                track.name = trackModel.trackName;
                track.streamLocation = trackModel.trackLocation;
                track.playlist = player.playlist;
                track.thumbNail = trackModel.trackAlbums.albumArtworkThumb;
                track.coverArt = trackModel.trackAlbums.albumArtwork;
                track.albumArtist = trackModel.trackAlbums.albumArtists.artistName;
                
                if (trackModel.trackiTunesUrl)
                    track.iTunesUrl = [NSURL URLWithString:trackModel.trackiTunesUrl];
                
                if (trackModel.trackFetchDate > 0)
                    track.streamExpireDate = [NSDate dateWithTimeIntervalSince1970:trackModel.trackFetchDate];
                
                if (trackModel.trackUrl)
                    track.streamURL = [NSURL URLWithString:trackModel.trackUrl];
                
                [player.playlist addTrack:track];
            }
        }
        //
        // Reset the cell
        //
        [cell resetToOriginalState];
        //
        // Let the user know everything went ok
        //
        UIImage * check = [UIImage imageNamed:@"check"];
        TKAlertCenter * alert = [[TKAlertCenter alloc] init];
        [alert postAlertWithMessage:@"" image:[check tintColor:[UIColor whiteColor]]];
    };
    //
    // Figure out if we should display a list to choose from or just
    // automatically add the default
    //
    RDMusicRepository * repository = [RDMusicRepository sharedInstance];
    __block NSArray * playlists = [repository playlistModels];
    switch (playlists.count) {
        case 0:
        {
            //
            // Let the user know that they need to add a playlist first
            // in order for this feature to work
            //
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add to Mix"
                                                             message:@"You must create a Mix before you can access this feature"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
            [alert show];
            [cell resetToOriginalState];
            break;
        }
            
        case 1:
        {
            RDPlaylistModel * playlist = [playlists objectAtIndex:0];
            processSelection(playlist);
            break;
        }
            
        default:
        {
            //
            // Get a list of just the names
            //
            NSMutableArray * names = [NSMutableArray array];
            [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                RDPlaylistModel * playlist = obj;
                [names addObject:playlist.name];
            }];
            //
            // Display the list of play lists so the user can choose
            //
            [ActionSheetStringPicker showPickerWithTitle:@"Select a Mix"
                                                    rows:names
                                        initialSelection:0
                                               doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                   //
                                                   // Save the selection
                                                   //
                                                   RDPlaylistModel * playlist = [playlists objectAtIndex:selectedIndex];
                                                   processSelection(playlist);
                                               }
                                             cancelBlock:^(ActionSheetStringPicker *picker) {
                                                 //
                                                 // Reset the cell
                                                 //
                                                 [cell resetToOriginalState];
                                              }
                                                  origin:sender];
            break;
        }
    }
}


- (void)didPressRemoveFavorite:(UIButton *)sender
{
    RDPlayerViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDPlayerViewCell class]]) {
            cell = (RDPlayerViewCell *)superView;
            break;
        }
        superView = [superView superview];
    }while (superView);
    //
    // Throw up am alert ask if the user really wants to delete
    //
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Delete Mix Favorite"
                                                         message:[NSString stringWithFormat:@"Are you sure you want to delete %@", cell.track.name]
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Delete", nil];
    
    RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
    [modalAlert show];
    //
    // See if they pressed the Delete button
    //
    if (modalAlert.cancelled)
        return;
    //
    // Check to see if the track is currently playing
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if ([cell.track isEqualToTrack:player.currentTrack] ||
        [cell.track isEqualToTrack:player.queuedTrack])
    {
        //
        // Stop the track
        //
        [player stop];
        //
        // Hide the player
        //
        [self reset];
    }
    //
    // Delete the track from the repository
    //
    RDMusicRepository * repository = [RDMusicRepository sharedInstance];
    RDPlaylistModel * playlist = [repository playlistByName:_playlist.name];
    //
    // Loop through the track list and remove it from playlist
    //
    NSArray * tracks = [playlist.playlistTracks allObjects];
    [tracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        RDTrackModel * track = (RDTrackModel *)obj;
        if ([track.trackLocation isEqualToString:cell.track.streamLocation]) {
            [playlist removePlaylistTracksObject:track];
            [repository saveChanges];
            *stop = YES;
        }
    }];
    //
    // Remove it from the playlist
    //
    [_playlist removeTrack:cell.track];
    //
    // Update the info box
    //
    if (_playlist.discs > 1) {
        _infoTracks.text = [NSString stringWithFormat:@"%i Discs %i Tracks", _playlist.discs, _playlist.tracksTotal];
    } else {
        _infoTracks.text = [NSString stringWithFormat:@"%i Tracks", _playlist.tracksTotal];
    }
    //
    // Remove it from table view
    //
    [_trackListView reloadData];
}

- (void)didTapPlayerPlayPause
{
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (player.isPlaying) {
        //
        // Pause the stream
        //
        [player pause];
    }
    else if (player.isPaused) {
        //
        // Resume the stream
        //
        [player resume];
    }
}

- (void)didSwipePlayerNextPrev:(UIGestureRecognizer *)gesture
{
    UISwipeGestureRecognizer * swipeGesture = (UISwipeGestureRecognizer *) gesture;
    
    if (swipeGesture.direction == UISwipeGestureRecognizerDirectionLeft || swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
        RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
        if (player.currentTrack || player.queuedTrack) {
            if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight)
                [self playPreviousTrack];
            else
                [self playNextTrack];
        } else {
            //
            // This happens when we've reached the end of the play list
            //
            if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
                NSArray * tracks = [player.playlist tracksForDisc:player.playlist.discs];
                NSIndexPath * path = [NSIndexPath indexPathForItem:tracks.count - 1 inSection:player.playlist.discs];
                [self playTrack:[player.playlist trackAtIndex:path]];
            } else {
                NSIndexPath * path = [NSIndexPath indexPathForItem:0 inSection:1];
                [self playTrack:[player.playlist trackAtIndex:path]];
            }
        }
    }
}

- (void)didDoubleTapPlayer
{
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if (![_playlist isEqualToPlaylist:player.playlist]) {
        RDPlaylistScrollView * view = (RDPlaylistScrollView *) [self.view viewWithTag:ALBUMCOVER_SCROLLVIEW_TAG];
        //
        // See if this play list is already in our list of albums
        //
        BOOL bScrolled = [view scrollToPlaylist:player.playlist];
        if (!bScrolled) {
            _playlist = player.playlist;
            //
            // Update the scroll view and player
            //
            [view setPlaylists:[self getRelatedPlaylists]];
            [self updateUI:_playlist];
        }

    }
}


- (void)didLongSwipePlayer:(UIGestureRecognizer *)gesture
{
    static NSUInteger totalSeconds = 0;
    
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    RDMusicTrack * currentTrack = player.currentTrack;
    NSUInteger duration = CMTimeGetSeconds(currentTrack.duration);
    if (currentTrack && duration > 0) {
    
        if(gesture.state == UIGestureRecognizerStateBegan)
        {
            totalSeconds = player.position;
            NSUInteger dMinutes = floor(totalSeconds % 3600 / 60);
            NSUInteger dSeconds = floor(totalSeconds % 3600 % 60);
            NSString * text = [NSString stringWithFormat:@"%02i:%02i", dMinutes, dSeconds];
            
            UIView * view = [self.view viewWithTag:SCRUBBER_VIEW_TAG];
            view.layer.opacity = 0;
            view.layer.hidden = NO;
            view.frame = CGRectMake((self.view.frame.size.width / 2) - 25, self.playerView.frame.origin.y - 25, 50, 25);
            
            UILabel * time = [[view subviews] objectAtIndex:0];
            time.text = text;
            
            _swipePoint = [gesture locationInView:_playerView];
            
            [UIView animateWithDuration:0.3
                             animations:^{
                                 view.layer.opacity = 1.0f;
                             }];
        }
        else if(gesture.state == UIGestureRecognizerStateChanged)
        {
            CGPoint currentPoint = [gesture locationInView:_playerView];
            if (currentPoint.x < _swipePoint.x) {
                NSUInteger diff = _swipePoint.x - currentPoint.x;
                totalSeconds -= diff;
                //
                // If we are greater than durations default to zero
                //
                if (totalSeconds > duration)
                    totalSeconds = 0;
                
            } else {
                NSUInteger diff = currentPoint.x - _swipePoint.x;
                totalSeconds += diff;
                //
                // If we are greater than durations default to duration
                //
                if (totalSeconds > duration)
                    totalSeconds = duration;
            }
            
            NSUInteger dMinutes = floor(totalSeconds % 3600 / 60);
            NSUInteger dSeconds = floor(totalSeconds % 3600 % 60);
            NSString * text = [NSString stringWithFormat:@"%02i:%02i", dMinutes, dSeconds];
            
            UIView * view = [self.view viewWithTag:SCRUBBER_VIEW_TAG];
            UILabel * time = [[view subviews] objectAtIndex:0];
            time.text = text;

            _swipePoint = currentPoint;
            
        }
        else if(gesture.state == UIGestureRecognizerStateEnded)
        {
            [player seekTo:totalSeconds];
            
            UIView * view = [self.view viewWithTag:SCRUBBER_VIEW_TAG];
            [UIView animateWithDuration:0.3
                             animations:^{
                                 view.layer.opacity = 0;
                             }];
        }
    }
}


- (IBAction)didPressClose
{
    //
    // Turn on continuous play
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    player.playerIsVisible = NO;
    //
    // Unsubscribe from notifications
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.delegate playerViewControllerDidClose:self];
}

- (IBAction)didPressVerifyAlbum
{
    //
    // This does a connectivity check to see if we are on wifi
    // or not. It also hold the settings that determines if the user
    // decided to continue playing on their data plan. That way we
    // wouldn't be displaying an alert that they've already agreed upon.
    //
    if ([[RDMusicPlayer sharedInstance] safeToPlay]) {
        NSString * location = [_playlist.playlistId objectForKey:@"streamLocation"];
        RDAlbumModel * model = [[RDMusicRepository sharedInstance] albumModelByLocation:location];
        
        _verifyController = [[RDPlayerAlbumVerifyController alloc] initWithContentController:self];
        [_verifyController search:@{ RDiTunesSearchQueryAlbumNameKey : model.albumPrevTitle, RDiTunesSearchQueryArtistNameKey : model.albumArtists.artistName }];
    }
}


@end
