//
//  RDMixViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 9/15/13.
//
//
#import "RDMixViewController.h"
#import "RDMusicResourceCache.h"
#import "RDMusicRepository.h"
#import "RDMusicPlayer.h"
#import "RDPlayerViewController.h"
#import "RDAlertView.h"
#import "UIImage+RhythmDen.h"
#import "UIColor+RhythmDen.h"
#import "NSArray+RhythmDen.h"
#import "RDSwipeableTableViewCell.h"


#pragma mark - RDMixlibraryViewCell Implementation

@interface RDMixlibraryViewCell : RDSwipeableTableViewCell
@property (strong, nonatomic) RDPlaylistModel * playlist;
@end


@implementation RDMixlibraryViewCell {
    UILabel * _albumArtist;
    UILabel * _albumTitle;
    UILabel * _albumSongs;
    UIImageView * _albumArtwork;
}

@synthesize playlist = _playlist;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        
        _albumArtwork = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10, 65, 65)];
        _albumArtwork.clipsToBounds = YES;
        _albumArtwork.contentMode = UIViewContentModeScaleToFill;
        _albumArtwork.image = cache.playlistThumbImage;
        _albumArtwork.layer.cornerRadius = 10.0f;
        [self.contentView addSubview:_albumArtwork];
        
        _albumTitle = [[UILabel alloc] initWithFrame:CGRectMake(79, 10, 221, 21)];
        _albumTitle.font = [UIFont boldSystemFontOfSize:16.0];
        _albumTitle.textColor = [UIColor colorWithRed:115.0/255.0 green:51.0/255.0 blue:21.0/255.0 alpha:1];
        _albumTitle.textAlignment = NSTextAlignmentLeft;
        _albumTitle.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumTitle.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_albumTitle];
        
        UIColor * fontColor = [UIColor colorWithRed:150.0/255.0 green:121.0/255.0 blue:101.0/255.0 alpha:1];
        
        _albumArtist = [[UILabel alloc] initWithFrame:CGRectMake(79, 29, 221, 21)];
        _albumArtist.font = [UIFont boldSystemFontOfSize:13.0];
        _albumArtist.textColor = fontColor;
        _albumArtist.textAlignment = NSTextAlignmentLeft;
        _albumArtist.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumArtist.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_albumArtist];
        
        _albumSongs = [[UILabel alloc] initWithFrame:CGRectMake(80, 49, 233, 21)];
        _albumSongs.font = [UIFont systemFontOfSize:13.0];
        _albumSongs.textColor = fontColor;
        _albumSongs.textAlignment = NSTextAlignmentLeft;
        _albumSongs.lineBreakMode = NSLineBreakByTruncatingTail;
        _albumSongs.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_albumSongs];
      
        self.revealDirection = RDSwipeableTableViewCellRevealDirectionRight;
        self.revealDistance = 150.0f;
        self.layer.borderColor = cache.cellBorderColor.CGColor;
        self.layer.borderWidth = 0.4f;
    }
    return self;
}


- (void)setPlaylist:(RDPlaylistModel *)playlist
{
    _playlist = playlist;
    //
    // Set up meta data
    //
    _albumTitle.text = _playlist.name;
    _albumArtist.text = @"Mix";
    _albumSongs.text = [NSString stringWithFormat:@"%i Tracks", _playlist.playlistTracks.count];
}

@end


#pragma mark - RDMixViewController Implementation

@interface RDMixViewController () <NSFetchedResultsControllerDelegate,RDSwipeableTableViewCellDelegate,RDPlayerViewControllerDelegate>

- (void)didPressAddPlaylist;
- (void)didPressDeletePlaylist:(UIButton *)sender;
- (void)didPressEditPlaylist:(UIButton *)sender;
@end

@implementation RDMixViewController {
    RDAppPreference * _preferences;
    NSFetchedResultsController * _repositoryController;
}

@synthesize mixListView = _mixListView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _preferences = [[RDAppPreference alloc] init];
	//
    // Setup our background
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    //
    // Setup the title of our note card
    //
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)];
    title.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    title.textColor = cache.labelTitleTextColor;
    title.backgroundColor = [UIColor clearColor];
    title.text = @"Mix Factory";
    self.navigationItem.titleView = title;
    //
    // Setup Add Mix button
    //
    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(didPressAddPlaylist)];
    [addButton setTintColor:cache.labelTitleTextColor];
    self.navigationItem.leftBarButtonItem = addButton;
    //
    // Setup the fetch controller
    //
    _repositoryController = [[RDMusicRepository sharedInstance] mixLibraryController];
    _repositoryController.delegate = self;
}


- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDMixViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder) {
        _preferences = nil;
        _repositoryController = nil;
        _mixListView = nil;
        self.view = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
}



#pragma mark - NSFetchedResultsControllerDelegate Protocol

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [_mixListView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_mixListView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_mixListView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_mixListView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            RDMixlibraryViewCell * cell = (RDMixlibraryViewCell *)[_mixListView cellForRowAtIndexPath:indexPath];
            cell.playlist = anObject;
            break;
        }
        default:
            break;
    }
}


#pragma mark - RDSwipeableTableViewCellDelegate delegate methods

- (void)tableView:(UITableView *)tableView
willBeginCellSwipe:(RDSwipeableTableViewCell *)cell
      inDirection:(RDSwipeableTableViewCellRevealDirection)direction
{
    if ([cell.revealView.subviews count] == 0) {
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        cell.revealView.backgroundColor = cache.darkBackColor;
        
        CGRect cellRect = cell.frame;
        
        UIButton * deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        deleteButton.backgroundColor = [[UIColor redColor] darkerColor];
        deleteButton.tintColor = [UIColor whiteColor];
        deleteButton.frame = CGRectMake(cellRect.size.width - 65, 0, 65, cellRect.size.height);
        [deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
        [deleteButton addTarget:self action:@selector(didPressDeletePlaylist:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.revealView addSubview:deleteButton];
        
        UIButton * editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        editButton.backgroundColor = cache.barTintColor;
        editButton.titleLabel.font = [UIFont systemFontOfSize:15];
        editButton.frame = CGRectMake(deleteButton.frame.origin.x - 65, 0, 65, cellRect.size.height);
        [editButton setTitleColor:cache.darkBackColor forState:UIControlStateNormal];
        [editButton setTitle:@"Edit" forState:UIControlStateNormal];
        [editButton addTarget:self action:@selector(didPressEditPlaylist:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.revealView addSubview:editButton];
    }
    //
    // Slide any other mix back to normal
    //
    NSArray * cells = [_mixListView indexPathsForVisibleRows];
    [cells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath * path = (NSIndexPath *) obj;
        RDSwipeableTableViewCell * item = (RDSwipeableTableViewCell *)[_mixListView cellForRowAtIndexPath:path];
        if (![item isEqual:cell]) [item resetToOriginalState];
    }];
}


#pragma mark - RDPlayerViewControllerDelegate Protocol

- (void)playerViewControllerDidClose:(RDPlayerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
    }];
}



#pragma mark - UITableViewDataSource Protocol

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> info = [[_repositoryController sections] objectAtIndex:section];
    return [[info objects] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"listViewCell";
    
    RDMixlibraryViewCell * cell = (RDMixlibraryViewCell *) [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil) {
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        
        cell = [[RDMixlibraryViewCell alloc] init];
        cell.delegate = self;
        cell.backgroundColor = [UIColor colorWithPatternImage:[cache gradientImageByKey:ResourceCacheCellBackColorKey
                                                                               withRect:cell.bounds
                                                                             withColors:cache.cellGradientBackColors]];
        
        UIView * selectionView = [[UIView alloc] init];
        selectionView.backgroundColor = cache.darkBackColor;
        cell.selectedBackgroundView = selectionView;
    }

    cell.playlist = (RDPlaylistModel *)[_repositoryController objectAtIndexPath:indexPath];
    
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RDMixlibraryViewCell * cell = (RDMixlibraryViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.revealViewVisible) return;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
    __block RDMusicPlaylist * playlist = player.playlist;
    //
    // Check to see if the current playlist is already this mix if it
    // is we can save resources by not trying to fetch
    //
    RDPlaylistModel * playlistModel = (RDPlaylistModel *)[_repositoryController objectAtIndexPath:indexPath];
    if (![playlistModel.name isEqualToString:player.playlist.name]) {
        playlist = [RDMusicPlaylist new];
        playlist.playlistId = @{@"name" : playlistModel.name , @"createDate" : [NSDate dateWithTimeIntervalSince1970:playlistModel.createDate]};
        playlist.name = playlistModel.name;
        playlist.artist = @"Mix";
        playlist.isMix = YES;
        playlist.coverArt = UIImageJPEGRepresentation([[RDMusicResourceCache sharedInstance] playlistCoverArt], 0.0);
        
        NSMutableArray * shuffledTracks = [NSMutableArray arrayWithArray:[playlistModel.playlistTracks allObjects]];
        [shuffledTracks shuffle];
        
        [shuffledTracks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            RDTrackModel * model = (RDTrackModel *)obj;
            RDMusicTrack * track = [RDMusicTrack new];
            track.disc = 1;
            track.number = idx + 1;
            track.name = model.trackName;
            track.streamLocation = model.trackLocation;
            track.playlist = playlist;
            track.thumbNail = model.trackAlbums.albumArtworkThumb;
            track.coverArt = model.trackAlbums.albumArtwork;
            track.albumName = model.trackAlbums.albumTitle;
            track.albumArtist = model.trackAlbums.albumArtists.artistName;
            
            if (model.trackiTunesUrl)
                track.iTunesUrl = [NSURL URLWithString:model.trackiTunesUrl];
            
            if (model.trackFetchDate > 0)
                track.streamExpireDate = [NSDate dateWithTimeIntervalSince1970:model.trackFetchDate];
            
            if (model.trackUrl)
                track.streamURL = [NSURL URLWithString:model.trackUrl];
            
            [playlist addTrack:track];
        }];
    }
   
    RDPlayerViewController* playerController = [[self storyboard] instantiateViewControllerWithIdentifier:@"Player"];
    playerController.playlist = playlist;
    playerController.delegate = self;
    
    [self presentViewController:playerController animated:YES completion:nil];
}



