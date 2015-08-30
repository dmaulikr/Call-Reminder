//
//  FREditNumberViewController.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 9/26/13.
//  Copyright (c) 2013 Тимур Насыров. All rights reserved.
//
//  ViewController просмотра и редактирования номера с его списком напоминаний

#import "FREditNumberViewController.h"

#import "FREditReminderViewController.h"
#import "FRAppDelegate.h"
#import "TNStaticUtils.h"

@interface FREditNumberViewController ()

@end

@implementation FREditNumberViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setupFormatter];
    _phoneChars = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
    [_phoneChars addCharactersInString:@"+*#,"];
    
    // Listen for changes locale (if the user changes the Region Format settings)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeChanged) name:NSCurrentLocaleDidChangeNotification object:nil];
    
    // если задан объект номера для редактирования - переходим в режим редактирования и просмотра напоминания
    if (self.itemToEdit) {
        self.navItem.title = NSLocalizedString(@"EDIT_NUMBER", @"Edit");
        if ([self.itemToEdit valueForKey:@"reminder"] != NULL) {
            self.fetchedResultsController = [self fetchedResultsController];
            /*
            NSSet *reminders = [self.itemToEdit valueForKey:@"reminder"];
            if ([reminders count] > 0) {
                phoneReminders = [NSArray arrayWithArray:[reminders allObjects]];
            }
             */
        }
    } else { // если объект номера не задан - все поля будут пустыми для создания нового номера
        self.navItem.title = NSLocalizedString(@"NEW_NUMBER", @"New");
    }
    
    _isContactFromAdressBook = FALSE;
    isInnerEdit = FALSE;
    
    UserSettings = [NSUserDefaults standardUserDefaults];
    
    self.fieldTitle.delegate = self;
    parentView = (FRViewController*)self.navigationController.viewControllers[0];
    
    //UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    //[self.tableView addGestureRecognizer:gestureRecognizer];
    
    /*
    if (self.itemToEdit) {
        [self setContactFromAdressBook:((NSString *)[self.itemToEdit valueForKey:@"temp"]).boolValue];
    }*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadRemindersInNumber) name:@"CustomNotifReceived" object:nil];
}

- (void) reloadRemindersInNumber
{
    if (self.isViewLoaded && self.view.window) {
        // !!!: TODO implement table reminders update
        //[self.tableView reloadData];
    }
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // если перешли на этот view по нажатию на accessoryButton напоминания в главном view - подсвечиваем соответсвующее напоминание в списке
    if (self.reminderToFocus) {
        NSIndexPath *reminderToFocusIndexPath = [self.fetchedResultsController indexPathForObject:self.reminderToFocus];
        NSIndexPath *reminderToFocusRealIndexPath = [NSIndexPath indexPathForRow:reminderToFocusIndexPath.row inSection:1];
        //[self.tableView scrollToRowAtIndexPath:reminderToFocusRealIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        [self.tableView selectRowAtIndexPath:reminderToFocusRealIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        self.reminderToFocus = NULL;
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    [self setupRemindersFetchedResultsController];
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void) setupRemindersFetchedResultsController {
    NSString *cacheName = @"RemindersMaster";

    [NSFetchedResultsController deleteCacheWithName:cacheName];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSString *entityName = @"Reminder";
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"alarm" ascending:YES];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:YES];
    //NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number == %@", self.itemToEdit];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:cacheName];
    
    [aFetchedResultsController.fetchRequest setPredicate:predicate];
    
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
}

// этой функцией определяем, что редактировать (удалять свайпом) можно только ячейки с напоминаниями
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && (indexPath.row + 1 != [tableView numberOfRowsInSection:1])) {
        return YES;
    } else return NO;
}

// удаление напоминаний свайпом по ячейкам
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        NSManagedObject *objToDelete = [self.fetchedResultsController objectAtIndexPath:realIndexPath];
        
        [self deleteReminder:objToDelete];
    }
}

- (void)deleteReminder:(NSManagedObject *)reminderToDelete
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    [context deleteObject:reminderToDelete];
    
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    // !!!: TODO test and delete number if it exist and is temp
    if (self.fetchedResultsController.fetchedObjects.count < 1 && self.itemToEdit && ((NSString *)[self.itemToEdit valueForKey:@"temp"]).boolValue) {
        //[self setContactFromAdressBook:FALSE];
        [context deleteObject:self.itemToEdit];
        [context save:&error];
        self.itemToEdit = NULL;
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    /*
    if ([self.itemToEdit valueForKey:@"reminder"] != NULL) {
        NSSet *reminders = [self.itemToEdit valueForKey:@"reminder"];
        if ([reminders count] > 0) {
            phoneReminders = [NSArray arrayWithArray:[reminders allObjects]];
        }
    }
     */

    parentView.shouldReloadRemindersTable = TRUE;
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableViewRowAnimation rowAnimation = UITableViewRowAnimationAutomatic;
    if (!self.isViewLoaded || !self.view.window) rowAnimation = UITableViewRowAnimationNone;
    
    switch(type) {
        case NSFetchedResultsChangeInsert: {
            NSArray *visibleCells = [self.tableView visibleCells];
            for (UITableViewCell *cell in visibleCells) {
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:cell] animated:NO];
            }
            NSIndexPath *realNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];
            [self.tableView insertRowsAtIndexPaths:@[realNewIndexPath] withRowAnimation:rowAnimation];
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
            [self.tableView deleteRowsAtIndexPaths:@[realIndexPath] withRowAnimation:rowAnimation];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
            NSManagedObject *reminder = [_fetchedResultsController objectAtIndexPath:indexPath];
            ENReminderCell *reminderCell = (ENReminderCell *)[self.tableView cellForRowAtIndexPath:realIndexPath];
            reminderCell.fieldMessage.text = [reminder valueForKey:@"notification"];
            [reminderCell setDate:[reminder valueForKey:@"alarm"]];
            break;
        }
        case NSFetchedResultsChangeMove: {
            NSIndexPath *realIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:1];
            NSIndexPath *realNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];
            [self.tableView deleteRowsAtIndexPaths:@[realIndexPath] withRowAnimation:rowAnimation];
            [self.tableView insertRowsAtIndexPaths:@[realNewIndexPath] withRowAnimation:rowAnimation];
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return NSLocalizedString(@"REMINDERS_SECTION", nil);
    }
    else return nil;
}

