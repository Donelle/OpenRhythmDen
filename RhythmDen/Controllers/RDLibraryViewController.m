//
//  MainViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 12/27/11.
//  Copyright (c) 2011 The Potter's Den, Inc. All rights reserved.
//
#import "RDLibraryViewController.h"
#import "RDPlayerViewController.h"
#import "RDMusicRepository.h"
#import "RDModels+RhythmDen.h"
#import "RDMusicPlayer.h"
#import "RDMusicResourceCache.h"
#import "RDMusicLibrary.h"
#import "RDAppPreference.h"
#import "RDSwipeableTableViewCell.h"
#import "NSObject+RhythmDen.h"
#import "UIImage+RhythmDen.h"
#import "UIColor+RhythmDen.h"
#import "LEColorPicker.h"
#import <QuartzCore/QuartzCore.h>


#pragma mark - RDlibraryViewAlbumCell Implementation

@interface RDLibraryViewAlbumCell : RDSwipeableTableViewCell
@property (assign, nonatomic) RDSortPreference sortBy;
@property (strong, nonatomic) RDAlbumModel * album;
@end


@implementation RDLibraryViewAlbumCell {
    UILabel * _albumArtist;
    UILabel * _albumTitle;
    UILabel * _albumSongs;
    UIImageView * _albumArtwork;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        _albumArtwork = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10, 65, 65)];
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
        
        _albumSongs = [[UILabel alloc] initWithFrame:CGRectMake(80, 49, 233, 21)];
        _albumSongs.font = [UIFont systemFontOfSize:13.0];
        _albumSongs.textColor = fontColor;
        _albumSongs.textAlignment = NSTextAlignmentLeft;
        _albumSongs.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumSongs.backgroundColor = [UIColor clearColor];
        [self addSubview:_albumSongs];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    self.backgroundColor = [UIColor colorWithPatternImage:[cache gradientImageByKey:ResourceCacheCellBackColorKey
                                                                           withRect:self.bounds
                                                                         withColors:cache.cellGradientBackColors]];
    
    self.layer.borderColor = cache.cellBorderColor.CGColor;
    self.layer.borderWidth = 0.4f;
    //
    // Set up meta data
    //
    if (self.sortBy == RDSortByArtistPreference) {
        _albumTitle.text = _album.albumArtists.artistName;
        _albumArtist.text = _album.albumTitle;
    } else {
        _albumTitle.text = _album.albumTitle;
        _albumArtist.text = _album.albumArtists.artistName;
    }
    //
    // Set up track count
    //
    if (_album.albumDiscs > 1) {
        _albumSongs.text = [NSString stringWithFormat:@"%i Discs %i Tracks", _album.albumDiscs, _album.albumTrackCount];
    } else {
        _albumSongs.text = [NSString stringWithFormat:@"%i Tracks", _album.albumTrackCount];
    }
    //
    // Check to see if we are the current album playing
    //
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    if ((player.isPlaying || player.isPaused) && [_album.albumTitle isEqualToString:player.playlist.name]) {
        self.backgroundColor = cache.cellHighlightedBackColor;
    }
}


- (void)setAlbum:(RDAlbumModel *)album
{
    _album = album;
    [self setNeedsLayout];
    //
    // Load image
    //
    NSData * artworkData = _album.albumArtworkThumb;
    [self performBlockInBackground:^{
        UIImage * albumArt = [[RDMusicResourceCache sharedInstance] missingCoverArtImage];
        Float32 radius = 0.0f;
        
        if (artworkData) {
            albumArt = [UIImage imageWithData:artworkData];
            radius = 10;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _albumArtwork.clipsToBounds = YES;
            _albumArtwork.image = albumArt;
            _albumArtwork.layer.opacity = 0;
            _albumArtwork.layer.cornerRadius = radius;
            [UIView animateWithDuration:1.0
                             animations:^{
                                 _albumArtwork.layer.opacity = 1.0;
                             } completion:^(BOOL finished) {
                             }];
            
        });
    }];
}


@end


#pragma mark - RDlibrarySearchViewController Implementation

@interface RDLibrarySearchViewController : UITableViewController<UISearchBarDelegate,UISearchDisplayDelegate>
- (id)initWithSearchBar:(UISearchBar *)searchBar andViewController:(UIViewController *)contentController;
@end


typedef enum {
    RDLibrarySearchAlbums = 1,
    RDLibrarySearchArtists = 2,
    RDLibrarySearchBoth = 3,
} RDLibrarySearchState;

