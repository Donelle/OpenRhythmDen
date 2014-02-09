//
//  RDAlertView.h
//  RhythmDen
//
//  Created by Donelle Sanders on 10/3/13.
//
//

#import <UIKit/UIKit.h>

@interface RDAlertView : NSObject<UIAlertViewDelegate>
@property (readonly, nonatomic) BOOL cancelled;

- (id)initWithAlert:(UIAlertView *)alertView;
- (void)show;

@end
