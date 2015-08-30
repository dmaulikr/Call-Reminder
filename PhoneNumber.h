//
//  Call Reminder.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/1/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Reminder;

@interface PhoneNumber : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * t_firstLetter;
@property (nonatomic, retain) NSNumber * temp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Reminder *reminder;

@end
