//
//  BitlyTweetSheetAccountSelector.m
//  BitlyLib
//
//  Created by Tracy Pesin on 7/5/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyTweetSheetAccountSelector.h"
#import "BitlyLibUtil.h"

@implementation BitlyTweetSheetAccountSelector

@synthesize accounts;
@synthesize delegate;

- (void)dealloc
{
    [accounts release];
    
    [super dealloc];
}

- (id)initWithAccounts:(NSArray *)accountsList
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.accounts = accountsList;
        self.contentSizeForViewInPopover = CGSizeMake(200.0, 150.0);
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Choose account";
    UIView *bgView = [[UIView alloc] init];
    self.tableView.backgroundView = bgView;
    [bgView release];
    self.tableView.backgroundView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    

    ACAccount *account = [self.accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = account.accountDescription; 
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
    
    NSString *lastAccountUsed = [BitlyLibUtil sharedBitlyUtil].lastAccountUsed;
    if ([lastAccountUsed isEqualToString:account.username]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate accountSelector:self didSelectAccount:[self.accounts objectAtIndex: indexPath.row]];
}

@end
