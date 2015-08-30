//
//  TNCellNumberSearch.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/27/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TNCellWithTable;

@interface TNCellNumberSearch : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *number;

@property (strong, nonatomic) NSIndexPath *selfIndexPath;
@property (weak, nonatomic) TNCellWithTable *parentTable;

- (IBAction)buttonPressed:(id)sender;

@end
