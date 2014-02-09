//
//  RDPlayerTutorialViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 10/11/13.
//
//

#import "RDViewController.h"

@class RDPlayerTutorialViewController;
@protocol RDPlayerTutorialDelegate <NSObject>

- (void)playlerTutorialDismissViewController:(RDPlayerTutorialViewController *)controller;

@end

@interface RDPlayerTutorialViewController : RDViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<RDPlayerTutorialDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *instructionTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *trackTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *doneImageView;
@property (weak, nonatomic) IBOutlet UILabel *doneLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

- (IBAction)didPressClose;
- (IBAction)didPressNext;

@end
