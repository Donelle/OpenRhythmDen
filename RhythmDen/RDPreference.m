//
//  RDPreference.m
//  RhythmDen
//
//  Created by Donelle Sanders on 1/8/12.
//  Copyright (c) 2012 The Potter's Den, Inc. All rights reserved.
//

#import "RDPreference.h"
#import "NSObject+RhythmDen.h"



@interface RDCloudPreference : NSObject

@property (readonly, nonatomic) BOOL cloudEnabled;

- (void)write:(id)value forKey:(NSString *)name;
- (id)read:(NSString *)name;
- (void)deleteKey:(NSString *)name;

+ (RDCloudPreference *) sharedInstance;

@end

@implementation RDCloudPreference
{
    BOOL _isCloudEnabled;
}

- (id)init
{
    if (self = [super init]) {
        if ([[NSFileManager defaultManager] ubiquityIdentityToken]) {
           [self performBlockInBackground:^{
                NSURL * fileURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
                _isCloudEnabled = fileURL != nil;
           }];
        }
    }
    return  self;
}

- (BOOL)cloudEnabled
{
    return _isCloudEnabled;
}


- (void)write:(id)value forKey:(NSString *)name
{
    [[NSUbiquitousKeyValueStore defaultStore] setObject:value forKey:name];
}

- (id)read:(NSString *)name
{
    return [[NSUbiquitousKeyValueStore defaultStore] objectForKey:name];
}

- (void)deleteKey:(NSString *)name
{
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:name];
}

+ (RDCloudPreference *)sharedInstance
{
    static RDCloudPreference * preference = nil;
    
    if (preference == nil)
        preference = [[RDCloudPreference alloc] init];
    
    return preference;
}

@end


@implementation RDPreference
{
    RDCloudPreference * _cloudPreference;
}

-(id)init
{
    if (self = [super init]) {
        _cloudPreference = [RDCloudPreference sharedInstance];
    }
    
    return self;
}


-(id)read:(NSString *)name
{
    return [self read:name fromCloud:NO];
}

-(id)read:(NSString *)name fromCloud:(BOOL)willRead
{
    if (_cloudPreference.cloudEnabled && willRead)
        return [_cloudPreference read:name];
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:name];
}

-(void)write:(id)value forKey:(NSString *)name
{
    [self write:value forKey:name toCloud:NO];
}

-(void)write:(id)value forKey:(NSString *)name toCloud:(BOOL)willWrite
{
    if (_cloudPreference.cloudEnabled && willWrite) {
        [_cloudPreference write:value forKey:name];
    } 
    else {
       [[NSUserDefaults standardUserDefaults] setValue:value forKey:name];
    }
}

-(void)deleteKey:(NSString *)name
{
    [self deleteKey:name fromCloud:NO];
}

-(void)deleteKey:(NSString *)name fromCloud:(BOOL)willDelete
{
    if (_cloudPreference.cloudEnabled && willDelete) {
        [_cloudPreference deleteKey:name];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:name];
    }
}


@end
