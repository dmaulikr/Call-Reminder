//
//  FRReminderCell.h
//  Call Reminder
//
//  Created by Тимур Насыров on 22.01.14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TNTableViewCell.h"

@interface FRReminderCell : TNTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelNumber;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;

@end