#define kReminderSection 1
#define kReminderNoteRow 1
#define kReminderDateRow 2
#define kReminderDateHeigh 160

#define kNumberSearchSection 0
#define kNumberRow 0
#define kNumberSearchRow 2

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.tableView.rowHeight;
    
    switch (indexPath.section) {
            /*
        case kReminderSection: {
            if (!self.remindSwitch.on && (indexPath.row == kReminderNoteRow || indexPath.row == kReminderDateRow)) {
                height = 0.0f;
            } else if (self.remindSwitch.on && indexPath.row == kReminderDateRow) {
                height = kReminderDateHeigh;
            }
            break;
        }*/
            
        case kNumberSearchSection: {
            if (indexPath.row == kNumberSearchRow) {
                if (self.navigationController.navigationBarHidden) {
                    height = [UIScreen mainScreen].bounds.size.height - _mainTableView.rowHeight - 20;
                }
                else {
                    height = 0;
                }
            } else if (indexPath.row == kNumberRow && self.navigationController.navigationBarHidden) {
                height = 0;
            }
            break;
        }
            
        default:
            break;
    }
       
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSInteger totalRows = [tableView numberOfRowsInSection:indexPath.section] - 1;
        if (indexPath.row == totalRows && ![_fieldNumber.text length]) {
            [self highlightNumberField];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else {
            [self performSegueWithIdentifier:@"NewReminderSegue" sender:cell];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) { // ячейки для первой секции (номер и имя)
        case 0:
            switch (indexPath.row) { // ячейка с номером
                case 0: {
                    cell = [self loadCellWithIdentifier:@"ENPhoneNumberCell" AndClass:[ENPhoneNumberCell class] ForTableView:tableView];
                    _cellNumber = cell;
                    ENPhoneNumberCell *phoneNumberCell = (ENPhoneNumberCell *)cell;
                    _fieldNumber = phoneNumberCell.fieldNumber;
                    _buttonAdressBook = phoneNumberCell.buttonAddressBook;
                    [_buttonAdressBook addTarget:self action:@selector(addFromAdressBook:) forControlEvents:UIControlEventTouchUpInside];
                    if ([UserSettings boolForKey:@"PhoneFormat"]) { // если форматирование номеров включено в настройках
                        _fieldNumber.delegate = self;
                    }
                    if (self.itemToEdit) { // если редактируем
                        _fieldNumber.text = [[self.itemToEdit valueForKey:@"number"] description]; // заполяем поле номера
                        [self setContactFromAdressBook:((NSString *)[self.itemToEdit valueForKey:@"temp"]).boolValue]; // проверяем, является ли наш контакт импортированным из адресной книги телефона, и применяем необходимые настройки
                    }
                    if (!self.itemToEdit) { // если создаем новый - добавляем прослушивание события (меняем подсказку в поле имени)
                        [_fieldNumber addTarget:self action:@selector(fieldNumberChanged:) forControlEvents:UIControlEventEditingChanged];
                    }
                    break;
                }
                case 1: { // ячейка с именем
                    cell = [self loadCellWithIdentifier:@"ENNameCell" AndClass:[ENNameCell class] ForTableView:tableView];
                    //cell = [tableView dequeueReusableCellWithIdentifier:@"ENNameCell"];
                    _cellTitle = cell;
                    _cellTitle.separatorInset = UIEdgeInsetsZero;
                    ENNameCell *nameCell = (ENNameCell *)cell;
                    _fieldTitle = nameCell.fieldTitle;
                    _numberOkButton = nameCell.numberOkButton;
                    // события для отображения меню выбора имени из имеющихся контактов (выводится только если телефонный номер пуст)
                    [_fieldTitle addTarget:self action:@selector(nameFieldEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
                    [_fieldTitle addTarget:self action:@selector(nameFieldEditingEnd:) forControlEvents:UIControlEventEditingDidEnd];
                    [_fieldTitle addTarget:self action:@selector(titleChanged:) forControlEvents:UIControlEventEditingChanged];
                    [_numberOkButton addTarget:self action:@selector(numberOkButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                    
                    if (self.itemToEdit) {
                        _fieldTitle.text = [[self.itemToEdit valueForKey:@"title"] description];
                        [nameCell setTextHint:false];
                    }
                    break;
                }
                case 2: { // скрытая ячейка с tableview - в нее выводится меню для выбора контактов из имеющихся в приложении
                    cell = [tableView dequeueReusableCellWithIdentifier:@"RINumberSearchCell"]; // ячейка из storyboard (класса TNCellWithTable)
                    _cellNumberSearch = (TNCellWithTable *)cell;
                    _cellNumberSearch.managedObjectContext = self.managedObjectContext;
                    break;
                }
                    
                default:
                    break;
            }
            break;
        case 1: { // секция с напоминаниями
            NSManagedObject *reminder;
            if (_fetchedResultsController.fetchedObjects.count > indexPath.row) {
                NSIndexPath *reminderIndex = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
                reminder = [_fetchedResultsController objectAtIndexPath:reminderIndex];
            }
            if (reminder != nil) { // ячейка с напоминанием
                cell = [self loadCellWithIdentifier:@"ENReminderCell" AndClass:[ENReminderCell class] ForTableView:tableView];
                ENReminderCell *reminderCell = (ENReminderCell *)cell;
                reminderCell.fieldMessage.text = [reminder valueForKey:@"notification"];
                [reminderCell setDate:[reminder valueForKey:@"alarm"]];
            }
            else { // ячейка-кнопка создания нового напоминания
                cell = [tableView dequeueReusableCellWithIdentifier:@"RINewReminderCell"];
                newReminderCell = cell;
            }
            break;
        }
        case 2: // секция с кнопкой удаления текущего номера и всех напоминаний в нем
            switch (indexPath.row) {
                case 0: {
                    cell = [self loadCellWithIdentifier:@"ENDeleteCell" AndClass:[ENDeleteCell class] ForTableView:tableView];
                    _cellDelete = cell;
                    ENDeleteCell *delCell = (ENDeleteCell *)cell;
                    _buttonDelete = delCell.buttonDelete;
                    deleteButtonText = _buttonDelete.titleLabel.text;
                    if (self.itemToEdit) { // отображается только в режиме редактирования
                        [_buttonDelete addTarget:self action:@selector(deleteNumber:) forControlEvents:UIControlEventTouchUpInside];
                        _cellDelete.hidden = NO;
                    }
                    break;
                }
                default:
                    break;
            }
            break;
            
        default:
            break;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
            break;
            
        case 1: {
            NSInteger count = 1;
            NSArray *reminders = [self.itemToEdit valueForKeyPath:@"reminder"];
            if (reminders != nil) count += reminders.count;
            return count;
            break;
        }
        case 2:
            return 1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) fillFields
{
    if (self.itemToEdit) {
        self.cellDelete.hidden = NO;
        self.fieldNumber.text = [[self.itemToEdit valueForKey:@"number"] description];
        self.fieldTitle.text = [[self.itemToEdit valueForKey:@"title"] description];
        [self setContactFromAdressBook:((NSString *)[self.itemToEdit valueForKey:@"temp"]).boolValue];
        if ([self.itemToEdit valueForKey:@"reminder"] != NULL) {
            /*
            NSArray *reminders = [self.itemToEdit valueForKey:@"reminder"];
            if ([reminders count] > 0) {
                phoneReminders = reminders;
            }
             */
        }
    }
}

// подготовка к переходу на другой view (для редактирования напоминания)
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual: @"returnToMainViewFromNewNumber"]) {
        return;
    }
    
    FREditReminderViewController *destination = [segue destinationViewController];
    // !!!: TODO check if destination is EditReminderView
    if (![destination.title  isEqual: NSLocalizedString(@"SETTINGS_VIEW", @"Settings")]) {
        destination.parentNumber = self.itemToEdit;
        if ([sender isKindOfClass:[ENReminderCell class]]) {
            ENReminderCell *cell = (ENReminderCell *)sender;
            //NSIndexPath *itemIndexPath = [NSIndexPath indexPathForRow:cell.indexPath.row inSection:0];//cell.indexPath;//[self.tableViewNumbers indexPathForCell:cell];
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForRow:[self.tableView indexPathForCell:cell].row inSection:0];
            destination.itemToEdit = [_fetchedResultsController objectAtIndexPath:itemIndexPath];
        }
        else {
            destination.itemToEdit = nil;
        }
        
        //destination.managedObjectContext = self.managedObjectContext;
    }
    destination.managedObjectContext = self.managedObjectContext;
}

- (IBAction)saveNumber:(id)sender
{
    if (isInnerEdit && (![_fieldNumber.text isEqualToString:[_itemToEdit valueForKey:@"number"]] || ![_fieldTitle.text isEqualToString:[_itemToEdit valueForKey:@"title"]])) {
        //show confirmation dialog
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit number" message:[NSString stringWithFormat:@"Are you sure you want to edit the record '%@'?", [_itemToEdit valueForKey:@"title"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [alert show];
        return;
    }
    if ([self saveTheNumber: NO]) {
        [self performSegueWithIdentifier:@"returnToMainViewFromNewNumber" sender:self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        if ([self saveTheNumber: NO]) {
            [self performSegueWithIdentifier:@"returnToMainViewFromNewNumber" sender:self];
        }
    }
}

#define kPlaceHolderColor "UIDeviceRGBColorSpace 0 0 0.0980392 0.22"

// подсветка строки номера (если пользователь нажмет сохранить при пустом поле)
- (void) highlightNumberField
{
    NSString *placeholderColor = [_fieldNumber.attributedPlaceholder attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
    
    if ([[placeholderColor description] isEqual: @kPlaceHolderColor]) {
        NSString *placeholderText = _fieldNumber.placeholder;
        [UIView transitionWithView:_fieldNumber
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
                        }
                        completion:^(BOOL finished){[UIView transitionWithView:_fieldNumber
                                                                      duration:1.0f
                                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                                    animations:^{
                                                                        _fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: placeholderColor}];
                                                                    }
                                                                    completion:nil];}];
    }
}

