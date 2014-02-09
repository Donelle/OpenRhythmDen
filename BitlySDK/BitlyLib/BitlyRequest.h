//
//  NewsMeBitlyRequest.h
//  NewsMe
//
//  Created by Tracy Pesin on 1/5/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BitlyRequest;

@protocol BitlyRequestDelegate
@required
- (void)bitlyRequestSucceeded:(BitlyRequest *)bitlyRequest 
                   forLongURL:(NSURL *)longURL 
           withShortURLString:(NSString *)shortURLString 
                 responseData:(NSDictionary *)data;

- (void)bitlyRequest:(BitlyRequest *)bitlyRequest failedForLongURL:(NSURL *)url 
          statusCode:(NSInteger)statusCode
          statusText:(NSString *)statusText;
@end


@interface BitlyRequest : NSObject {
}

@property(nonatomic, assign) id<BitlyRequestDelegate>delegate;
@property(nonatomic, retain) NSURL *longURL;

- (BitlyRequest *)initWithURL:(NSURL *)url;
- (void)start;

@end
