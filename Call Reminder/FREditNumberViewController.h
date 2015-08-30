//
//  FREditNumberViewController.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 9/26/13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#import "RMPhoneFormat.h"
#import "TNCellWithTable.h"
#import "ENDeleteCell.h"
#import "ENPhoneNumberCell.h"
#import "ENNameCell.h"
#import "ENReminderCell.h"
#import "FRViewController.h"

@class FRViewController;

@interface FREditNumberViewController : UITableViewController <UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIAlertViewDelegate>
{
    BOOL _isContactFromAdressBook;
    BOOL isInnerEdit;
    RMPhoneFormat * _phoneFormat;
    NSMutableCharacterSet * _phoneChars;
    NSString * deleteButtonText;
    NSTimer *timerToCancelDeleting;
    NSUserDefaults *UserSettings;
    NSArray *phoneReminders;
    
    CGPoint initScrollPos;
    UIEdgeInsets initMainViewInsets;
    
    UITableViewCell *newReminderCell;
    FRViewController *parentView;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) id itemToEdit;
@property (weak, nonatomic) id reminderToFocus;

@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;
@property (strong, nonatomic) IBOutlet UITableView *mainTableView;

@property (weak, nonatomic) UITextField *fieldNumber;
@property (weak, nonatomic) UITableViewCell *cellTitle;
@property (weak, nonatomic) UITextField *fieldTitle;
@property (weak, nonatomic) IBOutlet UITableViewCell *datePickerCell;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITableViewCell *notificationMessageCell;
@property (weak, nonatomic) IBOutlet UITextField *notificationMessageField;
@property (weak, nonatomic) IBOutlet UISwitch *remindSwitch;
@property (weak, nonatomic) UIButton *buttonDelete;
@property (weak, nonatomic) UITableViewCell *cellDelete;
@property (weak, nonatomic) UIButton *buttonAdressBook;
@property (weak, nonatomic) UITableViewCell *cellNumber;
@property (weak, nonatomic) TNCellWithTable *cellNumberSearch;
@property (weak, nonatomic) UIButton *numberOkButton;

- (IBAction)returnToNumberEdit:(UIStoryboardSegue *)segue;
- (IBAction)saveNumber:(id)sender;
- (void)addFromAdressBook:(id)sender;
- (void)deleteNumber:(id)sender;
- (void)nameFieldEditingBegin:(id)sender;
- (void)nameFieldEditingEnd:(id)sender;
- (void)titleChanged:(id)sender;
- (void)numberOkButtonPressed:(id)sender;
- (NSManagedObject *)saveTheNumber: (BOOL)setFRC;

- (void)selectedNumberObject: (NSManagedObject *) object;
- (void)fieldNumberChanged: (id)sender;

@end
