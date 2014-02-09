//
//  RDDropboxSyncMetaModel.h
//  RhythmDen
//
//  Created by Donelle Sanders on 12/5/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RDDropboxSyncMetaModel : NSManagedObject

@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * locationHash;

@end
