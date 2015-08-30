//
//  FRAppDelegate.m
//  Call Reminder
//
//  Created by Тимур Насыров on 23.09.13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import "FRAppDelegate.h"

#import "FRViewController.h"
#import "TNStaticUtils.h"

@implementation FRAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

const char NumberToDial;
const char ReminderObj;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
//    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//    FRViewController *controller = (FRViewController *)navigationController.topViewController;
//    controller.managedObjectContext = self.managedObjectContext;
    
    // пользовательские настройки и кое-какие флаги, которые сохраняются между запусками приложения:
    NSDictionary * defaultsDictionary = @{@"AppFirstLaunch" : @YES, @"Animation" : @YES, @"PhoneFormat" : @YES, @"ConfirmCallNotif" : @YES, @"ConfirmAfterCall" :@YES, @"GroupContacts" : @YES, @"AfterCall" : @NO};//, @"WillCall": @NO};
    _userSettings = [NSUserDefaults standardUserDefaults];
    [_userSettings registerDefaults:defaultsDictionary];
    if ([_userSettings boolForKey:@"AppFirstLaunch"]) {
        // обнаружен первый запуск приложения
        [_userSettings setBool:NO forKey:@"AppFirstLaunch"];
    }
    
    // если приложение запущенно через напоминание:
    UILocalNotification *localNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif) {
        // получаем данные напоминания:
        NSString *reminderKey = [localNotif.userInfo objectForKey:@"ReminderKey"];
        NSURL *reminderURL = [NSURL URLWithString:reminderKey];
        NSManagedObject *reminderObject = [self objectWithURI:reminderURL];
        NSManagedObject *numberObject = [reminderObject valueForKey:@"number"];
        
        if ([_userSettings boolForKey:@"ConfirmCallNotif"]) { // если пользователь в настройках указал, что перед звонком следует вывести подтверждение
            [self makeAlertViewWithNumber:numberObject AndReminder:reminderObject];
        } else { // иначе - звоним сразу по номеру, связанному с напоминанием
            [reminderObject setValue:@YES forKey:@"pendingCall"]; // запоминаем, что пользователь звонит из приложения (чтобы по завершения разговора спроить, следует ли удалить напоминание или перенести его)
            [self saveContext];
            NSString *numberNumber = [numberObject valueForKey:@"number"];
            [self dial:numberNumber afterNotif:YES];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // обработка напоминаний при запущенном приложении:
    NSString *reminderKey = [notification.userInfo objectForKey:@"ReminderKey"];
    NSURL *reminderURL = [NSURL URLWithString:reminderKey];
    NSManagedObject *reminderObject = [self objectWithURI:reminderURL];
    if (reminderObject != NULL) {
        NSManagedObject *numberObject = [reminderObject valueForKey:@"number"];
        
        if ([application applicationState] == UIApplicationStateActive || [_userSettings boolForKey:@"ConfirmCallNotif"]) {
            // если приложение активно или пользователь указал в настройках, выводим диалоговое окошко с подтверждением вызова
            [self makeAlertViewWithNumber:numberObject AndReminder:reminderObject];
        } else {
            // если приложение было в фоне и пользователь не указал в настройках запрос подтверждения - звоним сразу
            NSString *numberNumber = [numberObject valueForKey:@"number"];
            [reminderObject setValue:@YES forKey:@"pendingCall"];
            [self saveContext];
            [self dial:numberNumber afterNotif:YES];
        }
        
        if (application.applicationState == UIApplicationStateActive ) {
            // если приложение активно - вызываем событие для перерисовки спика напоминаний (для того, чтобы вызываемое напоминание отобразилось как просроченное)
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomNotifReceived" object:self];
//            UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
//            if ([navigationController.topViewController isMemberOfClass:[FRViewController class]]) {
//                FRViewController *controller = (FRViewController *)navigationController.topViewController;
//                [controller reloadRemindersForced];
//            }
        }
    }
}

// функция отображения диалогового окна для подтверждения телефонного звонка
- (void)makeAlertViewWithNumber: (NSManagedObject *) numberObject AndReminder: (NSManagedObject *) reminderObject
{
    NSString *numberNumber = [numberObject valueForKey:@"number"];
    NSString *numberTitle = [numberObject valueForKey:@"title"];
    NSString *reminderNote = [reminderObject valueForKey:@"notification"];
    UIAlertView *callAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:[NSLocalizedString(@"CALL_MESSAGE", nil) stringByAppendingString:@" %@"], numberTitle] message:reminderNote delegate:self cancelButtonTitle:NSLocalizedString(@"CALL_LATER", nil) otherButtonTitles:NSLocalizedString(@"CALL_NOW", nil), nil];
    [callAlert show];
    objc_setAssociatedObject(callAlert, &NumberToDial, numberNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(callAlert, &ReminderObj, reminderObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// если в диалоговом окне нажата кнопка подтверждения - совершаем телефонный звонок
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString * number = objc_getAssociatedObject(alertView, &NumberToDial);
        NSManagedObject * reminder = objc_getAssociatedObject(alertView, &ReminderObj);
        [reminder setValue:@YES forKey:@"pendingCall"];
        [self saveContext];
        [self dial:number afterNotif:YES];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

// при сворачивании приложения, обновляем бейдж приложения - число просроченных напоминаний
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (grantedSettings.types & UIUserNotificationTypeBadge) {
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reminder" inManagedObjectContext: self.managedObjectContext];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entity];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"alarm <= %@", [NSDate date]];
            [request setPredicate:predicate];
            
            NSError *error;
            NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
            if ([mutableFetchResults count] > 0) {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[mutableFetchResults count]];
            } else {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            }
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    // если приложение перешло в активный режим после звонка по напоминанию, выводим actionSheet, в котором пользователь может удалить или отлиожить напоминание, по которому был совершен звонок
    if ([_userSettings boolForKey:@"AfterCall"]) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"alarm" ascending:YES];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reminder" inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pendingCall = YES"];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        [fetchRequest setPredicate:predicate];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:NULL cacheName:NULL];
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        NSManagedObject *firstReminder = [fetchedResultsController fetchedObjects][0];
        NSManagedObject *number = [firstReminder valueForKey:@"number"];
        
        NSString *sheetTitle = [NSString stringWithFormat:NSLocalizedString(@"AFTERCALL_MESSAGE", nil), [number valueForKey:@"title"]];
        
        [firstReminder setValue:@NO forKey:@"pendingCall"];
        [self saveContext];
        
        [_userSettings setBool:NO forKey:@"AfterCall"];
        [_userSettings synchronize];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                   destructiveButtonTitle:NSLocalizedString(@"AFTERCALL_DELETE", nil)
                                                        otherButtonTitles:[NSString stringWithFormat:NSLocalizedString(@"AFTERCALL_REMINDLATER", nil), @"30"], [NSString stringWithFormat:NSLocalizedString(@"AFTERCALL_REMINDLATER", nil), @"5"], nil];
        [actionSheet showInView:self.window];
        objc_setAssociatedObject(actionSheet, &ReminderObj, firstReminder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

// функция обработки нажатия на кнопки в actionSheet, показанному после совершения звонка
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSManagedObject *reminder = objc_getAssociatedObject(actionSheet, &ReminderObj);
    NSManagedObject *number = [reminder valueForKey:@"number"];
    NSString *title = [number valueForKey:@"title"];
    if (![title length]) {
        title = [number valueForKey:@"number"];
    }
    NSDate *dateNow = [NSDate date];
    NSDate *dateToRemind;
    switch (buttonIndex) {
        case 0:
            [self.managedObjectContext deleteObject:reminder];
            break;
        case 1:
            dateToRemind = [dateNow dateByAddingTimeInterval:60*30];
            [reminder setValue:dateToRemind forKey:@"alarm"];
            //[TNStaticUtils makeCallNotification:[UIApplication sharedApplication] Date:dateToRemind ToWho:title Message:[reminder valueForKey:@"notification"] ReminderObject:reminder];
            break;
            
        case 2:
            dateToRemind = [dateNow dateByAddingTimeInterval:60*5];
            [reminder setValue:dateToRemind forKey:@"alarm"];
            //[TNStaticUtils makeCallNotification:[UIApplication sharedApplication] Date:dateToRemind ToWho:title Message:[reminder valueForKey:@"notification"] ReminderObject:reminder];
            break;
            
        default:
            return;
    }
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];
}

