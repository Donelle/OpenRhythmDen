//
//  BitlyURLShortener.h
//  TwitterTest
//
//  Created by Tracy Pesin on 6/20/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BitlyURLShortener;

@protocol BitlyURLShortenerDelegate <NSObject>
@optional

/* Called after all URLs in the text are either shortened, or have had shortening attempted and failed */
- (void)bitlyURLShortenerDidShortenText:(BitlyURLShortener *)shortener oldText:(NSString *)oldText text:(NSString *)text linkDictionary:(NSDictionary *)dictionary;

/* Called when each URL is successfully shortened. */ 
- (void)bitlyURLShortenerDidShortenURL:(BitlyURLShortener *)shortener longURL:(NSURL *)longURL shortURLString:(NSString *)shortURLString; 

/* This method will be called whenever shortening fails for an individual link. The bitlyURLShortenerDidShortenText: delegate method will still be called once all links
    in the text have been attempted. 
 
    Developers can choose to implement this if they need to debug problems with url shortening, 
    such as an invalid api key. */
- (void)bitlyURLShortener:(BitlyURLShortener *)shortener 
        didFailForLongURL:(NSURL *)longURL 
               statusCode:(NSInteger)statusCode
               statusText:(NSString *)statusText;
@end

@interface BitlyURLShortener : NSObject  {
    NSString *shortenedText;
    id<BitlyURLShortenerDelegate> delegate;
}

@property (nonatomic, assign) id<BitlyURLShortenerDelegate> delegate;

- (void)shortenLinksInText:(NSString *)text;
- (void)shortenURL:(NSURL *)URL;

@end
