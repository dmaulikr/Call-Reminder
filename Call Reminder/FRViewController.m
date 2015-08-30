//
//  FRViewController.m
//  Call Reminder
//
//  Created by Тимур Насыров on 23.09.13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//
//  Основной ViewController приложения, с таблицей номеров и напоминаний

#import "FRViewController.h"

#import "FRAppDelegate.h"
#import "FRPhoneNumberCell.h"
#import "FRReminderCell.h"
#import "TNStaticUtils.h"
#import "TNTableViewCell.h"

@interface FRViewController ()

@end

const char IndexPath;

@implementation FRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    FRAppDelegate *appDelegate = (FRAppDelegate *)[[UIApplication sharedApplication] delegate];
    UserSettings = appDelegate.userSettings;//[NSUserDefaults standardUserDefaults];
    
    self.managedObjectContext = [appDelegate managedObjectContext];
    // обнаружение просроченных напоминаний
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reminder" inManagedObjectContext: self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"alarm <= %@", [NSDate date]];
    [request setPredicate:predicate];
    
    NSError *error;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if ([mutableFetchResults count] > 0) {
        // если просроченные напоминания обнаружены - переключитсья на отображение списка напоминаний (а не номеров)
        self.tableSwitcher.selectedSegmentIndex = 1;
    }
    
    self.fetchedResultsController = [self fetchedResultsController];
    shouldReloadTable = false;
    _shouldReloadNumbersTable = FALSE;
    _shouldReloadRemindersTable = FALSE;
    isJustLoaded = TRUE;
    self.tableViewNumbers.sectionIndexMinimumDisplayRowCount = 10;
    _tableViewNumbers.sectionIndexBackgroundColor = [UIColor clearColor];
    self.searchDisplayer.searchResultsTableView.rowHeight = self.tableViewNumbers.rowHeight;
    // прячем ячейку со строкой поиска, сместив прокрутку ниже на одну ячейку:
    self.tableViewNumbers.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    sectionsNames = [[NSMutableArray alloc] init];
    //[self fetchNumbers];
//    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 480.0)) {
//    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadRemindersForced) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadRemindersForced) name:@"CustomNotifReceived" object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (isJustLoaded) {
        isJustLoaded = FALSE;
        return;
    }
    
    // перерисовываем таблицы в случае необходимости
    if (_shouldReloadNumbersTable && !_shouldReloadRemindersTable) {
        [self reloadTableWithIndex:0];
    } else if (!_shouldReloadNumbersTable && _shouldReloadRemindersTable) {
        [self reloadTableWithIndex:1];
    } else if (_shouldReloadNumbersTable && _shouldReloadRemindersTable) {
        [self reloadTable];
    }
}

- (void) fetchNumbers: (NSString *) searchString {
    // Define our table/entity to use
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhoneNumber" inManagedObjectContext: self.managedObjectContext];
    // Setup the fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    // Define how we will sort the records
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [request setSortDescriptors:sortDescriptors];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temp = nil AND (title contains[cd] %@ OR number contains[cd] %@)", searchString, searchString];
    [request setPredicate:predicate];
    // Fetch the records and handle an error
    NSError *error;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (!mutableFetchResults) {
        // Handle the error.
        // This is a serious error and should advise the user to restart the application
    }
    // Save our fetched data to an array
    phoneNumbersArray = mutableFetchResults;
    //[self setEventArray: mutableFetchResults];
}

