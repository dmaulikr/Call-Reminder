//
//  FRSettingsViewController.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/17/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRAppDelegate.h"
#import "FRViewController.h"

@interface FRSettingsViewController : UITableViewController
{
    NSUserDefaults *UserSettings;
    FRViewController *RootController;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UISwitch *switchAnimation;
@property (weak, nonatomic) IBOutlet UISwitch *switchPhoneFormat;
@property (weak, nonatomic) IBOutlet UISwitch *switchGroupContacts;
@property (weak, nonatomic) IBOutlet UISwitch *switchConfCallNotif;
@property (weak, nonatomic) IBOutlet UISwitch *switchAfterCall;

- (IBAction)switchedAnimation:(id)sender;
- (IBAction)switchedPhoneFormat:(id)sender;
- (IBAction)switchedGroupContacts:(id)sender;
- (IBAction)switchedConfCallNotif:(id)sender;
- (IBAction)switchedAfterCall:(id)sender;
- (IBAction)generateContacts:(id)sender;


@end
