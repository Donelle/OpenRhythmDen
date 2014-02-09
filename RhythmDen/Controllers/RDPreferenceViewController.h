//
//  RDPreferenceViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 2/10/13.
//
//

#import "RDViewController.h"

@interface RDPreferenceViewController : RDViewController<UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UITableView * preferenceView;
@property (weak, nonatomic) IBOutlet UILabel * statusLabel;
@property (weak, nonatomic) IBOutlet UIView * refreshView;
@property (weak, nonatomic) IBOutlet UILabel * refreshStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton * refreshLibraryButton;

- (IBAction)didPressSyncronizeLibrary:(id)sender;

@end