@implementation RDLibrarySearchViewController
{
    NSFetchedResultsController * _artistRepository;
    NSFetchedResultsController * _albumRepository;
    UISearchDisplayController * _searchDisplayController;
    NSString * _queryText;
    RDLibrarySearchState _searchState;
}

- (id)initWithSearchBar:(UISearchBar *)searchBar andViewController:(UIViewController *)contentController
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:contentController];
        _searchDisplayController.delegate = self;
        _searchDisplayController.searchResultsDataSource = self;
        _searchDisplayController.searchResultsDelegate = self;
    }
    return self;
}

- (void)dealloc
{
    _searchDisplayController.delegate = nil;
    _searchDisplayController = nil;
    _artistRepository = nil;
    _albumRepository = nil;
}

#pragma mark - Methods

- (void)searchRepository
{
    _artistRepository = [[RDMusicRepository sharedInstance] searchLibraryControllerWith:_queryText sortBy:RDSortByArtistPreference];
    _albumRepository = [[RDMusicRepository sharedInstance] searchLibraryControllerWith:_queryText sortBy:RDSortByAlbumPreference];
    [_searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark - UISearchBarDelegate Protocol

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UIImage * background = [cache gradientImageByKey:ResourceCacheCellBackColorKey withRect:_searchDisplayController.searchBar.bounds withColors:cache.viewGradientBackColors];

    _searchDisplayController.searchBar.backgroundColor = [UIColor colorWithPatternImage:background];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    //
    // We check for two kinds of events:
    // 1. User clicked outside of the searchbar (therefore the result table is hidden)
    // 2. User clicked a row from the result list (result table is visible but we clicked something)
    //
    NSIndexPath * cellSelected = _searchDisplayController.searchResultsTableView.indexPathForSelectedRow;
    if (_searchDisplayController.searchResultsTableView.hidden || cellSelected) {
        [self searchBarCancelButtonClicked:searchBar];
    }
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchDisplayController.searchBar.backgroundColor = [UIColor clearColor];
}


#pragma mark - UISearchDisplayControllerDelegate Protocol

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _queryText = searchString;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchRepository) object:nil];
    [self performSelector:@selector(searchRepository) withObject:nil afterDelay:0.7];
    return NO;
}


- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    //
    // Setup the tableview background color for the search
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UIImage * background = [cache gradientImageByKey:ResourceCacheCellBackColorKey withRect:tableView.bounds withColors:cache.cellGradientBackColors];
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor colorWithPatternImage:background];
}

