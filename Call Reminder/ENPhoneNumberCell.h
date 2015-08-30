//
//  ENPhoneNumberCell.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/2/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ENPhoneNumberCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *fieldNumber;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddressBook;

@end
