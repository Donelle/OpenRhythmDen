//
//  MainViewController.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/27/11.
//  Copyright (c) 2011 The Potter's Den, Inc. All rights reserved.
//

#import "RDViewController.h"
#import <CoreData/CoreData.h>


@interface RDLibraryViewController : RDViewController<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *libraryView;
@property (weak, nonatomic) IBOutlet UISearchBar *librarySearchBar;


@end
