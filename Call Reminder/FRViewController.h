//
//  FRViewController.h
//  Call Reminder
//
//  Created by Тимур Насыров on 23.09.13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "FREditNumberViewController.h"

extern const char IndexPath;

@interface FRViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate>
{
    NSMutableArray * phoneNumbersArray;
    bool shouldReloadTable;
    NSUserDefaults *UserSettings;
    NSMutableArray *sectionsNames;
    bool isJustLoaded;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) bool shouldReloadNumbersTable;
@property (nonatomic) bool shouldReloadRemindersTable;
-(void)reloadTableWithIndex: (int)tableIndex;
-(void)reloadRemindersForced;

- (IBAction)tableSwitched:(UISegmentedControl *)sender;
- (IBAction)returnToMainView:(UIStoryboardSegue *)segue;
@property (weak, nonatomic) IBOutlet UITableView *tableViewNumbers;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tableSwitcher;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayer;


@end
