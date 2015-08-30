//
//  FRAppDelegate.h
//  Call Reminder
//
//  Created by Тимур Насыров on 23.09.13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const char NumberToDial;

@interface FRAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{

}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSUserDefaults* userSettings;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (NSManagedObject *)objectWithURI:(NSURL *)uri;
+ (BOOL)dial:(NSString *)number;
- (void)dial:(NSString *)number afterNotif:(BOOL)afterNotif;

@end
