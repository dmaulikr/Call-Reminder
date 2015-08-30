//
//  ENNameCell.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/2/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "ENNameCell.h"

@implementation ENNameCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [self setTextHint:true];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTextHint:(BOOL)hint
{
    if (hint) {
        _fieldTitle.placeholder = NSLocalizedString(@"NAME_FIELD_HINT", "Placeholder with hint");
    } else {
        _fieldTitle.placeholder = NSLocalizedString(@"NAME_FIELD", "Placeholder without hint");
    }
}

@end
