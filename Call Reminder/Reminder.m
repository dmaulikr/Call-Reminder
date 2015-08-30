//
//  Reminder.m
//  Call Reminder
//
//  Created by Тимур Насыров on 24.01.14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "Reminder.h"
#import "TNStaticUtils.h"


@implementation Reminder

@dynamic alarm;
@dynamic notification;
@dynamic pendingCall;
@dynamic t_dateName;
@dynamic number;

// вычисляем как будет выглядеть дата в заголовках секций в таблице отображения напоминаний
- (NSString *) t_dateName
{
    [self willAccessValueForKey:@"t_dateName"];
    
    NSString *dateName;
    if ([self.alarm compare: [NSDate date]] == NSOrderedAscending || [self.alarm compare: [NSDate date]] == NSOrderedSame)
    {
        dateName = NSLocalizedString(@"REMIDNDERLIST_EXPIRED", @"Expired");
    }
    else
    {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *alarmDay = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.alarm];
        NSDateComponents *todayDay = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
        
        if ([alarmDay isEqual:todayDay])
        {
            dateName = NSLocalizedString(@"TODAY", @"Today");
        }
        else
        {
            NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
            [offsetComponents setDay:1];
            NSDate *nextDay = [calendar dateByAddingComponents:offsetComponents toDate:[calendar dateFromComponents:todayDay] options:0];
            
            if ([[calendar dateFromComponents:alarmDay] isEqual:nextDay])
            {
                dateName = NSLocalizedString(@"TOMORROW", @"Tomorrow");
            }
            else
            {
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setDateStyle:NSDateFormatterLongStyle];
                dateName = [df stringFromDate:[self alarm]];
            }
        }
    }
    
    [self didAccessValueForKey:@"t_dateName"];
    return dateName;
}

- (void)willSave
{
    if (self.isInserted) return;
    
    UIApplication * app = [UIApplication sharedApplication];
    // если напоминание удаляется из CoreData - удаляем напоминание и из notification center
    if (self.isDeleted) {
        [TNStaticUtils cancelNotification:app :[[[self objectID] URIRepresentation] absoluteString]];
    }
    // если напоминание редактируется - меняем напоминание и в notification center
    else if (self.isUpdated) {
        // !!!:TODO check that ONLY pendingCall has changed
        NSDictionary * changedVals = [self changedValues];
        if (changedVals.count == 1 && changedVals[@"pendingCall"] != NULL) return;
        
        // !!!:TODO check if date is old - don't cancel notif
        NSDate * oldDate = [self changedValuesForCurrentEvent][@"alarm"];
        //if ([oldDate compare: [NSDate date]] == NSOrderedAscending || ![TNStaticUtils updateNotificationInApp:app ByURI:[[[self objectID] URIRepresentation] absoluteString] WithDate:self.alarm AndMessage:self.notification]) {
        //if ([oldDate compare: [NSDate date]] == NSOrderedDescending)
        [TNStaticUtils cancelNotification:app :[[[self objectID] URIRepresentation] absoluteString]];
        NSString *toWho = [self.number valueForKey:@"title"];
        if (![toWho length]) toWho = [self.number valueForKey:@"number"];
        [TNStaticUtils makeCallNotification:app Date:self.alarm ToWho:toWho Message:self.notification ReminderObject:self];
        
    }
}

- (void)didSave
{
    // создаем напоминание в notification center
    if (self.isInserted) {
        NSString *toWho = [self.number valueForKey:@"title"];
        if (![toWho length]) toWho = [self.number valueForKey:@"number"];
        [TNStaticUtils makeCallNotification:[UIApplication sharedApplication] Date:self.alarm ToWho:toWho Message:self.notification ReminderObject:self];
    }
}

@end
