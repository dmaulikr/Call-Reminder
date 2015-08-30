//
//  TNStaticUtils.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/17/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TNStaticUtils : NSObject

+ (BOOL)cancelNotification: (UIApplication *)app :(NSString *)reminderURI;
//+ (BOOL)updateNotificationInApp: (UIApplication *)app ByURI: (NSString *)reminderURI WithDate: (NSDate *)newDate AndMessage: (NSString *)newMessage;
+ (void)makeCallNotification: (UIApplication *)app Date: (NSDate *)date ToWho: (NSString *) title Message: (NSString *) message ReminderObject: (NSManagedObject *) reminderObj;

@end
