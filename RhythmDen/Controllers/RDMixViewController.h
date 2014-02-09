//
//  RDMixViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders on 9/15/13.
//
//

#import "RDViewController.h"

@interface RDMixViewController : RDViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView * mixListView;

@end
