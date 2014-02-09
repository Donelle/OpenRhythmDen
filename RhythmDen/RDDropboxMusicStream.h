//
//  RDDropboxMusicStream.h
//  Dropbox
//
//  Created by Donelle Sanders on 2/5/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RDDropboxMusicStreamDelegate <NSObject>
- (void)requestFailed:(NSError *)error;

@optional
- (void)didReceiveMedia:(id)response;
- (void)didReceiveMediaUnchanged:(id)response;
- (void)retrieveMediaCompleted:(id)response;
- (void)retrieveMediaCancelled:(id)response;

@end

@interface RDDropboxMusicStream : NSObject

@property (weak, nonatomic) id<RDDropboxMusicStreamDelegate> delegate;

- (id)initWithUser:(NSString *)userId;
- (void)retrieveMediaFor:(NSDictionary *)locations;
- (void)retrieveStreamableMediaURLFor:(NSString *)location;
- (void)cancelRequest;

@end
