//
//  ENReminderCell.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/4/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "ENReminderCell.h"

@implementation ENReminderCell

- (void)awakeFromNib
{
    // Initialization code
    editMode = YES;
    initFieldWidth = _fieldMessage.bounds.size.width;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/*
- (void) setEditMode: (BOOL)mode aninated: (BOOL)animated
{
    editMode = mode;
    if (mode) {
        _labelDate.hidden = YES;
        [_fieldMessage setBounds:CGRectMake(_fieldMessage.bounds.origin.x, _fieldMessage.bounds.origin.y, initFieldWidth, _fieldMessage.bounds.size.height)];
        [_fieldMessage setTextColor:[UIColor blackColor]];
    }
    else {
        _labelDate.hidden = NO;
        [_fieldMessage setBounds:CGRectMake(_fieldMessage.bounds.origin.x, _fieldMessage.bounds.origin.y, initFieldWidth - _labelDate.bounds.size.width, _fieldMessage.bounds.size.height)];
        if ([_fieldMessage.text length]) {
            [_fieldMessage setTextColor:[UIColor blueColor]];
        } else {
            _fieldMessage.placeholder = NSLocalizedString(@"REMINDER", nil);
        }
    }
}*/

- (void) setDate: (NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //NSString *dateName = @"";
    //[df setDateFormat:@"dd.MM.yy HH:mm"];
    if ([date compare: [NSDate date]] == NSOrderedAscending) {
        _labelDate.textColor = [UIColor redColor];
    }
    else {
        _labelDate.textColor = [_fieldMessage textColor];//[UIColor blackColor];
    }
    /*
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateDay = [calendar components:(NSTimeZoneCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSDateComponents *todayDay = [calendar components:(NSTimeZoneCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *nextDay = [calendar dateByAddingComponents:offsetComponents toDate:[calendar dateFromComponents:todayDay] options:0];
    [offsetComponents setDay:-1];
    NSDate *prevDay = [calendar dateByAddingComponents:offsetComponents toDate:[calendar dateFromComponents:todayDay] options:0];
    
    if ([dateDay isEqual:todayDay]) {
        [df setDateFormat:@" HH:mm"];
        dateName = NSLocalizedString(@"TODAY", @"Today");
    } else if ([[calendar dateFromComponents:dateDay] isEqual:nextDay]) {
        [df setDateFormat:@" HH:mm"];
        dateName = @"Tmrw";
        //dateName = NSLocalizedString(@"TOMORROW", @"Tomorrow");
    }else if ([[calendar dateFromComponents:dateDay] isEqual:prevDay]) {
        [df setDateFormat:@" HH:mm"];
        //dateName = NSLocalizedString(@"YESTERDAY", @"Yesterday");
        dateName = @"Ytd";
    } else {
        [df setDateFormat:@"dd.MM.yy HH:mm"];
    }
     
    _labelDate.text = [dateName length] > 0 ? [dateName stringByAppendingString:[df stringFromDate:date]] : [df stringFromDate:date];
    */
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateDay = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    NSDateComponents *todayDay = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
    
    if ([dateDay isEqual:todayDay]) {
        [df setDateStyle:NSDateFormatterNoStyle];
        [df setTimeStyle:NSDateFormatterShortStyle];
    } else {
        [df setDateStyle:NSDateFormatterMediumStyle];
    }
    
    _labelDate.text = [df stringFromDate:date];
    [_labelDate sizeToFit];
    //NSLog(@"Date width: %f or %f", _labelDate.bounds.size.width, _labelDate.frame.size.width);
    //NSLog(@"Message width: %f or %f", _fieldMessage.bounds.size.width, _fieldMessage.frame.size.width);
    /*
    _labelDate.translatesAutoresizingMaskIntoConstraints = NO;
    _fieldMessage.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDictionary = @{@"labelDate":_labelDate, @"fieldMessage":_fieldMessage};
    NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[fieldMessage]-5-[labelDate]-0-|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:viewsDictionary];
    [self addConstraints:constraint_POS_H];
     */
}

@end
