//
//  FREditReminderViewController.h
//  Call Reminder
//
//  Created by Тимур Насыров on 07.07.14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FREditNumberViewController.h"
#import "TNStaticUtils.h"

@interface FREditReminderViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextView *textMessage;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) NSManagedObject *parentNumber;
@property (weak, nonatomic) id itemToEdit;

- (IBAction)saveReminder:(id)sender;

@end
