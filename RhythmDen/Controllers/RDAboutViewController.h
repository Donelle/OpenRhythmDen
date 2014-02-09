//
//  RDAboutViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 10/7/13.
//
//

#import "RDViewController.h"

@interface RDAboutViewController : RDViewController<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UITableView *contributionListView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (IBAction)didClose;

@end
