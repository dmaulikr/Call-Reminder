//
//  ENNameCell.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/2/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ENNameCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *fieldTitle;
@property (weak, nonatomic) IBOutlet UIButton *numberOkButton;

- (void)setTextHint:(BOOL)hint;

@end