#pragma mark - UITableViewDataSource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    id<NSFetchedResultsSectionInfo> info = [[_artistRepository sections] objectAtIndex:0];
    int artistCount = [info numberOfObjects];
    
    info = [[_albumRepository sections] objectAtIndex:0];
    int albumCount = [info numberOfObjects];
    
    if (artistCount > 0 && albumCount > 0) {
        _searchState = RDLibrarySearchBoth;
        return 2;
    }
    
    if (artistCount > 0) {
        _searchState = RDLibrarySearchArtists;
        return 1;
    }
    
    if (albumCount > 0) {
        _searchState = RDLibrarySearchAlbums;
        return 1;
    }
    
    return 0;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //
    // The artist will always come before album title
    //
    if ((_searchState == RDLibrarySearchBoth && section == 0) || _searchState == RDLibrarySearchArtists) {
        id<NSFetchedResultsSectionInfo> info = [[_artistRepository sections] objectAtIndex:0];
        int objects = [[info objects] count];
        
        for (int i =0, rows = 0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *) [[info objects] objectAtIndex:i];
            rows += artist.artistAlbums.count;
            
            if ((i + 1) == objects) {
                return  rows;
            }
        }
    }
    //
    // Albums
    //
    id<NSFetchedResultsSectionInfo> info = [[_albumRepository sections] objectAtIndex:0];
    return [info numberOfObjects];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"CellIdentifier";
    
    RDLibraryViewAlbumCell * cell = (RDLibraryViewAlbumCell *) [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil)
        cell = [[RDLibraryViewAlbumCell alloc] init];
    
    RDAlbumModel * album = nil;
    if ((_searchState == RDLibrarySearchBoth && indexPath.section == 0) || _searchState == RDLibrarySearchArtists) {
        cell.sortBy = RDSortByArtistPreference;
        
        id<NSFetchedResultsSectionInfo> info = [[_artistRepository sections] objectAtIndex:0];
        NSInteger objects = [info numberOfObjects];
        
        for (int i = 0, rows =0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *)  [[info objects] objectAtIndex:i];
            NSArray * albums = [artist sortedAlbums];
            rows += albums.count;
            if (indexPath.row < rows) {
                int ndx = indexPath.row - (rows - albums.count);
                album = [albums objectAtIndex:ndx];
                break;
            }
        }
    } else {
        cell.sortBy = RDSortByAlbumPreference;
        album = (RDAlbumModel *)[_albumRepository objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    }
    
    if (album) {
        UIView * selectionView = [[UIView alloc] init];
        selectionView.backgroundColor = [[RDMusicResourceCache sharedInstance] cellSelectionBackColor];
        cell.selectedBackgroundView = selectionView;
        cell.album = album;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    RDAlbumModel * album = nil;
    if ((_searchState == RDLibrarySearchBoth && indexPath.section == 0) || _searchState == RDLibrarySearchArtists) {
        id<NSFetchedResultsSectionInfo> info = [[_artistRepository sections] objectAtIndex:0];
        NSInteger objects = [info numberOfObjects];
        
        for (int i = 0, rows =0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *)  [[info objects] objectAtIndex:i];
            NSArray * albums = [artist sortedAlbums];
            rows += albums.count;
            if (indexPath.row < rows) {
                int ndx = indexPath.row - (rows - albums.count);
                album = [albums objectAtIndex:ndx];
                break;
            }
        }
    } else {
        album = (RDAlbumModel *)[_albumRepository objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    }
    
    RDMusicPlaylist * playlist = [RDMusicPlaylist new];
    playlist.playlistId = @{@"streamLocation" : album.albumLocation};
    playlist.name = album.albumTitle;
    playlist.artist = album.albumArtists.artistName;
    playlist.coverArt = album.albumArtwork;
    playlist.thumbNail = album.albumArtworkThumb;
    playlist.colorScheme = [album getColorSchemeDictionary];
    playlist.iTunesVerified = album.albumiTunesVerified;
    [playlist addTrackModels:[album.albumTracks allObjects]];
    //
    // Check to see if we have valid colors if it's zero then we
    // never processed this album's artwork because sync for this
    // album was done in the background.
    //
    if (playlist.colorScheme.count == 0) {
        UIImage * thumbNail = [UIImage imageWithData:album.albumArtworkThumb];
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
        // Save to repository
        //
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        [repository saveChanges];
        //
        // Update the playlist object
        //
        playlist.colorScheme = colorsDictionary;
    }
    
    [_searchDisplayController.searchContentsController performSelector:@selector(showPlayerWith:) withObject:playlist];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [_searchDisplayController setActive:NO animated:YES];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect headerRect = CGRectMake(0, 0, tableView.bounds.size.width, 30.0);;
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UIView * headerView = [[UIView alloc] initWithFrame:headerRect];
    UIImage * backgroundImage = [cache gradientImageByKey:ResourceCacheCellBackColorKey withRect:headerRect withColors:cache.cellGradientBackColors];;
    headerView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
    
    UIView * cellheaderLabelView = [[UIView alloc] initWithFrame:headerRect];
    cellheaderLabelView.layer.borderColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1].CGColor;
    cellheaderLabelView.layer.borderWidth = 0.5f;
    cellheaderLabelView.backgroundColor = cache.darkBackColor;
    
    UILabel * sectionLetter = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 210, 20)];
    sectionLetter.font = [UIFont fontWithName:@"Ubuntu Condensed" size:22];
    sectionLetter.textColor = cache.labelTitleTextColor;
    sectionLetter.backgroundColor = [UIColor clearColor];
    sectionLetter.text = @"Albums";
    
    if ((_searchState == RDLibrarySearchBoth && section == 0) || _searchState == RDLibrarySearchArtists)
        sectionLetter.text = @"Artists";
    
    [cellheaderLabelView addSubview:sectionLetter];
    [headerView addSubview:cellheaderLabelView];
    
    return headerView;
}



@end


#pragma mark - RDLibraryViewController Implementation

@interface RDLibraryViewController () <RDPlayerViewControllerDelegate>

- (void)didPressSort:(id)sender;
- (void)didPressSortOptionChanged:(id)sender;
- (void)didPressNowPlaying:(id)sender;
- (void)showPlayerWith:(RDMusicPlaylist *)playlist;