// подсветка строки создания нового напоминания (если редактируется импортированный из АК телефона номер и пользователь попытался сохранить, не создав напоминания)
- (void) highlightNewReminder
{
    UILabel *newReminderLabel;
    for (UIView *subView in newReminderCell.contentView.subviews) {
        if ([subView isKindOfClass:[UILabel class]]) {
            newReminderLabel = (UILabel*)subView;
            break;
        }
    }

    if (newReminderLabel != NULL) {
        UIColor *labelColor = newReminderLabel.textColor;
        if (labelColor != [UIColor redColor]) {
            [UIView transitionWithView:newReminderLabel
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                [newReminderLabel setTextColor:[UIColor redColor]];
                            }
                            completion:^(BOOL finished){[UIView transitionWithView:newReminderLabel
                                                                          duration:1.0f
                                                                           options:UIViewAnimationOptionTransitionCrossDissolve
                                                                        animations:^{
                                                                            [newReminderLabel setTextColor:labelColor];
                                                                        }
                                                                        completion:nil];}];
        }
    }
}

- (NSManagedObject *)saveTheNumber: (BOOL)setFRC
{
    if (![_fieldNumber.text length]) {
        [self highlightNumberField];
        //_fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
        return NULL;
    }
    
    if (_isContactFromAdressBook && !self.itemToEdit && self.navigationController.visibleViewController == self) {
        //highlight add new reminder
        [self highlightNewReminder];
        return NULL;
    }
    
    parentView.shouldReloadNumbersTable = TRUE;
    
    NSManagedObject *newPhone;
    if (self.itemToEdit) {
        newPhone = self.itemToEdit;
    }
    else {
        newPhone = [NSEntityDescription insertNewObjectForEntityForName:@"PhoneNumber" inManagedObjectContext:self.managedObjectContext];
        //[newPhone setValue:[NSDate date] forKey:@"created"];
    }
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    NSString *titleText = _fieldTitle.text;
    titleText = [titleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [newPhone setValue:_fieldNumber.text        forKey:@"number"];
    [newPhone setValue:titleText                forKey:@"title"];
    [newPhone setValue:@(_isContactFromAdressBook) forKey:@"temp"];
    
    [newPhone setValue:[NSDate date] forKey:@"modified"];
    // Save the context.
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    if (setFRC) {
        self.itemToEdit = newPhone;
        self.fetchedResultsController = [self fetchedResultsController];
    }
    
    return newPhone;
}

// устаревший метод - не используется
- (IBAction)OLDsaveNumber:(id)sender {
    if (![_fieldNumber.text length]) {
        NSString *placeholderText = _fieldNumber.placeholder;
        NSString *placeholderColor = [_fieldNumber.attributedPlaceholder attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
        [UIView transitionWithView:_fieldNumber
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
                        }
                        completion:^(BOOL finished){[UIView transitionWithView:_fieldNumber
                                                      duration:1.0f
                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                    animations:^{
                                                        _fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: placeholderColor}];
                                                    }
                                                           completion:nil];}];
        //_fieldNumber.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
        return;
    }
    
    NSManagedObject *newPhone;
    if (self.itemToEdit) {
        newPhone = self.itemToEdit;
    }
    else {
        newPhone = [NSEntityDescription insertNewObjectForEntityForName:@"PhoneNumber" inManagedObjectContext:self.managedObjectContext];
        //[newPhone setValue:[NSDate date] forKey:@"created"];
    }
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    NSString *titleText = _fieldTitle.text;
    titleText = [titleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [newPhone setValue:_fieldNumber.text        forKey:@"number"];
    [newPhone setValue:titleText                forKey:@"title"];
    [newPhone setValue:@(_isContactFromAdressBook) forKey:@"temp"];
    
    /*
    if ([titleText length] > 0) {
        //NSString *firstLetter = [_fieldTitle.text substringToIndex:1];
        //firstLetter = [_fieldTitle.text uppercaseString];
        unichar firstLetter = [titleText characterAtIndex:0];
        if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:firstLetter] || [[NSCharacterSet punctuationCharacterSet] characterIsMember:firstLetter]) {
            [newPhone setValue:@"#" forKey:@"t_firstLetter"];
        } else {
            [newPhone setValue:[[NSString stringWithCharacters:&firstLetter length:1] uppercaseString] forKey:@"t_firstLetter"];
        }
    } else {
        [newPhone setValue:@"" forKey:@"t_firstLetter"];
    }
     */
    
    BOOL toMakeNotif = NO;
    BOOL toClearNotif = NO;
    //Saving reminder
    UIApplication *app = [UIApplication sharedApplication];
    NSString *reminderURI;
    NSManagedObject *newReminder;
    if (self.remindSwitch.on) {
        BOOL reminderExisted = NO;
        if ([newPhone valueForKey:@"reminder"] != NULL) {
            reminderExisted = YES;
        }
        newReminder = [NSEntityDescription insertNewObjectForEntityForName:@"Reminder" inManagedObjectContext:self.managedObjectContext];

//        if ([newPhone valueForKey:@"reminder"] == NULL) {
//            newReminder = [NSEntityDescription insertNewObjectForEntityForName:@"Reminder" inManagedObjectContext:self.managedObjectContext];
//        }
//        else {
//            reminderExisted = YES;
//            newReminder = [newPhone valueForKey:@"reminder"];
//        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitTimeZone | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:self.datePicker.date];
        [dateComponents setSecond:0];
        
        [newReminder setValue:[calendar dateFromComponents:dateComponents] forKey:@"alarm"];
        [newReminder setValue:self.notificationMessageField.text forKey:@"notification"];
        [newReminder setValue:@NO forKey:@"pendingCall"];
        
        NSManagedObject *oldReminder = [newPhone valueForKey:@"reminder"];
        BOOL remindersAreEq = [newReminder isEqual:oldReminder];
        if (!reminderExisted) {
            toClearNotif = NO;
            toMakeNotif = YES;
        } else if (!remindersAreEq) {
            toClearNotif = YES;
            toMakeNotif = YES;
            reminderURI = [[[oldReminder objectID] URIRepresentation] absoluteString];
            [self.managedObjectContext deleteObject:oldReminder];
        } else {
            newReminder = oldReminder;
        }
        
        [newPhone setValue:newReminder forKey:@"reminder"];
    }
    else {
        if ([newPhone valueForKey:@"reminder"] != NULL) {
            toClearNotif = YES;
            NSManagedObject *reminder = [newPhone valueForKey:@"reminder"];
            if (app.applicationIconBadgeNumber > 0 && [[NSDate date] compare:[reminder valueForKey:@"alarm"]] == NSOrderedDescending) {
                app.applicationIconBadgeNumber -= 1;
            }
            reminderURI = [[[reminder objectID] URIRepresentation] absoluteString];
            //delete reminder!
            [self.managedObjectContext deleteObject:reminder];
            [newPhone setValue:NULL forKey:@"reminder"];
        }
    }
    
    [newPhone setValue:[NSDate date] forKey:@"modified"];
    // Save the context.
    NSError *error = nil;

    if (![self.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    // Clearing and creating Local Notification:
    if (toClearNotif) {
        [TNStaticUtils cancelNotification:app :reminderURI];
    }
    if (toMakeNotif) {
        [TNStaticUtils makeCallNotification:app Date:self.datePicker.date ToWho:[_fieldTitle.text length] ? _fieldTitle.text : _fieldNumber.text Message:self.notificationMessageField.text ReminderObject:newReminder];
    }
    
    [self performSegueWithIdentifier:@"returnToMainViewFromNewNumber" sender:self];
}

/*
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    initMainViewInsets = _mainTableView.contentInset;
    _mainTableView.contentInset = UIEdgeInsetsMake(0, 0, 216, 0);
    [_mainTableView scrollRectToVisible:textField.frame animated:NO];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _mainTableView.contentInset = initMainViewInsets;
}
*/

// устаревший метод - не используется
- (IBAction)remindSwitched:(id)sender {
    [self hideKeyboard];
    if (self.remindSwitch.on) {
        //if (_mainTableView.contentInset.bottom < 100) _mainTableView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        self.datePickerCell.hidden = NO;
        self.notificationMessageCell.hidden = NO;
        self.datePickerCell.alpha = 0.0f;
        self.notificationMessageCell.alpha = 0.0f;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.datePickerCell.alpha = 1.0f;
            self.notificationMessageCell.alpha = 1.0f;
        }];
        
    } else {
        [self setContactFromAdressBook:FALSE];
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        [UIView animateWithDuration:0.25
                         animations:^{
                             self.datePickerCell.alpha = 0.0f;
                             self.notificationMessageCell.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             self.datePickerCell.hidden = YES;
                             self.notificationMessageCell.hidden = YES;
                         }];
    }
}

