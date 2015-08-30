//
//  FREditReminderViewController.m
//  Call Reminder
//
//  Created by Тимур Насыров on 07.07.14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//
// ViewController редактриования напоминания

#import "FREditReminderViewController.h"

@interface FREditReminderViewController ()

@end

@implementation FREditReminderViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_itemToEdit) {
        _datePicker.date = [_itemToEdit valueForKey:@"alarm"];
        _textMessage.text = [_itemToEdit valueForKey:@"notification"];
    }
    else {
        [self.datePicker setMinimumDate:[[NSDate date] dateByAddingTimeInterval:60]];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (IBAction)saveReminder:(id)sender
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self.datePicker.date];
    [dateComponents setSecond:0];
    NSDate *alarmDate = [calendar dateFromComponents:dateComponents];
    
    if ([alarmDate compare: [NSDate date]] == NSOrderedAscending || [alarmDate compare: [NSDate date]] == NSOrderedSame) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERT", @"Alert") message:NSLocalizedString(@"NOTIF_BEFORENOW", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"Cancel") otherButtonTitles: nil];
        [alert show];
        return;
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 // запрос на отображение напоминаний в iOS 8
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (!(grantedSettings.types  & UIUserNotificationTypeAlert)){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERT", @"Alert") message:NSLocalizedString(@"NOTIFS_OFF", @"disabled notifs message") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"Cancel") otherButtonTitles: nil];
            [alert show];
            return;
        }
    }
#endif
    if (!self.parentNumber) {
        FREditNumberViewController *numberController = (FREditNumberViewController *)[self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count - 2)];
        self.parentNumber = [numberController saveTheNumber: YES];
    }
    NSManagedObject *reminder;
    if (self.itemToEdit) {
        reminder = self.itemToEdit;
    } else {
        reminder = [NSEntityDescription insertNewObjectForEntityForName:@"Reminder" inManagedObjectContext:self.managedObjectContext];
    }
    
    [reminder setValue:alarmDate forKey:@"alarm"];
    [reminder setValue:self.textMessage.text forKey:@"notification"];
    [reminder setValue:@NO forKey:@"pendingCall"];
    [reminder setValue:self.parentNumber forKey:@"number"];
    
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
//    UIApplication *app = [UIApplication sharedApplication];
//    NSString *reminderURI = [[[reminder objectID] URIRepresentation] absoluteString];
//    
//    //deleting reminder if existed
//    if (self.itemToEdit) {
//        [TNStaticUtils cancelNotification:app :reminderURI];
//    }
//    
//    //creating new reminder
//    NSString *toWho = [self.parentNumber valueForKey:@"title"];
//    if (![toWho length]) toWho = [self.parentNumber valueForKey:@"number"];
//    NSString *note = [self.parentNumber valueForKey:@"note"];
//    
//    [TNStaticUtils makeCallNotification:app Date:alarmDate ToWho:toWho Message:note ReminderObject:reminder];
    
    [self performSegueWithIdentifier:@"returnToNumberFromReminder" sender:self];
}
@end
