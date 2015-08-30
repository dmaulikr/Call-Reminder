//
//  TNStaticUtils.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/17/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "TNStaticUtils.h"

@implementation TNStaticUtils

+ (BOOL)cancelNotification: (UIApplication *)app :(NSString *)reminderURI
{
    NSArray *eventsArray = [app scheduledLocalNotifications];
    for (int i = 0; i < [eventsArray count]; i++)
    {
        UILocalNotification* oneEvent = [eventsArray objectAtIndex:i];
        NSDictionary *userInfoCurrent = oneEvent.userInfo;
        NSString *uid = [userInfoCurrent valueForKey:@"ReminderKey"];
        if ([uid isEqualToString:reminderURI])
        {
            [app cancelLocalNotification:oneEvent];
            return YES;
        }
    }
    return NO;
}

//+ (void)updateNotificationInApp: (UIApplication *)app ByURI: (NSString *)reminderURI WithDate: (NSDate *)newDate AndMessage: (NSString *)newMessage
//{
//    NSArray *eventsArray = [app scheduledLocalNotifications];
//    for (int i = 0; i < [eventsArray count]; i++)
//    {
//        UILocalNotification* oneEvent = [eventsArray objectAtIndex:i];
//        NSDictionary *userInfoCurrent = oneEvent.userInfo;
//        NSString *uid = [userInfoCurrent valueForKey:@"ReminderKey"];
//        if ([uid isEqualToString:reminderURI])
//        {
//            if (newMessage != NULL)
//                [oneEvent setAlertBody:newMessage];
//            if (newDate != NULL)
//                [oneEvent setFireDate:newDate];
//            
//            return YES;
//        }
//    }
//    return NO;
//}

+ (void)makeCallNotification: (UIApplication *)app Date: (NSDate *)date ToWho: (NSString *) title Message: (NSString *) message ReminderObject: (NSManagedObject *) reminderObj
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
    //[dateComponents setSecond:0];
    
    localNotification.fireDate = [calendar dateFromComponents:dateComponents];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    NSString * alertBody;
    if ([message length] == 0) {
        alertBody = [NSString stringWithFormat:[NSLocalizedString(@"CALL_MESSAGE", nil) stringByAppendingString:@" %@"],
                     title];
    } else {
        alertBody = [NSString stringWithFormat:[NSLocalizedString(@"CALL_MESSAGE", nil) stringByAppendingString:@" %@: %@"],
                     title, message];
    }
    localNotification.alertBody = alertBody;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.alertAction = NSLocalizedString(@"CALL_NOW", @"call now");
    localNotification.applicationIconBadgeNumber = 1;//[app applicationIconBadgeNumber] + 1;
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[[[reminderObj objectID] URIRepresentation] absoluteString] forKey:@"ReminderKey"];
    localNotification.userInfo = infoDict;
    [app scheduleLocalNotification:localNotification];
}

@end