// функции для работы с адресной книгой телефона
- (void)addFromAdressBook: (id)sender
{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    picker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:kABPersonPhoneProperty]];
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
//{
//    // ensure user picked a phone property
//    if(property == kABPersonPhoneProperty)
//    {
//        ABMultiValueRef phone = ABRecordCopyValue(person, property);
//        self.fieldNumber.text = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, ABMultiValueGetIndexForIdentifier(phone, identifier));
//        
//        NSString * firstName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
//        firstName = [firstName length] == 0 ? @"" : firstName;
//        NSString * lastName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
//        lastName = [lastName length] == 0? @"" : lastName;
//        self.fieldTitle.text = [[firstName stringByAppendingString:@" "] stringByAppendingString:lastName];
//        
//        [self dismissViewControllerAnimated:YES completion:nil];
//        [self setContactFromAdressBook:TRUE];
//        return NO;
//    }
//    else
//    {
//        return NO;
//    }
//}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    //[self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person property:property identifier:identifier];
    if(property == kABPersonPhoneProperty)
    {
        ABMultiValueRef phone = ABRecordCopyValue(person, property);
        self.fieldNumber.text = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone, ABMultiValueGetIndexForIdentifier(phone, identifier));
        
        NSString * firstName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        firstName = [firstName length] == 0 ? @"" : firstName;
        NSString * lastName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
        lastName = [lastName length] == 0? @"" : lastName;
        self.fieldTitle.text = [[firstName stringByAppendingString:@" "] stringByAppendingString:lastName];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [self setContactFromAdressBook:TRUE];
    }
}

//- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
//{
//    return YES;
//}

// прячем клаву при прокрутке
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideKeyboard];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
    [self deletingCancel];
}

- (void)deleteNumber:(id)sender
{
    NSString *confTitle = NSLocalizedString(@"DELETE_SURE", "Delete confirm");
    if (self.buttonDelete.titleLabel.text != confTitle) {
        [self.buttonDelete setTitle:confTitle forState:UIControlStateNormal];
        timerToCancelDeleting = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(deletingCancel) userInfo:nil repeats:NO];
    }
    else {
        [self stopTimer];
        if (self.itemToEdit) {
            NSManagedObject *numberToDelete = self.itemToEdit;
            
            NSSet *reminders = [numberToDelete valueForKey:@"reminder"];
            for (NSManagedObject *reminder in reminders) {
                [self.managedObjectContext deleteObject:reminder];
            }
            
            [self.managedObjectContext deleteObject:numberToDelete];
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
            [self performSegueWithIdentifier:@"returnToMainViewFromNewNumber" sender:self];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self endNumbersSearch];
    return [textField endEditing:NO];
}

// фильтрация меню выбора существующих номеров в приложении, по вводу
- (void)nameFieldEditingBegin:(id)sender
{
    if ([_fieldNumber.text length] == 0 && !self.navigationController.navigationBarHidden && !self.itemToEdit) {
        [self startNumbersSearch];
    }
}

