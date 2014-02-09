//
//  TKAlertCenter.m
//  Created by Devin Ross on 9/29/10.
//
/*
 
 tapku || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "TKAlertCenter.h"
#import "UIView+TKCategory.h"
#import "TKGlobal.h"

#pragma mark - TKAlertView

@interface TKAlertView : UIView {
	CGRect _messageRect;
	NSString *_text;
	UIImage *_image;
}

- (id) init;
- (void) setMessageText:(NSString*)str;
- (void) setImage:(UIImage*)image;

@end


@implementation TKAlertView
#define PADDING 20.0

- (id) init{
	if(!(self = [super initWithFrame:CGRectMake(0, 0, 100, 100)])) return nil;
	_messageRect = CGRectInset(self.bounds, 10, 10);
	self.backgroundColor = [UIColor clearColor];
	return self;
	
}

- (void) _drawRoundRectangleInRect:(CGRect)rect withRadius:(CGFloat)radius{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	
	CGRect rrect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height );
	
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathFill);
}
- (void) drawRect:(CGRect)rect
{
	[[UIColor colorWithWhite:0 alpha:0.8] set];
	[self _drawRoundRectangleInRect:rect withRadius:10];
    
    if (_image) {
        CGRect imageRect = CGRectMake(PADDING / 2.0, PADDING / 2.0, _image.size.width, _image.size.height);
        [_image drawInRect:imageRect];
    }
    
    if (_text.length > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary * attributes = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                       NSParagraphStyleAttributeName: paragraphStyle,
                                       NSStrokeColorAttributeName : [UIColor whiteColor] };
        
        [_text drawInRect:_messageRect withAttributes:attributes];
	}
}

#pragma mark Setter Methods
- (void) adjust{
	
    CGRect rect = CGRectZero;
    //
    // Detect if we have an image
    //
    if (_image) {
        rect = CGRectMake(0, 0, _image.size.width + PADDING, _image.size.height + PADDING);
    }
    //
    // Detect if we have text
    //
    if (_text.length > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSDictionary * attributes = @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14],
                                       NSParagraphStyleAttributeName: paragraphStyle };
        
        CGRect textRect = [_text boundingRectWithSize:CGSizeMake(160,200)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];
        
        double maxHeight = rect.size.height > textRect.size.height ? rect.size.height : textRect.size.height;
        rect.size = CGSizeMake(rect.size.width + textRect.size.width + (PADDING / 2), maxHeight);
        //
        // Set the inset
        //
        _messageRect = CGRectInset(rect, rect.size.width + (PADDING / 2), 10);
    }
    
    [self setBounds:rect];
	[self setNeedsLayout];
	[self setNeedsDisplay];
	
}
- (void) setMessageText:(NSString*)str{
	_text = str;
	[self adjust];
}
- (void) setImage:(UIImage*)img{
	_image = img;
	[self adjust];
}

@end

#pragma mark - TKAlertCenter

@implementation TKAlertCenter

+ (TKAlertCenter*) defaultCenter {
	static TKAlertCenter *defaultCenter = nil;
	if (!defaultCenter) {
		defaultCenter = [[TKAlertCenter alloc] init];
	}
	return defaultCenter;
}


- (id) init{
	if(!(self=[super init])) return nil;
	
	_alerts = [[NSMutableArray alloc] init];
	_alertView = [[TKAlertView alloc] init];
	_active = NO;
	
	
	_alertFrame = [UIScreen mainScreen].applicationFrame;
	return self;
}


- (TKAlertView *)alertView
{
    return _alertView;
}


#pragma mark Show Alert Message
- (void) showAlerts{
	
	if([_alerts count] < 1) {
		_active = NO;
		return;
	}
	
	_active = YES;
	_alertView.transform = CGAffineTransformIdentity;
	_alertView.alpha = 0;
	[[UIApplication sharedApplication].keyWindow addSubview:_alertView];

    NSArray * data = [_alerts objectAtIndex:0];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( [obj isKindOfClass:[NSString class]]) {
            [_alertView setMessageText:obj];
        }
        else if ([obj isKindOfClass:[UIImage class]])
            [_alertView setImage:obj];
    }];
    
	_alertView.center = CGPointMake(_alertFrame.origin.x+_alertFrame.size.width/2, _alertFrame.origin.y+_alertFrame.size.height/2);
			
	CGRect rr = _alertView.frame;
	rr.origin.x = (int)rr.origin.x;
	rr.origin.y = (int)rr.origin.y;
	_alertView.frame = rr;
	
	UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat degrees = 0;
	if(o == UIInterfaceOrientationLandscapeLeft ) degrees = -90;
	else if(o == UIInterfaceOrientationLandscapeRight ) degrees = 90;
	else if(o == UIInterfaceOrientationPortraitUpsideDown) degrees = 180;
	_alertView.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
	_alertView.transform = CGAffineTransformScale(_alertView.transform, 2, 2);
	
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.15];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStep2)];
	_alertView.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
	_alertView.frame = CGRectIntegral(_alertView.frame);
	_alertView.alpha = 1;
	[UIView commitAnimations];
}


- (void) animationStep2
{
    __block BOOL bHasText = NO;
    NSArray * data = [_alerts objectAtIndex:0];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( [obj isKindOfClass:[NSString class]]) {
            *stop = bHasText = YES;
        }
    }];
    
	[UIView beginAnimations:nil context:nil];
    
    double duration = 1.4f;
    if (bHasText) {
        // depending on how many words are in the text
        // change the animation duration accordingly
        // avg person reads 200 words per minute
        NSArray * words = [_alerts[0][0] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        duration = MAX(((double)[words count]*60.0/200.0),1.4f);
    }
    
    [UIView setAnimationDelay:duration];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationStep3)];
	
	UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat degrees = 0;
	if(o == UIInterfaceOrientationLandscapeLeft ) degrees = -90;
	else if(o == UIInterfaceOrientationLandscapeRight ) degrees = 90;
	else if(o == UIInterfaceOrientationPortraitUpsideDown) degrees = 180;
	_alertView.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
	_alertView.transform = CGAffineTransformScale(_alertView.transform, 0.5, 0.5);
	
	_alertView.alpha = 0;
	[UIView commitAnimations];
}
- (void) animationStep3{
	
	[_alertView removeFromSuperview];
	[_alerts removeObjectAtIndex:0];
	[self showAlerts];
	
}
- (void) postAlertWithMessage:(NSString*)message image:(UIImage*)image
{
    if (message.length > 0 && image)
		[_alerts addObject:@[message,image]];
	else if(message.length > 0)
		[_alerts addObject:@[message]];
	else if(image)
		[_alerts addObject:@[image]];
    
	if(!_active) [self showAlerts];
}
- (void) postAlertWithMessage:(NSString*)message{
	[self postAlertWithMessage:message image:nil];
}


#pragma mark System Observation Changes
CGRect subtractRect(CGRect wf,CGRect kf);
CGRect subtractRect(CGRect wf,CGRect kf){
	
	
	
	if(!CGPointEqualToPoint(CGPointZero,kf.origin)){
		
		if(kf.origin.x>0) kf.size.width = kf.origin.x;
		if(kf.origin.y>0) kf.size.height = kf.origin.y;
		kf.origin = CGPointZero;
		
	}else{
		
		
		kf.origin.x = abs(kf.size.width - wf.size.width);
		kf.origin.y = abs(kf.size.height -  wf.size.height);
		
		
		if(kf.origin.x > 0){
			CGFloat temp = kf.origin.x;
			kf.origin.x = kf.size.width;
			kf.size.width = temp;
		}else if(kf.origin.y > 0){
			CGFloat temp = kf.origin.y;
			kf.origin.y = kf.size.height;
			kf.size.height = temp;
		}
		
	}
	return CGRectIntersection(wf, kf);
	
	
	
}
- (void) keyboardWillAppear:(NSNotification *)notification {
	
	NSDictionary *userInfo = [notification userInfo];
	NSValue* aValue = userInfo[UIKeyboardFrameEndUserInfoKey];
	CGRect kf = [aValue CGRectValue];
	CGRect wf = [UIScreen mainScreen].applicationFrame;
	
	[UIView beginAnimations:nil context:nil];
	_alertFrame = subtractRect(wf,kf);
	_alertView.center = CGPointMake(_alertFrame.origin.x+_alertFrame.size.width/2, _alertFrame.origin.y+_alertFrame.size.height/2);

	[UIView commitAnimations];

}
- (void) keyboardWillDisappear:(NSNotification *) notification {
	_alertFrame = [UIScreen mainScreen].applicationFrame;

}
- (void) orientationWillChange:(NSNotification *) notification {
	
	NSDictionary *userInfo = [notification userInfo];
	NSNumber *v = userInfo[UIApplicationStatusBarOrientationUserInfoKey];
	UIInterfaceOrientation o = [v intValue];
	
	
	
	
	CGFloat degrees = 0;
	if(o == UIInterfaceOrientationLandscapeLeft ) degrees = -90;
	else if(o == UIInterfaceOrientationLandscapeRight ) degrees = 90;
	else if(o == UIInterfaceOrientationPortraitUpsideDown) degrees = 180;
	
	[UIView beginAnimations:nil context:nil];
	_alertView.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
	_alertView.frame = CGRectMake((int)_alertView.frame.origin.x, (int)_alertView.frame.origin.y, (int)_alertView.frame.size.width, (int)_alertView.frame.size.height);
	[UIView commitAnimations];
	
}

@end