//
//  ENReminderCell.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/4/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ENReminderCell : UITableViewCell
{
    BOOL editMode;
    CGFloat initFieldWidth;
}

@property (weak, nonatomic) IBOutlet UILabel *fieldMessage;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;

@property (weak, nonatomic) NSIndexPath *indexPath;

//- (void) setEditMode: (BOOL)edit aninated: (BOOL)animated;
- (void) setDate: (NSDate *)date;

@end
