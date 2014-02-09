//
//  RDTutorialsViewController.m
//  RhythmDen
//
//  Created by Donelle Sanders on 10/18/13.
//
//

#import "RDTutorialsViewController.h"
#import "RDMusicResourceCache.h"
#import "UIImage+RhythmDen.h"
#import "RDPlayerTutorialViewController.h"
#import "RDDropboxTutorialViewController.h"

@interface RDTutorialsViewController () <RDDropboxTutorialViewDelegate, RDPlayerTutorialDelegate>

@end

@implementation RDTutorialsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //
    // Setup the title
    //
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
    title.font = [UIFont fontWithName:@"Ubuntu Condensed" size:25];
    title.textColor =  cache.labelTitleTextColor;
    title.backgroundColor = [UIColor clearColor];
    title.text = self.navigationItem.title;
    self.navigationItem.titleView = title;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"RDTutorialsViewController - didReceiveMemoryWarning was called");
#endif
    
    if (!self.isFirstResponder)
        self.view = nil;
    
    [[RDMusicResourceCache sharedInstance] clearCache];
    [super didReceiveMemoryWarning];
    
}


#pragma mark - RDDropboxTutorialViewDelegate

- (void)dropboxTutorialDismissViewController:(RDDropboxTutorialViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
    }];
}



#pragma mark - RDPlayerTutorialViewDelegate

- (void)playlerTutorialDismissViewController:(RDPlayerTutorialViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        controller.delegate = nil;
    }];
}



#pragma mark - UITableViewDataSource Protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    /* Dropbox Setup Tutorial, Player Tutorial */
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * identity = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identity];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identity];
    
    RDMusicResourceCache * cache = [RDMusicResourceCache sharedInstance];
    
    cell.backgroundColor = cache.darkBackColor;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
    cell.textLabel.textColor = cache.barTintColor;
    cell.textLabel.text = indexPath.row == 0 ? @"Dropbox Setup Instructions" : @"Player Instruction";
    cell.imageView.image = [[UIImage imageNamed:@"help"] tintColor:cache.barTintColor];
    cell.layer.cornerRadius = 5.0f;
    cell.clipsToBounds = YES;

    UIView * selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = cache.buttonBackgroundColor;
    cell.selectedBackgroundView = selectionView;
    
    return cell;
}


#pragma mark - UITableViewDelegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            RDDropboxTutorialViewController * dropboxTutorialController = [[self storyboard] instantiateViewControllerWithIdentifier:@"DropboxTutorial"];
            dropboxTutorialController.delegate = self;
            [self presentViewController:dropboxTutorialController animated:YES completion:nil];
            break;
        }
            
        case 1:
        {
            RDPlayerTutorialViewController * playerTutorialController = [[self storyboard] instantiateViewControllerWithIdentifier:@"PlayerTutorial"];
            playerTutorialController.delegate = self;
            [self presentViewController:playerTutorialController animated:YES completion:nil];
            break;
        }
    }
}


@end
