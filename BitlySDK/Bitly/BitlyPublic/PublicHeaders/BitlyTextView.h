//
//  BitlyTextView.h
//  BitlyLib
//
//  Created by Tracy Pesin on 7/19/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BitlyURLShortener.h"

@class BitlyTextView;

@protocol BitlyTextViewDelegate <NSObject, UITextViewDelegate>
@optional
- (void)bitlyTextView:(BitlyTextView *)textView 
      didShortenLinks:(NSDictionary *)linkDictionary 
              oldText:(NSString *)oldText 
                 text:(NSString *)text;

- (void)bitlyTextView:(BitlyTextView *)textView textDidChange:(NSString *)text;

@end


@interface BitlyTextView : UIView <BitlyURLShortenerDelegate, UITextViewDelegate>

@property (nonatomic, retain) BitlyURLShortener *shortener;
@property (nonatomic, retain) UITextView *textView;

@property (nonatomic, assign) NSString *text;

@property (nonatomic, assign) IBOutlet id<BitlyTextViewDelegate> delegate;

- (void)addURL:(NSURL *)url;

- (void)shortenLinks;

- (BOOL)becomeFirstResponder;

@end
