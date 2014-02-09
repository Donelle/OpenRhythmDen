//
//  RDPlayerTutorialViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 10/11/13.
//
//

#import "RDPlayerTutorialViewController.h"
#import "RDAppPreference.h"
#import "RDMusicResourceCache.h"
#import "NSObject+RhythmDen.h"
#import "UIImage+RhythmDen.h"
#import "UIDevice+RhythmDen.h"
#import <QuartzCore/QuartzCore.h>

@interface RDPlayerTutorialViewController ()

- (void)startTimer;
- (void)stopTimer;
- (void)pauseTimer;
- (void)updateTrackTime:(NSTimer *)timer;

@end

#define SCRUBBER_VIEW_TAG 100

@implementation RDPlayerTutorialViewController
{
    int _stepIndex;
    NSTimer * _timer;
    NSUInteger _duration;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    //
    // Setup the UI
    //
    self.containerView.clipsToBounds = YES;
    self.containerView.layer.cornerRadius = 10.0f;
    self.containerView.backgroundColor = cache.lightBackColor;
    self.playerView.layer.opacity = 0.0f;
    self.nextButton.layer.cornerRadius = 5.0f;
    self.doneLabel.layer.opacity = 0.0f;
    self.doneImageView.layer.opacity = 0.0f;
    self.doneImageView.image = [[UIImage imageNamed:@"check"] tintColor:[UIColor darkTextColor]];
    self.closeButton.backgroundColor = cache.buttonBackgroundColor;
    self.closeButton.layer.cornerRadius = 5.0f;
    [self.closeButton setTitleColor:cache.buttonTextColor forState:UIControlStateNormal];
    //
    // Setup the floating duration view
    //
    CGRect viewRect = self.view.frame;
    UIView * scrubbleView = [[UIView alloc] initWithFrame:CGRectMake((viewRect.size.width / 2) - 25, self.playerView.frame.origin.y - 25, 50, 25)];
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
    timeLabel.text = @"2:10";
    [scrubbleView addSubview:timeLabel];

    //
    // Setup gestures gesture
    //
    UIView * gestureView = [[UIView alloc] initWithFrame:CGRectOffset(self.playerView.bounds, 0, 0)];
    [self.playerView insertSubview:gestureView atIndex:self.playerView.subviews.count - 1];
    
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPlayerPlayPause)];
    tapGesture.delegate = self;
    [gestureView addGestureRecognizer:tapGesture];
    
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
    // Initialize to first step
    //
    _stepIndex = 0;
    
    if (![self isiPhone5])
        self.closeButton.frame = CGRectOffset(self.closeButton.frame, 0, -70);
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDPlayerTutorialViewController - didReceiveMemoryWarning was called");
#endif

    if (!self.isFirstResponder) {
        _statusImageView = nil;
        _statusLabel = nil;
        _trackLabel = nil;
        _instructionTitleLabel = nil;
        _instructionLabel = nil;
        _playerView = nil;
        _containerView = nil;
        _nextButton = nil;
        _closeButton = nil;
        self.view = nil;
    }
    
    [super didReceiveMemoryWarning];
}


- (void)startTimer
{
    _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateTrackTime:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)pauseTimer
{
    [_timer invalidate];
}

- (void)updateTrackTime:(NSTimer *)timer
{
    _duration += 1;
    NSUInteger dTotalSeconds = (60 * 4) - _duration;
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
    _trackTimeLabel.text = [NSString stringWithFormat:@"-%02i:%02i", dMinutes, dSeconds];
    
    if (dTotalSeconds <= 0)
        [self stopTimer];
}

- (void)stopTimer
{
    _duration = 1;
    [_timer invalidate];
}


- (BOOL)isiPhone5 {
    
    NSString *deviceType = [[UIDevice currentDevice] platform];
    NSRange iPhone5 = [deviceType rangeOfString:@"iPhone5" options:NSCaseInsensitiveSearch];
    NSRange iPod5 = [deviceType rangeOfString:@"iPod5" options:NSCaseInsensitiveSearch];
    return (iPhone5.location == 0 || iPod5.location == 0);
}