- (void)didReceiveMusicLibrarySyncCompletedNotification:(NSNotification *)notification;
- (void)didReceiveTrackStartedNotification:(NSNotification *)notification;
- (void)didReceiveTrackEndedNotification:(NSNotification *)notification;

@end

@implementation RDLibraryViewController {
    NSFetchedResultsController * _repositoryController;
    RDAppPreference * _preference;
    RDLibrarySearchViewController * _searchController;
    CGPoint _savedOffset;
    BOOL _didReceiveLowMemoryWarning;
}

#define SECTION_HEADER_HEIGHT 30.0
#define SEARCHBAR_TAG 100
#define SORTOPTIONS_TAG 101
#define SORTBUTTON_TAG 102
#define SEARCHSORTHEADER_TAG 103

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _preference = [[RDAppPreference alloc] init];
    //
    // Register for syncronization notifications
    //
    [self registerForNotificationWith:@selector(didReceiveTrackStartedNotification:) forName:RDMusicPlayerTrackStartedNotification];
    [self registerForNotificationWith:@selector(didReceiveTrackEndedNotification:) forName:RDMusicPlayerTrackEndedNotification];
    [self registerForNotificationWith:@selector(didReceiveMusicLibrarySyncCompletedNotification:) forName:RDMusicLibraryClearedNotification];
    [self registerForNotificationWith:@selector(didReceiveMusicLibrarySyncCompletedNotification:) forName:RDMusicLibrarySyncCompleteNotification];
    [self registerForNotificationWith:@selector(didReceiveMusicLibrarySyncCompletedNotification:) forName:RDMusicLibrarySyncCancelledNotification];
    [self registerForNotificationWith:@selector(didReceiveMusicLibrarySyncCompletedNotification:) forName:RDMusicLibrarySyncFailedNotification];
    //
    // Setup the title of our note card
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)];
    title.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    title.textColor = cache.labelTitleTextColor;
    title.backgroundColor = [UIColor clearColor];
    title.text = @"Music";
    self.navigationItem.titleView = title;
    //
    // Setup searchbar
    //
    CGRect headerRect = self.librarySearchBar.frame;
    self.librarySearchBar.translucent = YES;
    self.librarySearchBar.barTintColor = [UIColor clearColor];
    self.librarySearchBar.backgroundColor = [UIColor clearColor];
    //
    // Setup sort options
    //
    UIImageView * sortImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 24, 24)];
    sortImage.image = [[UIImage imageNamed:@"sort-icon"] tintColor:cache.barTintColor];
    sortImage.contentMode = UIViewContentModeScaleAspectFit;
    
    UISegmentedControl * sortOptions = [[UISegmentedControl alloc] initWithFrame:CGRectMake(45, 2, headerRect.size.width - 80, headerRect.size.height - 10)];
    sortOptions.tag = SORTOPTIONS_TAG;
    [sortOptions setTintColor:cache.barTintColor];
    [sortOptions insertSegmentWithTitle:@"Album Title" atIndex:0 animated:NO];
    [sortOptions insertSegmentWithTitle:@"Album Artist" atIndex:1 animated:NO];
    sortOptions.selectedSegmentIndex = _preference.librarySortBy == RDSortByAlbumPreference ? 0 : 1;
    [sortOptions addTarget:self action:@selector(didPressSortOptionChanged:) forControlEvents:UIControlEventValueChanged];
    
    UIView * container = [[UIView alloc] initWithFrame:headerRect];
    container.tag = SEARCHSORTHEADER_TAG;
    [container addSubview:sortImage];
    [container addSubview:sortOptions];
    //
    // Setup tableview index color
    //
    [self.libraryView setSectionIndexColor:cache.labelTitleTextColor];
    [self.libraryView setSectionIndexTrackingBackgroundColor:cache.tableIndexTrackingColor];
    [self.libraryView setSectionIndexBackgroundColor:[UIColor clearColor]];
    [self.libraryView setTableHeaderView:container];
    _savedOffset = CGPointMake(0, headerRect.size.height);
    //
    // Get our data fetchers
    //
    _repositoryController = [[RDMusicRepository sharedInstance] musicLibraryControllerBySort:_preference.librarySortBy];
    _searchController = [[RDLibrarySearchViewController alloc] initWithSearchBar:self.librarySearchBar andViewController:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.libraryView.contentOffset = _savedOffset;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _savedOffset = self.libraryView.contentOffset;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDLibraryViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder) {
        _repositoryController.delegate = nil;
        _repositoryController = nil;
        _preference = nil;
        _searchController = nil;
        _didReceiveLowMemoryWarning = YES;
        self.view = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
}