- (void)nameFieldEditingEnd:(id)sender
{
    //[self endNumbersSearch];
}

- (void)titleChanged:(id)sender
{
    if (self.navigationController.navigationBarHidden) {
        [_cellNumberSearch searchTable: _fieldTitle.text];
    }
}

// убирем меню по нажатию ОК
- (void)numberOkButtonPressed:(id)sender
{
    [self endNumbersSearch];
    [self.fieldTitle endEditing:NO];
}

/*
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return self.navigationController.navigationBarHidden ? 2 : 3;
        case 1:
            return self.navigationController.navigationBarHidden ? 4 : 3;
        case 2:
            return 1;
        default:
            return 0;
    }
}
 */

#define kAddInset 80.0f;

// отображаем меню выбора номера из существующих в приложении
- (void)startNumbersSearch
{
    _cellNumberSearch.mainParentView = self;
    _fieldTitle.returnKeyType = UIReturnKeyDone;
    initScrollPos = self.tableView.contentOffset;
    //initMainViewInsets = _mainTableView.contentInset;
    //CGPoint navBarOrigin = self.navigationController.navigationBar.frame.origin;
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    CGFloat bottomInset = _mainTableView.contentInset.bottom + kAddInset;
    _mainTableView.contentInset = UIEdgeInsetsMake(_mainTableView.contentInset.top, _mainTableView.contentInset.left, bottomInset, _mainTableView.contentInset.right);

    [_mainTableView beginUpdates];
    [_mainTableView endUpdates];
    
    self.cellNumberSearch.hidden = NO;
    self.cellNumberSearch.alpha = 0.0f;
    self.cellNumber.alpha = 1.0f;
    self.numberOkButton.alpha = 0.0f;
    self.numberOkButton.enabled = YES;
    self.numberOkButton.hidden = NO;
    //[self setAutomaticallyAdjustsScrollViewInsets:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.cellNumberSearch.alpha = 1.0f;
        self.cellNumber.alpha = 0.0f;
        self.numberOkButton.alpha = 1.0f;
        _mainTableView.contentOffset = CGPointMake(0, 10); //navBarOrigin;//CGPointZero;
    } completion:^(BOOL finished) {
        self.cellNumber.hidden = YES;
        //[_cellNumberSearch reloadTable];
    }];
    
    _mainTableView.scrollEnabled = NO;
}