#pragma mark - UIGestureRecognizerDelegate Protocol

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



#pragma mark - UI Events


- (void)didTapPlayerPlayPause
{
    if (_stepIndex == 2) {
        if (![self.statusLabel.text isEqualToString:@"Pause"]) {
            self.statusLabel.text = @"Pause";
            self.statusImageView.image = [UIImage imageNamed:@"pause"];
            [self pauseTimer];
        }
        else {
            self.statusLabel.text = @"Now Playing";
            self.statusImageView.image = [UIImage imageNamed:@"play"];
            [self startTimer];
        }
    }
}

- (void)didSwipePlayerNextPrev:(UIGestureRecognizer *)gesture
{
    static NSUInteger trackNum = 1;
    if (_stepIndex == 3) {
        UISwipeGestureRecognizer * swipeGesture = (UISwipeGestureRecognizer *) gesture;
        
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionLeft || swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            
            if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
                trackNum -= 1;
                if (trackNum == 0) trackNum = 1;
                self.trackLabel.text = [NSString stringWithFormat:@"Track %.2d", trackNum];
            } else {
                self.trackLabel.text = [NSString stringWithFormat:@"Track %.2d", ++trackNum];
            }
            
            self.statusLabel.text = [NSString stringWithFormat:@"Loading Track %.2d", trackNum];
            self.statusImageView.image = [UIImage imageNamed:@"sync"];
            self.trackTimeLabel.hidden = YES;
            [self.statusImageView.layer removeAllAnimations];
            [self stopTimer];
            //
            // Start animation
            //
            CATransform3D rotationTransform = CATransform3DMakeRotation(2.0f * M_PI, 0, 0, 1.0);
            CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
            animation.toValue = [NSValue valueWithCATransform3D:rotationTransform];
            animation.duration = 1.5f;
            animation.cumulative = YES;
            animation.repeatCount = 100.0f;
            [self.statusImageView.layer addAnimation:animation forKey:nil];
            
            [self performBlock:^{
                [self.statusImageView.layer removeAllAnimations];
                self.statusLabel.text = @"Now Playing";
                self.statusImageView.image = [UIImage imageNamed:@"play"];
                self.trackTimeLabel.hidden = NO;
                [self startTimer];
            } afterDelay:2.0];
        }
    }
}


