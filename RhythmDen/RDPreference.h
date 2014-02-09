//
//  RDPreference.h
//  RhythmDen
//
//  Created by Donelle Sanders on 1/8/12.
//  Copyright (c) 2012 The Potter's Den. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDPreference : NSObject 

- (void)write:(id)value forKey:(NSString *)name;
- (void)write:(id)value forKey:(NSString *)name toCloud:(BOOL)willWrite;
- (id)read:(NSString *)name;
- (id)read:(NSString *)name fromCloud:(BOOL)willRead;
- (void)deleteKey:(NSString *)name;
- (void)deleteKey:(NSString *)name fromCloud:(BOOL)willDelete;

@end
