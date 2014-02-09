//
//  BitlyTweetSheetAccountSelector.h
//  BitlyLib
//
//  Created by Tracy Pesin on 7/5/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>

@class BitlyTweetSheetAccountSelector;

@protocol BitlyTweetSheetAccountSelectorDelegate <NSObject>
@required
- (void)accountSelector:(BitlyTweetSheetAccountSelector *)accountSelector didSelectAccount:(ACAccount *)account;
@end

@interface BitlyTweetSheetAccountSelector : UITableViewController {
    NSArray *accounts;
    id<BitlyTweetSheetAccountSelectorDelegate> delegate;
}

@property (nonatomic, retain) NSArray *accounts;

@property (nonatomic, assign) id<BitlyTweetSheetAccountSelectorDelegate> delegate;

- (id)initWithAccounts:(NSArray *)accountsList;

@end
