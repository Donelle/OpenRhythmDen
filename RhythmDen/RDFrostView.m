//
//  RDFrostView.m
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 11/6/13.
//
//

#import "RDFrostView.h"
#import "GPUImageSDK.h"
#import "UIImage+RhythmDen.h"
#import <Accelerate/Accelerate.h>

@implementation RDFrostView

- (id)initWithFrame:(CGRect)frame
{
    if (self =[super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)setBlurImage:(UIImage *)blurImage
{
    _blurImage = blurImage;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    GPUImageiOSBlurFilter *blurFilter = [GPUImageiOSBlurFilter new];
    blurFilter.blurRadiusInPixels = 13.0f;
    UIImage *snapshotImage = [blurFilter imageByFilteringImage:self.blurImage];
    
    CGSize newSize = (CGSize) { rect.size.width, rect.size.height * 4 };
    snapshotImage = [snapshotImage shrink:newSize];
    [[snapshotImage crop:rect] drawInRect:rect];
    
    UIColor * transWhite = [UIColor colorWithWhite:1.0 alpha:1.0];
    [transWhite setFill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    //CGContextSetAlpha(context, 0.5f);
    CGContextFillRect(context, rect);
}

@end
