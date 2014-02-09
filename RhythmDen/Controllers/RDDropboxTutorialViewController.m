//
//  RDDropboxTutorialViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 10/11/13.
//
//

#import "RDDropboxTutorialViewController.h"
#import "RDAppPreference.h"
#import "RDMusicResourceCache.h"

#define SLIDES 3

@implementation RDDropboxTutorialViewController
{
    CGPoint _contentOffSet;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    _container.clipsToBounds = YES;
    _container.layer.cornerRadius = 10.0f;
    _container.backgroundColor = cache.lightBackColor;
    _closeButton.layer.cornerRadius = 5.0f;
    _closeButton.backgroundColor = cache.buttonBackgroundColor;
    [_closeButton setTitleColor:cache.buttonTextColor forState:UIControlStateNormal];
    
    CGSize scrollSize = _imageScrollView.bounds.size;
    
    _imageScrollView.contentSize = CGSizeMake(scrollSize.width * SLIDES, scrollSize.height);
    _imageScrollView.pagingEnabled = YES;
    _imageScrollView.bounces = NO;
    _imageScrollView.showsHorizontalScrollIndicator = NO;
    _pageControl.numberOfPages = SLIDES;
    _pageControl.currentPage = 0;
    _contentOffSet = CGPointMake(0, 0);
    //
    // Add Step 1
    //
    CGRect labelRect = CGRectMake(0, 0, 275, 113);
    UILabel * label = [[UILabel alloc] initWithFrame:labelRect];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = [UIColor darkGrayColor];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 8;
    label.text = @"You've successfully linked your Dropbox account with Rhythm Den! Next, you will need to add your music files on your computer to your Dropbox.";
    [_imageScrollView addSubview:label];
    
    CGRect imageRect = CGRectMake(0, 120, 274, 150);
    UIImageView * tutorialImage = [[UIImageView alloc] initWithFrame:imageRect];
    tutorialImage.image = [UIImage imageNamed:@"DropboxTutorial01"];
    tutorialImage.contentMode = UIViewContentModeScaleAspectFit;
    [_imageScrollView addSubview:tutorialImage];
    //
    // Add Step 2
    //
    label = [[UILabel alloc] initWithFrame:CGRectOffset(labelRect, scrollSize.width * 1, 0)];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = [UIColor darkGrayColor];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 8;
    label.text = @"On you computer, open your file manager and navigate to your Dropbox -> Apps -> RhythmDem -> Music folder. This folder is where all of your music will be stored and used by Rhythm Den.";
    [_imageScrollView addSubview:label];
    
    tutorialImage = [[UIImageView alloc] initWithFrame:CGRectOffset(imageRect, scrollSize.width * 1, 0)];
    tutorialImage.image = [UIImage imageNamed:@"DropboxTutorial02"];
    tutorialImage.contentMode = UIViewContentModeScaleAspectFit;
    [_imageScrollView addSubview:tutorialImage];
    //
    // Add Step 3
    //
    label = [[UILabel alloc] initWithFrame:CGRectOffset(labelRect, scrollSize.width * 2, 0)];
    label.font = [UIFont systemFontOfSize:15.0];
    label.textColor = [UIColor darkGrayColor];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 8;    label.text = @"Finally, copy your music into the Music Folder. Organize your music using the following format will help Rhythm Den locate and understand your music collection. MP3 (.mp3) and M4A (.m4a) music files are only supported.";
    [_imageScrollView addSubview:label];
    
    tutorialImage = [[UIImageView alloc] initWithFrame:CGRectOffset(imageRect, scrollSize.width * 2, 0)];
    tutorialImage.image = [UIImage imageNamed:@"DropboxTutorial03"];
    tutorialImage.contentMode = UIViewContentModeScaleAspectFit;
    [_imageScrollView addSubview:tutorialImage];
    
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDDropboxTutorialViewController - didReceiveMemoryWarning was called");
#endif
    if (!self.isFirstResponder) {
        _delegate = nil;
        _container = nil;
        _closeButton = nil;
        _imageScrollView = nil;
        _pageControl = nil;
        self.view = nil;
    }
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];

}

#pragma mark - UIScrollViewDelegate Protocol

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = _imageScrollView.frame.size.width;
    int page = floor((_imageScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    if (page != _pageControl.currentPage)
        _pageControl.currentPage = page;
}

#pragma mark - UI Events

- (IBAction)didPressClose
{
    //
    // Save our settings
    //
    RDAppPreference * preference = [RDAppPreference new];
    preference.shownDropboxTutorial = YES;
    //
    // Close our window
    //
    [_delegate dropboxTutorialDismissViewController:self];
}

@end
