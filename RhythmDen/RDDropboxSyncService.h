//
//  RDDropboxSyncService.h
//  RhythmDen
//
//  Created by Donelle Sanders Jr on 1/16/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _RDDropboxSyncStatus
{
    RDDropboxSyncStatusNone = 0,
    RDDropboxSyncStatusStarted = 1,
    RDDropboxSyncStatusFailed = 2,
    RDDropboxSyncStatusCancelled = 3,
    RDDropboxSyncStatusCompleted = 4
}RDDropboxSyncStatus;


@protocol RDDropboxSyncServiceRequestDelegate <NSObject>
-(void)dropboxSyncRequestCompleted:(id)context;
-(void)dropboxSyncRequestFailed:(NSError *)error;

@optional
-(void)dropboxSyncRequestStatus:(RDDropboxSyncStatus)status withContext:(id)context;
@end


@interface RDDropboxSyncService : NSOperation

@property (weak, nonatomic) id<RDDropboxSyncServiceRequestDelegate> delegate;
@property (copy, nonatomic) NSString * startLocation;

@end


