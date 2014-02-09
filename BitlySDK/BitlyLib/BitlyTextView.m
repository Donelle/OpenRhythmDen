//
//  BitlyTextView.m
//  BitlyLib
//
//  Created by Tracy Pesin on 7/19/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import "BitlyTextView.h"
#import <QuartzCore/QuartzCore.h>
#import "BitlyDebug.h"

@interface BitlyTextView ()

- (void)baseInit;

@end



@implementation BitlyTextView

@synthesize shortener;
@synthesize textView;
@synthesize text;
@synthesize delegate;

- (void)dealloc {
    
    self.delegate = nil;
    
    self.shortener.delegate = nil;
    [shortener release];
    
    self.textView.delegate = nil;
    [textView release];
    
    [super dealloc];
}

- (void)baseInit {
    
    UITextView *tv = [[UITextView alloc] initWithFrame:self.bounds];
    self.textView = tv;
    [tv release];
    [self addSubview:self.textView];
    self.textView.delegate = self;
    
    self.textView.layer.borderColor = [[UIColor grayColor] CGColor];
	self.textView.layer.borderWidth = 1.0;
	self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.returnKeyType = UIReturnKeyDone;
    
    self.textView.font = [UIFont fontWithName:@"Helvetica" size:15.0];
    
    BitlyURLShortener *us = [[BitlyURLShortener alloc] init];
    self.shortener = us;
    [us release];
    self.shortener.delegate = self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self baseInit];
    }
    return self;
}

- (void)setFrame:(CGRect)aFrame {
    [super setFrame:aFrame];
    self.textView.frame = self.bounds; 
}

#pragma mark -
#pragma mark properties
- (void)setText:(NSString *)theText {
    self.textView.text = theText;
    [self shortenLinks];
}

- (NSString *)text {
    return self.textView.text;
}

- (BOOL)becomeFirstResponder {
    return [self.textView becomeFirstResponder];
}

#pragma mark -

- (void)addURL:(NSURL *)url  {
    if (self.textView.text.length) {
        self.textView.text = [NSString stringWithFormat:@"%@ %@", self.textView.text, [url absoluteString]];
    } else {
        self.textView.text = [url absoluteString];
    }
    
    [self.shortener shortenLinksInText:self.textView.text];
}

- (void)shortenLinks {
    [self.shortener shortenLinksInText:self.textView.text];
}

#pragma mark BitlyURLShortenerDelegate
- (void)bitlyURLShortenerDidShortenText:(BitlyURLShortener *)shortener 
                                oldText:(NSString *)oldText
                                   text:(NSString *)currentText 
                         linkDictionary:(NSDictionary *)dictionary {
    //Need to replace the links now in case the text changed since being passed to the shortener
    for (NSString *oldLink in [dictionary allKeys]) {
        self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:oldLink withString:[dictionary objectForKey:oldLink]];
    }
    if ([self.delegate respondsToSelector:@selector(bitlyTextView:didShortenLinks:oldText:text:)]) {
        [self.delegate bitlyTextView:self didShortenLinks:dictionary oldText:oldText text:currentText];
    }
}

- (void)bitlyURLShortener:(BitlyURLShortener *)shortener 
        didFailForLongURL:(NSURL *)longURL 
               statusCode:(NSInteger)statusCode
               statusText:(NSString *)statusText {
    BitlyLog(@"BitlyTextView got link shortening error for url: %@", longURL);
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)atextView {
    if ([self.delegate respondsToSelector:@selector(bitlyTextView:textDidChange:)]) {
        [self.delegate bitlyTextView:self textDidChange:atextView.text];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self shortenLinks];
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)replacementText {
    if ([replacementText isEqualToString:@"\n"]) {
        [self.textView resignFirstResponder];
        return NO;
        
    } else if ([replacementText isEqualToString:@" "] || replacementText.length > 10 /*possible paste event*/ ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shortenLinks];
        });
    }
    return YES;
}


@end
