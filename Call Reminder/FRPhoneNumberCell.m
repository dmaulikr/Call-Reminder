//
//  FRPhoneNumberCell.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 9/30/13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import "FRPhoneNumberCell.h"

@implementation FRPhoneNumberCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    // Configure the view for the selected state
}

- (void)hideAccessory
{
    self.accessoryType = UITableViewCellAccessoryNone;
}

- (void)widthWithSections: (BOOL)on
{
    if (on) {
        [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 300, self.bounds.size.height)];
    } else {
        [self setBounds:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 320, self.bounds.size.height)];
    }
}

@end
