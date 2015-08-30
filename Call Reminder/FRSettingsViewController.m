//
//  FRSettingsViewController.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/17/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "FRSettingsViewController.h"

@interface FRSettingsViewController ()

@end

@implementation FRSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UserSettings = [NSUserDefaults standardUserDefaults];
    self.switchAnimation.on = ![UserSettings boolForKey:@"Animation"];
    self.switchPhoneFormat.on = [UserSettings boolForKey:@"PhoneFormat"];
    self.switchGroupContacts.on = [UserSettings boolForKey:@"GroupContacts"];
    self.switchConfCallNotif.on = [UserSettings boolForKey:@"ConfirmCallNotif"];
    self.switchAfterCall.on = [UserSettings boolForKey:@"ConfirmAfterCall"];
    
    RootController = self.navigationController.viewControllers[0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)switchedAnimation:(id)sender {
    [UserSettings setBool:!self.switchAnimation.on forKey:@"Animation"];
    [UserSettings synchronize];
}

- (IBAction)switchedPhoneFormat:(id)sender {
    [UserSettings setBool:self.switchPhoneFormat.on forKey:@"PhoneFormat"];
    [UserSettings synchronize];
}

- (IBAction)switchedGroupContacts:(id)sender {
    [UserSettings setBool:self.switchGroupContacts.on forKey:@"GroupContacts"];
    [UserSettings synchronize];
    RootController.shouldReloadNumbersTable = TRUE;
    RootController.fetchedResultsController = nil;
}

- (IBAction)switchedConfCallNotif:(id)sender {
    [UserSettings setBool:self.switchConfCallNotif.on forKey:@"ConfirmCallNotif"];
    [UserSettings synchronize];
}

- (IBAction)switchedAfterCall:(id)sender {
    [UserSettings setBool:self.switchAfterCall.on forKey:@"ConfirmAfterCall"];
    [UserSettings synchronize];
}

- (IBAction)generateContacts:(id)sender
{
    for (int i = 0; i < 100; i++) {
        int randomNum = arc4random() % 999999;
        int num = 5 + arc4random() % 10;
        NSMutableString* randomString = [NSMutableString stringWithCapacity:num];
        for (int i = 0; i < num; i++) {
            [randomString appendFormat:@"%C", (unichar)('a' + arc4random_uniform(25))];
        }
    
        NSManagedObject *randPhone = [NSEntityDescription insertNewObjectForEntityForName:@"PhoneNumber" inManagedObjectContext:self.managedObjectContext];
        [randPhone setValue:[NSString stringWithFormat:@"%i", randomNum]    forKey:@"number"];
        [randPhone setValue:randomString                                    forKey:@"title"];
        [randPhone setValue:@(FALSE)                                        forKey:@"temp"];
    }
    NSError *error;
    [self.managedObjectContext save:&error];
}
@end