#pragma mark - Instance Methods


- (void)didPressSort:(id)sender
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    UISegmentedControl * sortOptions = (UISegmentedControl *) [self.libraryView.tableHeaderView viewWithTag:SORTOPTIONS_TAG];
    
    UIButton * sortButton = (UIButton *)sender;
    sortButton.selected = !sortButton.selected;
    
    if (sortButton.selected) {
        [sortButton setTintColor:cache.darkBackColor];
        [sortButton setBackgroundColor:cache.barTintColor];
    
        sortOptions.selectedSegmentIndex = _preference.librarySortBy == RDSortByAlbumPreference ? 0 : 1;
    } else {
        [sortButton setTintColor:cache.barTintColor];
        [sortButton setBackgroundColor:cache.darkBackColor];
    }
}

- (void)didPressSortOptionChanged:(id)sender
{
    UISegmentedControl * sortOptions = (UISegmentedControl *)sender;
    //
    // Save the new selections
    //
    _preference.librarySortBy = sortOptions.selectedSegmentIndex == 0 ? RDSortByAlbumPreference : RDSortByArtistPreference;
    //
    // Reload
    //
    _repositoryController = [[RDMusicRepository sharedInstance] musicLibraryControllerBySort:_preference.librarySortBy];
    [self.libraryView reloadData];
}


- (void)didPressNowPlaying:(id)sender
{
    [self showPlayerWith:[[RDMusicPlayer sharedInstance] playlist]];
}


- (void)showPlayerWith:(RDMusicPlaylist *)playlist
{
    RDPlayerViewController *  playerController = [[self storyboard] instantiateViewControllerWithIdentifier:@"Player"];
    playerController.playlist = playlist;
    playerController.delegate = self;
    
    [self presentViewController:playerController animated:YES completion:nil];
}

#pragma mark - NSNotifications Methods


- (void)didReceiveMusicLibrarySyncCompletedNotification:(NSNotification *)notification
{
#if DEBUG
    NSLog(@"RDLibraryViewController - didReceiveMusicLibrarySyncCompletedNotification called");
#endif
    //
    // Reload
    //
    _repositoryController = [[RDMusicRepository sharedInstance] musicLibraryControllerBySort:_preference.librarySortBy];
    [self.libraryView reloadData];
}

- (void)didReceiveTrackStartedNotification:(NSNotification *)notification
{
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UIButton * nowPlayingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    nowPlayingBtn.tintColor = cache.barTintColor;
    nowPlayingBtn.backgroundColor = cache.darkBackColor;
    nowPlayingBtn.frame = CGRectMake(0, 0, 73, 30);
    nowPlayingBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    nowPlayingBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    nowPlayingBtn.titleLabel.numberOfLines = 2;
    nowPlayingBtn.layer.cornerRadius = 5.0;
    [nowPlayingBtn setTitle:@"Now Playing" forState:UIControlStateNormal];
    [nowPlayingBtn setTitleEdgeInsets:UIEdgeInsetsMake(0.0, -35.0, 0.0, 0.0)];
    [nowPlayingBtn setImage:[UIImage imageNamed:@"now-playing"] forState:UIControlStateNormal];
    [nowPlayingBtn setImageEdgeInsets:UIEdgeInsetsMake(6.0, 6.0, 6.0, 50.0)];
    [nowPlayingBtn addTarget:self action:@selector(didPressNowPlaying:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:nowPlayingBtn];
    [_libraryView reloadData];
}


- (void)didReceiveTrackEndedNotification:(NSNotification *)notification
{
    self.navigationItem.rightBarButtonItem = nil;
}


#pragma mark - RDPlayerViewControllerDelegate Protocol

- (void)playerViewControllerDidClose:(RDPlayerViewController *)controller
{
    [_libraryView reloadData];
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
    }];
}


#pragma mark - UITableViewDataSource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_repositoryController sections] count];
}


