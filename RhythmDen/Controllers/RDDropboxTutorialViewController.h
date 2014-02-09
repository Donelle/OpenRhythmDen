//
//  RDDropboxTutorialViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders on 10/11/13.
//
//

#import "RDViewController.h"

@class RDDropboxTutorialViewController;
@protocol RDDropboxTutorialViewDelegate <NSObject>
- (void)dropboxTutorialDismissViewController:(RDDropboxTutorialViewController *)controller;

@end

@interface RDDropboxTutorialViewController : RDViewController<UIScrollViewDelegate>

@property (weak, nonatomic) id<RDDropboxTutorialViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIScrollView *imageScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;


- (IBAction)didPressClose;

@end