- (void) fetchReminders {
    // Define our table/entity to use
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Reminder" inManagedObjectContext: self.managedObjectContext];
    // Setup the fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    // Define how we will sort the records
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"alarm" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [request setSortDescriptors:sortDescriptors];
    // Fetch the records and handle an error
    NSError *error;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (!mutableFetchResults) {
        // Handle the error.
        // This is a serious error and should advise the user to restart the application
    }
    // Save our fetched data to an array
    phoneNumbersArray = mutableFetchResults;
    //[self setEventArray: mutableFetchResults];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.fetchedResultsController = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController fetchedObjects] count] == 0 && !self.searchDisplayer.isActive) {
        return 1;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // если в таблице нет записей, подготавливаем ее для отображения большой ячейки-заглушки с надписью
    if ([[self.fetchedResultsController fetchedObjects] count] == 0 && self.tableViewNumbers.tag != 3 && !self.searchDisplayer.isActive) {
        tableView.rowHeight = 300;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return 1;
    } else {
        tableView.rowHeight = 55;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    return [[self.fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController fetchedObjects] count] == 0 && !self.searchDisplayer.isActive) return nil;
    
    NSString *sectionName = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    if ([UserSettings boolForKey:@"GroupContacts"]) {
//        for (NSString *sName in sectionsNames) {
//            if ([sName isEqualToString:sectionName]) {
//                sectionsNames = [[NSMutableArray alloc] init];
//                break;
//            }
//        }
        if ([sectionName length] && ![sectionsNames containsObject:sectionName]) {
            [sectionsNames addObject:sectionName];
        }
    }
    return sectionName;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // если в заголовке секции не число, а надпись "просроченно" (с учетом локализации) - отображаем ее красным цветом
    if ([[[[self.fetchedResultsController sections] objectAtIndex:section] name]  isEqual: NSLocalizedString(@"REMIDNDERLIST_EXPIRED", @"Expired")]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        [header.textLabel setTextColor:[UIColor whiteColor]];
        view.tintColor = [UIColor redColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if ([[self.fetchedResultsController fetchedObjects] count] == 0) {
        // если нет данных для отображения, выводим заглушку:
        cell = [self loadCellWithIdentifier:@"TNEmptyTableCell" AndClass:[UITableViewCell class] ForTableView:tableView];
    }
    // иначе - отображаем номера или напоминания, в зависимости от переключателя
    else if (self.tableSwitcher.selectedSegmentIndex == 0) {
        cell = [self loadCellWithIdentifier:@"PhoneNumberCell" AndClass:[FRPhoneNumberCell class] ForTableView:tableView];
        [self configureCellPhoneNumber:(FRPhoneNumberCell *)cell atIndexPath:indexPath];
    } else {
        cell = [self loadCellWithIdentifier:@"ReminderCell" AndClass:[FRReminderCell class] ForTableView:tableView];
        [self configureCellReminder:(FRReminderCell *)cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (UITableViewCell *)loadCellWithIdentifier: (NSString *) simpleTableIdentifier AndClass: (Class) class ForTableView: (UITableView *) tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (![cell isKindOfClass:class]) cell = nil;
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:simpleTableIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // удаление записей в таблице свайпом
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        sectionsNames = [[NSMutableArray alloc] init];
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSManagedObject *objToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        //deleting reminder
        if (self.tableSwitcher.selectedSegmentIndex == 1)
        {
            //[TNStaticUtils cancelNotification:[UIApplication sharedApplication] :[[[objToDelete objectID] URIRepresentation] absoluteString]];
            NSManagedObject *contact = [objToDelete valueForKey:@"number"];
            NSString *isTemp = [contact valueForKey:@"temp"];
            if (isTemp.boolValue) {
                NSInteger remsCount = 0;
                NSArray *reminders = [contact valueForKeyPath:@"reminder"];
                if (reminders != nil) remsCount = reminders.count;
                if (remsCount < 2) {
                    [context deleteObject:contact];
                }
            }
        }
        else //deleting contact
        {
            NSInteger remsCount = 0;
            NSArray *reminders = [objToDelete valueForKeyPath:@"reminder"];
            if (reminders != nil) remsCount = reminders.count;
            //if ([objToDelete valueForKey:@"reminder"] != NULL) {
            if (remsCount > 0) {
                // если у номера задано напоминание, выводим подтверждение, о том, что удалены будут оба
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dete" message:@"There's a reminder set for that contact. Are you sure you wish to delete both?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                [alert show];
                objc_setAssociatedObject(alert, &IndexPath, indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                return;
            }
        }
        
        [context deleteObject:objToDelete];
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// обработка нажатий в окне подтверждения удаления номера с напоминанием
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        NSIndexPath * indexPath = objc_getAssociatedObject(alertView, &IndexPath);
        
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSManagedObject *objToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSSet *reminders = [objToDelete valueForKey:@"reminder"];
        for (NSManagedObject *reminder in reminders) {
            [context deleteObject:reminder];
        }

        [context deleteObject:objToDelete];
        
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// запрос данных из coredata с предикатом
- (NSFetchedResultsController *)fetchedResultsControllerWithPredicate: (NSPredicate *) predicate
{
    if (_fetchedResultsController != nil) {
        _fetchedResultsController = nil;
    }
    
    [self setupFetchedResultsController];
    [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)setupFetchedResultsController
{
    NSString *sectionName;
    NSString *cacheName = @"Master";
    if (self.tableSwitcher.selectedSegmentIndex == 0) {
        if ([UserSettings boolForKey:@"GroupContacts"]) {
            sectionName = @"t_firstLetter";
        } else {
            sectionName = nil;
        }
    } else {
        sectionName = @"t_dateName";
    }
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSString *entityName;
    //NSString *sortKey;
    //NSSortDescriptor *sortDescriptor;
    NSArray *sortDescriptors = [[NSArray alloc] init];
    if (self.tableSwitcher.selectedSegmentIndex == 0) {
        entityName = @"PhoneNumber";
        NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"t_firstLetter" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        sortDescriptors = @[sortDescriptor1, sortDescriptor2];
        
        //sortKey = @"title";
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temp != YES"];
        [fetchRequest setPredicate:predicate];
    } else {
        entityName = @"Reminder";
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"alarm" ascending:YES];
        sortDescriptors = @[sortDescriptor];
        //sortKey = @"alarm";
    }
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:YES];
    //NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:sectionName cacheName:cacheName];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    [self setupFetchedResultsController];
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

// подготовка к переходу на другой view
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FREditNumberViewController *destination = [segue destinationViewController];
    // если мы переходим не на view настроек, а на view редактирования/просмотра номера и его напоминаний:
    if (![destination.title  isEqual: NSLocalizedString(@"SETTINGS_VIEW", @"Settings")]) {
        if ([sender isKindOfClass:[TNTableViewCell class]]) {
            TNTableViewCell *cell = (TNTableViewCell *)sender;
            NSIndexPath *itemToEdit = cell.indexPath;//[self.tableViewNumbers indexPathForCell:cell];
            if (self.tableSwitcher.selectedSegmentIndex == 0) {
                // если выбран номер, передаем для view редактирования/просмотра номера объект выбранного номера
                destination.itemToEdit = [self.fetchedResultsController objectAtIndexPath:itemToEdit];
            } else {
                // если выбрано напоминание,задаем для view редактирования/просмотра номера объект того номера, который соответствует выбранному напоминанию и объект самого выбранного напоминания для того, чтобы подсветить его в списке напоминаний номера
                destination.itemToEdit = [[self.fetchedResultsController objectAtIndexPath:itemToEdit] valueForKey:@"number"];
                destination.reminderToFocus = [self.fetchedResultsController objectAtIndexPath:itemToEdit];
            }
        }
        else {
            destination.itemToEdit = nil;
        }
        
        //destination.managedObjectContext = self.managedObjectContext;
    }
    destination.managedObjectContext = self.managedObjectContext;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (!self.isViewLoaded || (!self.view.window && ![self.searchDisplayer isActive])) return;
    
    if ([self.searchDisplayer isActive]) {
        shouldReloadTable = true;
    } else {
        [self.tableViewNumbers beginUpdates];
        self.tableViewNumbers.tag = 3;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (!(self.isViewLoaded && self.view.window)) return;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableViewNumbers insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableViewNumbers deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (!(self.isViewLoaded && self.view.window)) return;
    UITableView *tableView = [self.searchDisplayer isActive] ? self.searchDisplayer.searchResultsTableView : self.tableViewNumbers;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if (self.tableSwitcher.selectedSegmentIndex == 0) {
                [self configureCellPhoneNumber:(FRPhoneNumberCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            } else {
                [self configureCellReminder:(FRReminderCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            }
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (!self.isViewLoaded || (!self.view.window && ![self.searchDisplayer isActive])) return;
    //if ([[self.fetchedResultsController fetchedObjects] count] == 0)
    if ([self.searchDisplayer isActive]) {
        //[self.searchDisplayer.searchResultsTableView endUpdates];
        shouldReloadTable = true;
    } else {
        [self.tableViewNumbers endUpdates];
        self.tableViewNumbers.tag = 0;
        // если после внесения изменений таблица осталась пуст - красиво и плавно подменяем ее содержимое на ячейку-заглушку
        if ([[self.fetchedResultsController fetchedObjects] count] == 0) {
            [self.tableViewNumbers reloadData];
            CATransition *animation = [CATransition animation];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFade];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [animation setFillMode:kCAFillModeBoth];
            [animation setDuration:.3];
            [[self.tableViewNumbers layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
        }
    }
}

// нажата accessoryButton в ячейке и требуется выполнить переход на view просмотра/редактирования номера и списка его напоминаний
- (void) tableView: (UITableView *)tableView accessoryButtonTappedForRowWithIndexPath: (NSIndexPath *)indexPath
{
 /*   UIView *accessoryView = [[tableView cellForRowAtIndexPath:indexPath] accessoryType];
    for (id subView in accessoryView.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            UIButton *accessoryButton = (UIButton *)subView;
            [accessoryButton setHighlighted:YES];
        }
    }*/
    TNTableViewCell *cell = (TNTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.indexPath = indexPath;
    [self performSegueWithIdentifier: @"segueNewNumber" sender: cell];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if ([UserSettings boolForKey:@"GroupContacts"] && self.tableSwitcher.selectedSegmentIndex == 0 && ![self.searchDisplayer isActive]) {
        return [sectionsNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    } else {
        return nil;
    }
}

/*
- (void)numberEditButton: (FREditItemButton*)button event:(UIEvent*)event
{
    id cellView = [button superview];
    while ([cellView isKindOfClass:[UITableViewCell class]] == NO) {
        cellView = [cellView superview];
    }
    UITableViewCell* cell = (UITableViewCell *)cellView;
    
    id tableView = [cell superview];
    while ([tableView isKindOfClass:[UITableView class]] == NO) {
        tableView = [tableView superview];
    }
    
    button.itemToEdit = [(UITableView *)tableView indexPathForCell:cell];
    [self performSegueWithIdentifier: @"segueNewNumber" sender: button];
}
 */

- (void)configureCellPhoneNumber:(FRPhoneNumberCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.labelTitle.text = [[object valueForKey:@"title"] description];
    cell.labelNumber.text = [[object valueForKey:@"number"] description];
    if ([UserSettings boolForKey:@"GroupContacts"] && ![self.searchDisplayer isActive]) {
        [cell widthWithSections:YES];
    } else {
        [cell widthWithSections:NO];
    }
    //cell.buttonEditNumber.itemToEdit = indexPath;
    //[cell.buttonEditNumber addTarget:self action:@selector(numberEditButton:event:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureCellReminder:(FRReminderCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *reminder = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setTimeStyle:NSDateFormatterShortStyle];
    if ([[[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] name] isEqual: NSLocalizedString(@"REMIDNDERLIST_EXPIRED", @"Expired")]) {
        [df setDateStyle:NSDateFormatterShortStyle];
    } else {
        [df setDateFormat:NSDateFormatterNoStyle];
    }
    cell.labelDate.text = [df stringFromDate:[reminder valueForKey:@"alarm"]];
    if ([reminder valueForKey:@"number"] != NULL)
    {
        NSManagedObject *number = [reminder valueForKey:@"number"];
        cell.labelTitle.text = [[number valueForKey:@"title"] description];
        cell.labelNumber.text = [[number valueForKey:@"number"] description];
    }
    //cell.buttonEditNumber.itemToEdit = indexPath;
    //[cell.buttonEditNumber addTarget:self action:@selector(numberEditButton:event:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self.fetchedResultsController fetchedObjects] count] == 0) return;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.tableSwitcher.selectedSegmentIndex == 0) {
        // если нажат номер - сразу вызываем
        [FRAppDelegate dial:[[[self.fetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"number"] description]];
    }
    else {
        // если нажато напоминание - запоминаем, что вызов произойдет по напоминанию (чтобы после запросить у пользователя удаление или откладывание напоминания) и производим звонок
        NSManagedObject * reminder = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [reminder setValue:@YES forKey:@"pendingCall"];
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        NSManagedObject * number = [reminder valueForKey:@"number"];
        [self dial:[[number valueForKey:@"number"] description] afterNotif:YES];
    }
}

- (void)dial:(NSString *)number afterNotif:(BOOL)afterNotif
{
    if ([FRAppDelegate dial:number]) {
        NSUserDefaults * userSettings = [NSUserDefaults standardUserDefaults];
        [userSettings setBool:afterNotif forKey:@"AfterCall"];
        //[_userSettings setBool:YES forKey:@"WillCall"];
        [userSettings synchronize];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate = nil;
    if ([searchString length]) {
        if (self.tableSwitcher.selectedSegmentIndex == 0) {
            predicate = [NSPredicate predicateWithFormat:@"temp != YES AND (title contains[cd] %@ OR number contains[cd] %@)", searchString, searchString];
        }
        else {
            predicate = [NSPredicate predicateWithFormat:@"ANY number.title contains[cd] %@ OR ANY number.number contains[cd] %@", searchString, searchString];
        }
    }
    [self fetchedResultsControllerWithPredicate:predicate];
    
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [self fetchedResultsController];
    if (shouldReloadTable) {
        [self.tableViewNumbers reloadData];
        shouldReloadTable = FALSE;
    }
}

- (IBAction)tableSwitched:(UISegmentedControl *)sender
{
    sectionsNames = [[NSMutableArray alloc] init];
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [self fetchedResultsController];
    [self.tableViewNumbers reloadData];
    // add animation
    if ([UserSettings boolForKey:@"Animation"]) {
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionPush];
        if (sender.selectedSegmentIndex == 0) {
            [animation setSubtype:kCATransitionFromLeft];
        } else {
            [animation setSubtype:kCATransitionFromRight];
        }
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setFillMode:kCAFillModeBoth];
        [animation setDuration:.3];
        [[self.tableViewNumbers layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
    }
}

-(void)reloadTable
{
    sectionsNames = [[NSMutableArray alloc] init];
    if ([self.searchDisplayer isActive]) {
        [self.searchDisplayer.searchResultsTableView reloadData];
    }
    else
        [self.tableViewNumbers reloadData];
}

-(void)reloadTableWithIndex: (int)tableIndex
{
    if (self.tableSwitcher.selectedSegmentIndex == tableIndex) {
        [self reloadTable];
    } else if (tableIndex < 0) {
        [self reloadTable];
    }
}

-(void)reloadRemindersForced
{
    if (self.tableSwitcher.selectedSegmentIndex == 1) {
        sectionsNames = [[NSMutableArray alloc] init];
        self.fetchedResultsController = nil;
        self.fetchedResultsController = [self fetchedResultsController];
        [self.tableViewNumbers reloadData];
    }
}

-(IBAction)returnToMainView:(UIStoryboardSegue *)segue
{
    //[self reloadTable];
    //[self.searchDisplayer.searchBar becomeFirstResponder];
    /*
    NSString *searchString = self.searchDisplayer.searchBar.text;
    
    NSPredicate *predicate = nil;
    if ([searchString length]) {
        if (self.tableSwitcher.selectedSegmentIndex == 0) {
            predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR number contains[cd] %@", searchString, searchString];
        }
        else {
            predicate = [NSPredicate predicateWithFormat:@"alarm contains[cd] %@", searchString];
        }
    }
    [self fetchedResultsControllerWithPredicate:predicate];
    
    [self.searchDisplayer.searchResultsTableView reloadData];
     */
    /*
    if ([self.searchDisplayer isActive]) {
        NSString *searchString = self.searchDisplayer.searchBar.text;
        
        NSPredicate *predicate = nil;
        if ([searchString length]) {
            if (self.tableSwitcher.selectedSegmentIndex == 0) {
                predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR number contains[cd] %@", searchString, searchString];
            }
            else {
                predicate = [NSPredicate predicateWithFormat:@"alarm contains[cd] %@", searchString];
            }
        }
        [self fetchedResultsControllerWithPredicate:predicate];
        
        [self.searchDisplayer.searchResultsTableView reloadData];
    }
     */
}

@end
