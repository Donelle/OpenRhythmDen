//
//  RDPlayerViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/17/13.
//
//

#import "RDViewController.h"

@class  RDMusicPlaylist, RDPlayerViewController;
@protocol RDPlayerViewControllerDelegate <NSObject>

- (void)playerViewControllerDidClose:(RDPlayerViewController *)controller;

@end

@interface RDPlayerViewController : RDViewController<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,UIGestureRecognizerDelegate,UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) RDMusicPlaylist * playlist;
@property (weak, nonatomic) id<RDPlayerViewControllerDelegate> delegate;
//
// UI Controls
//
@property (weak, nonatomic) IBOutlet UITableView *trackListView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *infoAlbumTitle;
@property (weak, nonatomic) IBOutlet UILabel *infoArtist;
@property (weak, nonatomic) IBOutlet UILabel *infoTracks;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIImageView *playerArtworkView;
@property (weak, nonatomic) IBOutlet UIImageView *playerStatusView;
@property (weak, nonatomic) IBOutlet UILabel *playerTrackLength;
@property (weak, nonatomic) IBOutlet UILabel *playerTrackName;
@property (weak, nonatomic) IBOutlet UILabel *playerAlbumName;
@property (weak, nonatomic) IBOutlet UILabel *playerStatus;
@property (weak, nonatomic) IBOutlet UIImageView *playerRepeatView;
@property (weak, nonatomic) IBOutlet UIButton *verifyButton;

- (IBAction)didPressClose;
- (IBAction)didPressVerifyAlbum;

@end