// устанавливаем объект номера на редактирование по нажатию на строке из меню
- (void)selectedNumberObject: (NSManagedObject *) object
{
    //self.fieldNumber.text = [[object valueForKey:@"number"] description];
    //self.fieldTitle.text = [[object valueForKey:@"title"] description];
    
    isInnerEdit = TRUE;
    self.itemToEdit = object;
    self.fetchedResultsController = NULL;
    [self fetchedResultsController];
    [self.tableView reloadData];
    
    self.navItem.title = NSLocalizedString(@"EDIT_NUMBER", @"Edit");
    
    [self endNumbersSearch];
    [self hideKeyboard];
}

// скрываем меню
- (void)endNumbersSearch
{
    if (self.navigationController.navigationBarHidden) {
        _fieldTitle.returnKeyType = UIReturnKeyDefault;
        _mainTableView.scrollEnabled = YES;
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        
        [_mainTableView beginUpdates];
        //[_mainTableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        //[_mainTableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
        [_mainTableView endUpdates];
        
        self.cellNumber.alpha = 0.0f;
        self.cellNumber.hidden = NO;
        [UIView animateWithDuration:0.3
                         animations:^{
                             self.cellNumberSearch.alpha = 0.0f;
                             self.cellNumber.alpha = 1.0f;
                             self.numberOkButton.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             self.cellNumberSearch.hidden = YES;
                             self.numberOkButton.enabled = NO;
                             self.numberOkButton.hidden = YES;
                         }];

        CGFloat bottomInset = _mainTableView.contentInset.bottom - kAddInset;
        _mainTableView.contentInset = UIEdgeInsetsMake(_mainTableView.contentInset.top, _mainTableView.contentInset.left, bottomInset, _mainTableView.contentInset.right);
        [self.tableView setContentOffset:initScrollPos animated:YES];
    }
}