#pragma mark - UI Events

- (void)didPressAddPlaylist
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Create New Mix"
                                                         message:@"Type the name of your new Mix"
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Add", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField * textField = [alertView textFieldAtIndex:0];
    textField.placeholder = @"Mix Name goes here";
    
    RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
    [modalAlert show];
    
    if (!modalAlert.cancelled && textField.text.length > 0) {
        RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        
        RDPlaylistModel * playlist = [repository playlistModelWithName:textField.text];
        playlist.thumb = UIImagePNGRepresentation([cache.missingCoverArtImage tintColor:cache.barTintColor]);
        playlist.createDate = [[NSDate date] timeIntervalSince1970];
        [repository saveChanges];
    }
}


- (void)didPressDeletePlaylist:(UIButton *)sender
{
    RDMixlibraryViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDMixlibraryViewCell class]]) {
            cell = (RDMixlibraryViewCell *)superView;
            break;
        }
        
        superView = [superView superview];

    }while (superView);
    
    NSIndexPath * ndx = [_mixListView indexPathForCell:cell];
    RDPlaylistModel * playlist = [_repositoryController objectAtIndexPath:ndx];
    //
    // Create our alert
    //
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Delete Mix"
                                                         message:[NSString stringWithFormat:@"Are you sure you want to delete %@", playlist.name]
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Delete", nil];
    
    RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
    [modalAlert show];
    //
    // See if they pressed the Delete button
    //
    if (!modalAlert.cancelled) {
        RDMusicPlayer * player = [RDMusicPlayer sharedInstance];
        if ([playlist.name isEqualToString:player.playlist.name]) {
            [player stop];
            player.playlist = nil;
            //
            // Tell the library view screen to remove the Now Playing button
            //
            [[NSNotificationCenter defaultCenter] postNotificationName:RDMusicPlayerTrackEndedNotification object:nil];
        }
        
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        [repository deleteModel:playlist];
        [repository saveChanges];
    }
}


- (void)didPressEditPlaylist:(UIButton *)sender
{
    RDMixlibraryViewCell * cell = nil;
    UIView * superView = [sender superview];
    //
    // Get our parent cell
    //
    do {
        if ([superView isKindOfClass:[RDMixlibraryViewCell class]]) {
            cell = (RDMixlibraryViewCell *)superView;
            break;
        }
        
        superView = [superView superview];
        
    }while (superView);
    
    NSIndexPath * ndx = [_mixListView indexPathForCell:cell];
    RDPlaylistModel * playlist = [_repositoryController objectAtIndexPath:ndx];
    //
    // Create our alert
    //
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Edit Mix"
                                                         message:@"Edit the name of your Mix"
                                                        delegate:nil
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Update", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField * textField = [alertView textFieldAtIndex:0];
    textField.placeholder = playlist.name;
    
    RDAlertView * modalAlert = [[RDAlertView alloc] initWithAlert:alertView];
    [modalAlert show];
    //
    // See if they pressed the Delete button
    //
    if (!modalAlert.cancelled) {
        RDMusicRepository * repository = [RDMusicRepository sharedInstance];
        playlist.name = textField.text;
        [repository saveChanges];
    }
}

@end
