//
//  Reminder.h
//  Call Reminder
//
//  Created by Тимур Насыров on 24.01.14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Reminder : NSManagedObject

@property (nonatomic, retain) NSDate * alarm;
@property (nonatomic, retain) NSString * notification;
@property (nonatomic, retain) NSNumber * pendingCall;
@property (nonatomic, retain) NSString * t_dateName;
@property (nonatomic, retain) NSManagedObject *number;

@end