// сохранение данных core data
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// функция вызова по номеру
+ (BOOL)dial:(NSString *)number
{
    UIDevice *device = [UIDevice currentDevice];
    if ([[device model] isEqualToString:@"iPhone"] ) {
        //NSCharacterSet * charsToRemove = [NSCharacterSet characterSetWithCharactersInString:@"()-  "];
        NSMutableCharacterSet* charsToRemove = [NSMutableCharacterSet characterSetWithCharactersInString:@"()-"];
        [charsToRemove formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString * clearNumber = [[number componentsSeparatedByCharactersInSet:charsToRemove] componentsJoinedByString:@""];
        NSString * callCommand = [[NSString alloc] initWithFormat:@"tel://%@", clearNumber];
        //NSLog(@"%@", callCommand);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callCommand]];
        return YES;
    }
    else {
        UIAlertView *Notpermitted=[[UIAlertView alloc] initWithTitle:@"Alert" message:NSLocalizedString(@"DEVICE_NOSUPPORT", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [Notpermitted show];
        return NO;
    }
}

// функция вызова по номеру (если вызов произведен по напоминанию)
- (void)dial:(NSString *)number afterNotif:(BOOL)afterNotif
{
    if ([FRAppDelegate dial:number]) {
        [_userSettings setBool:afterNotif forKey:@"AfterCall"];
        //[_userSettings setBool:YES forKey:@"WillCall"];
        [_userSettings synchronize];
    }
}

// функция получения объекта из CoreData по URI (из напоминания)
- (NSManagedObject *)objectWithURI:(NSURL *)uri
{
    NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:uri];
    
    if (!objectID)
    {
        return nil;
    }
    
    NSManagedObject *objectForID = [[self managedObjectContext] objectWithID:objectID];
    if (![objectForID isFault])
    {
        return objectForID;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[objectID entity]];
    
    // Equivalent to
    // predicate = [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] rightExpression:[NSExpression expressionForConstantValue:objectForID]     modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
    [request setPredicate:predicate];
    
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:nil];
    if ([results count] > 0 )
    {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CallReminder" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CallReminder.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    // !!! миграция со старой версии datamodel не реализована
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        
//        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
//            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
//        }
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
