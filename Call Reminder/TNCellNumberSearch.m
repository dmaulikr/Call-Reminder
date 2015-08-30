//
//  TNCellNumberSearch.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/27/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "TNCellNumberSearch.h"
#import "TNCellWithTable.h"

@implementation TNCellNumberSearch

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)buttonPressed:(id)sender
{
    [self setSelected:YES animated:NO];
    [self setSelected:NO animated:YES];
    [_parentTable selectedInnerCellAtIndexPath:_selfIndexPath];
}
@end