- (void)didLongSwipePlayer:(UIGestureRecognizer *)gesture
{
    static CGPoint swipePoint;
    
    if (_stepIndex == 4) {
        NSUInteger duration = 4 * 1000;
        
        if(gesture.state == UIGestureRecognizerStateBegan)
        {
            NSUInteger dMinutes = floor(_duration % 3600 / 60);
            NSUInteger dSeconds = floor(_duration % 3600 % 60);
            NSString * text = [NSString stringWithFormat:@"%02i:%02i", dMinutes, dSeconds];
            
            UIView * view = [self.view viewWithTag:SCRUBBER_VIEW_TAG];
            view.layer.opacity = 0;
            view.layer.hidden = NO;
            view.frame = CGRectMake((self.view.frame.size.width / 2) - 25, self.playerView.frame.origin.y - 25, 50, 25);
            
            UILabel * time = [[view subviews] objectAtIndex:0];
            time.text = text;
            
            swipePoint = [gesture locationInView:_playerView];
            
            [UIView animateWithDuration:0.3
                             animations:^{
                                 view.layer.opacity = 1.0f;
                             }];
        }
        else if(gesture.state == UIGestureRecognizerStateChanged)
        {
            CGPoint currentPoint = [gesture locationInView:_playerView];
            if (currentPoint.x < swipePoint.x) {
                NSUInteger diff = swipePoint.x - currentPoint.x;
                _duration -= diff;
                //
                // If we are greater than durations default to zero
                //
                if (_duration > duration)
                    _duration = 0;
                
            } else {
                NSUInteger diff = currentPoint.x - swipePoint.x;
                _duration += diff;
                //
                // If we are greater than durations default to duration
                //
                if (_duration > duration)
                    _duration = duration;
            }
            
            
            NSUInteger dMinutes = floor(_duration % 3600 / 60);
            NSUInteger dSeconds = floor(_duration % 3600 % 60);
            
            UIView * view = [self.view viewWithTag:SCRUBBER_VIEW_TAG];
            UILabel * time = [[view subviews] objectAtIndex:0];
            time.text = [NSString stringWithFormat:@"%02i:%02i", dMinutes, dSeconds];
            
            NSUInteger dTotalSeconds = (60 * 4) - _duration;
            dMinutes = floor(dTotalSeconds % 3600 / 60);
            dSeconds = floor(dTotalSeconds % 3600 % 60);
            self.trackTimeLabel.text = [NSString stringWithFormat:@"-%02i:%02i", dMinutes, dSeconds];
            
            swipePoint = currentPoint;
            
        }
        else if(gesture.state == UIGestureRecognizerStateEnded)
        {
        
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
    // Reset everything
    //
    _stepIndex = 0;
    [self stopTimer];
    self.instructionTitleLabel.text = @"Player Instructions";
    self.instructionLabel.text = @"The following instructions will assist you with using the player.";
    self.doneImageView.layer.opacity = 0.0f;
    self.playerView.layer.opacity = 0.0f;
    self.doneLabel.layer.opacity = 0.0f;
    self.nextButton.layer.opacity = 1.0f;
    [self.nextButton setTitle:@"Get Started" forState:UIControlStateNormal];
    //
    // Save our settings
    //
    RDAppPreference * preference = [RDAppPreference new];
    preference.shownPlayerTutorial = YES;
    //
    // Close our window
    //
    [_delegate playlerTutorialDismissViewController:self];
}

- (IBAction)didPressNext
{
    _stepIndex += 1;
    switch (_stepIndex) {
        case 1:
        {
            [UIView animateKeyframesWithDuration:1.0f delay:0 options:0 animations:^{
                self.playerView.layer.opacity = 1.0f;
                self.instructionTitleLabel.text = @"Player";
                self.instructionLabel.text = @"This area represents the player, it responds to finger gestures to control the track being played.";
                [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
            } completion:nil];
            break;
        }
        case 2:
        {
            self.instructionTitleLabel.text = @"Play/Pause Track";
            self.instructionLabel.text = @"Tap anywhere on the player to change the track state from play to pause and vice versa.";
            [self startTimer];
            break;
        }
            
        case 3:
        {
            [self stopTimer];
            self.instructionTitleLabel.text = @"Play Previous/Next Track";
            self.instructionLabel.text = @"Swipe from right to left on the player to play the next track. Swipe from left to right to play the previous track.";
            self.statusLabel.text = @"Now Playing";
            self.trackTimeLabel.text = @"-04:00";
            self.statusImageView.image = [UIImage imageNamed:@"play"];
            break;
        }
            
        case 4:
        {
            [self stopTimer];
            self.instructionTitleLabel.text = @"Seek within Track";
            self.instructionLabel.text = @"Press down anywhere on the player until you see a floating bubble, then slide your finger left to move to the beginning of the track. Slide your finger to the right to move to the end of the track.";
            self.statusLabel.text = @"Now Playing";
            self.trackTimeLabel.text = @"-04:00";
            self.statusImageView.image = [UIImage imageNamed:@"play"];
            self.trackTimeLabel.hidden = NO;
            break;
        }
            
        default:
        {
            [UIView animateKeyframesWithDuration:0.5f delay:0 options:0 animations:^{
                self.instructionTitleLabel.text = @"Enjoy your Music";
                self.instructionLabel.text = @"This concludes the tutorial. You can access this tutorial again by clicking the Tutorials button in the Settings area.";
                self.nextButton.layer.opacity = 0.0f;
                self.playerView.layer.opacity = 0.0f;
                self.doneImageView.layer.opacity = 1.0f;
                self.doneLabel.layer.opacity = 1.0f;
            } completion:nil];
            break;
        }
    }
        
}

@end