-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
     __block NSMutableArray * letters = [NSMutableArray array];
    
    [_repositoryController.sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<NSFetchedResultsSectionInfo> section = obj;
        [letters addObject:[section name]];
    }];
    
    return letters;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger objects = 0;

    id<NSFetchedResultsSectionInfo> info = [[_repositoryController sections] objectAtIndex:section];
    objects = [info numberOfObjects];
    
    if(_preference.librarySortBy == RDSortByArtistPreference) {
        for (int i =0, rows = 0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *) [[info objects] objectAtIndex:i];
            rows += artist.artistAlbums.count;
            
            if ((i + 1) == objects) {
                objects = rows;
                break;
            }
        }
    }
    
    return objects;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"listViewCell";
    
    RDLibraryViewAlbumCell * cell = (RDLibraryViewAlbumCell *) [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil) 
        cell = [[RDLibraryViewAlbumCell alloc] init];
    
    RDAlbumModel * album = nil;
    
    if (_preference.librarySortBy == RDSortByAlbumPreference) {
        album = (RDAlbumModel *)[_repositoryController objectAtIndexPath:indexPath];
    } else {
        id<NSFetchedResultsSectionInfo> info = [[_repositoryController sections] objectAtIndex:indexPath.section];
        NSInteger objects = [info numberOfObjects];
        
        for (int i = 0, rows =0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *)  [[info objects] objectAtIndex:i];
            NSArray * albums = [artist sortedAlbums];
            rows += albums.count;
            if (indexPath.row < rows) {
                int ndx = indexPath.row - (rows - albums.count);
                album = [albums objectAtIndex:ndx];
                break;
            }
        }
    }
    
    cell.album = album;
    
    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = [[RDMusicResourceCache sharedInstance] cellSelectionBackColor];
    cell.selectedBackgroundView = selectionView;
    cell.sortBy = _preference.librarySortBy;
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RDAlbumModel * album = nil;

    if (_preference.librarySortBy == RDSortByAlbumPreference) {
        album =  [_repositoryController objectAtIndexPath:indexPath];
    } else {
        id<NSFetchedResultsSectionInfo> info = [[_repositoryController sections] objectAtIndex:indexPath.section];
        NSInteger objects = [info numberOfObjects];
        
        for (int i = 0, rows =0 ; i < objects; i++) {
            RDArtistModel * artist = (RDArtistModel *)  [[info objects] objectAtIndex:i];
            NSArray * albums = [artist sortedAlbums];
            rows += albums.count;
            if (indexPath.row < rows) {
                int ndx = indexPath.row - (rows - albums.count);
                album = [albums objectAtIndex:ndx];
                break;
            }
        }
    }
    
    RDMusicPlaylist * playlist = [RDMusicPlaylist new];
    playlist.playlistId = @{@"streamLocation" : album.albumLocation};
    playlist.name = album.albumTitle;
    playlist.artist = album.albumArtists.artistName;
    playlist.coverArt = album.albumArtwork;
    playlist.thumbNail = album.albumArtworkThumb;
    playlist.colorScheme = [album getColorSchemeDictionary];
    playlist.iTunesVerified = album.albumiTunesVerified;
    [playlist addTrackModels:[album.albumTracks allObjects]];
    //
    // Check to see if we have valid colors if it's zero then we
    // never processed this album's artwork because sync for this
    // album was done in the background.
    //
    if (playlist.colorScheme.count == 0) {
        UIImage * thumbNail = [UIImage imageWithData:album.albumArtworkThumb];
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
        // Save to repository
        //
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        [repository saveChanges];
        //
        // Update the playlist object
        //
        playlist.colorScheme = colorsDictionary;
    }

    [self showPlayerWith:playlist];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    id<NSFetchedResultsSectionInfo> info = [[_repositoryController sections] objectAtIndex:section];
    
    CGRect headerRect = CGRectMake(0, 0, tableView.bounds.size.width, SECTION_HEADER_HEIGHT);;
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UIView * headerView = [[UIView alloc] initWithFrame:headerRect];
    UIImage * backgroundImage = [cache gradientImageByKey:ResourceCacheCellBackColorKey withRect:headerRect withColors:cache.cellGradientBackColors];;
    headerView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
    
    UIView * cellheaderLabelView = [[UIView alloc] initWithFrame:headerRect];
    cellheaderLabelView.layer.borderColor = [UIColor colorWithRed:43.0/255.0 green:25.0/255.0 blue:14.0/255.0 alpha:1].CGColor;
    cellheaderLabelView.layer.borderWidth = 0.5f;
    cellheaderLabelView.backgroundColor = cache.darkBackColor;
    
    UILabel * sectionLetter = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 210, 20)];
    sectionLetter.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    sectionLetter.textColor = cache.labelTitleTextColor;
    sectionLetter.text = [info name];
    sectionLetter.backgroundColor = [UIColor clearColor];
    [cellheaderLabelView addSubview:sectionLetter];
    [headerView addSubview:cellheaderLabelView];
    
    return headerView;
}


@end
