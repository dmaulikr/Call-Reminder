//
//  FRPhoneNumberCell.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 9/30/13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TNTableViewCell.h"

@interface FRPhoneNumberCell : TNTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelNumber;

//@property (weak, nonatomic) NSIndexPath *indexPath;

- (void)hideAccessory;
- (void)widthWithSections: (BOOL)on;

@end