- (void)deletingCancel
{
    [self stopTimer];
    if (self.buttonDelete.titleLabel.text != deleteButtonText) {
        [self.buttonDelete setTitle:deleteButtonText forState:UIControlStateNormal];
    }
}

- (void)stopTimer {
    if ([timerToCancelDeleting isValid]) {
        [timerToCancelDeleting invalidate];
    }
}

- (void)setupFormatter {
    _phoneFormat = [[RMPhoneFormat alloc] init];
}

- (void)localeChanged {
    [self setupFormatter];
    
    // Reformat the current phone number
    if (_fieldNumber) {
        NSString *text = _fieldNumber.text;
        NSString *phone = [_phoneFormat format:text];
        _fieldNumber.text = phone;
    }
}

- (void)setContactFromAdressBook:(BOOL)isIt {
    if (isIt != _isContactFromAdressBook) {
        _isContactFromAdressBook = isIt;
        [self.buttonAdressBook setImage:[UIImage imageNamed:(isIt ? @"ButtonAddressBook1" : @"ButtonAddressBook0")] forState:UIControlStateNormal];
        if (isIt) isInnerEdit = FALSE;
    }
}

- (void)fieldNumberChanged:(id)sender {
    ENNameCell *nameCell = (ENNameCell *)_cellTitle;
    if (_fieldNumber.text.length == 0) {
        [nameCell setTextHint:true];
    } else {
        [nameCell setTextHint:false];
    }
}

// функция форматирования телефонных номеров (взята из интернета)
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField != self.fieldNumber) {
        return YES;
    }
    
    [self setContactFromAdressBook:FALSE];
    // For some reason, the 'range' parameter isn't always correct when backspacing through a phone number
    // This calculates the proper range from the text field's selection range.
    UITextRange *selRange = textField.selectedTextRange;
    UITextPosition *selStartPos = selRange.start;
    UITextPosition *selEndPos = selRange.end;
    NSInteger start = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selStartPos];
    NSInteger end = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selEndPos];
    NSRange repRange;
    if (start == end) {
        if (string.length == 0) {
            repRange = NSMakeRange(start - 1, 1);
        } else {
            repRange = NSMakeRange(start, end - start);
        }
    } else {
        repRange = NSMakeRange(start, end - start);
    }
    
    // This is what the new text will be after adding/deleting 'string'
    NSString *txt = [textField.text stringByReplacingCharactersInRange:repRange withString:string];
    // This is the newly formatted version of the phone number
    NSString *phone = [_phoneFormat format:txt];
    //BOOL valid = [_phoneFormat isPhoneNumberValid:phone];
    
    //textField.textColor = valid ? [UIColor blackColor] : [UIColor redColor];
    
    // If these are the same then just let the normal text changing take place
    if ([phone isEqualToString:txt]) {
        return YES;
    } else {
        // The two are different which means the adding/removal of a character had a bigger effect
        // from adding/removing phone number formatting based on the new number of characters in the text field
        // The trick now is to ensure the cursor stays after the same character despite the change in formatting.
        // So first let's count the number of non-formatting characters up to the cursor in the unchanged text.
        NSUInteger cnt = 0;
        for (NSUInteger i = 0; i < repRange.location + string.length; i++) {
            if ([_phoneChars characterIsMember:[txt characterAtIndex:i]]) {
                cnt++;
            }
        }
        
        // Now let's find the position, in the newly formatted string, of the same number of non-formatting characters.
        NSUInteger pos = [phone length];
        NSUInteger cnt2 = 0;
        for (NSUInteger i = 0; i < [phone length]; i++) {
            if ([_phoneChars characterIsMember:[phone characterAtIndex:i]]) {
                cnt2++;
            }
            
            if (cnt2 == cnt) {
                pos = i + 1;
                break;
            }
        }
        
        // Replace the text with the updated formatting
        textField.text = phone;
        
        // Make sure the caret is in the right place
        UITextPosition *startPos = [textField positionFromPosition:textField.beginningOfDocument offset:pos];
        UITextRange *textRange = [textField textRangeFromPosition:startPos toPosition:startPos];
        textField.selectedTextRange = textRange;
        
        return NO;
    }
}

- (IBAction)returnToNumberEdit:(UIStoryboardSegue *)segue
{
    //[self.tableView reloadData];
}

- (void)dealloc {
    _cellNumberSearch.fetchedResultsController = nil;
    _cellNumberSearch.managedObjectContext = nil;
    self.managedObjectContext = nil;
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
}

@end
