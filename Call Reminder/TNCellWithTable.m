//
//  TNCellWithTable.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/26/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import "TNCellWithTable.h"
#import "FREditNumberViewController.h"
#import "TNCellNumberSearch.h"

@implementation TNCellWithTable

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.bounds = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height - 44 - 20);
        cellTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        cellTableView.tag = 100;
        cellTableView.delegate = self;
        cellTableView.dataSource = self;
        cellTableView.rowHeight = 55;
        [self addSubview:cellTableView];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    UITableView *subMenuTableView =(UITableView *) [self viewWithTag:100];
    subMenuTableView.userInteractionEnabled = YES;
    subMenuTableView.allowsSelection = YES;
    subMenuTableView.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height - 44 - 20); //CGRectMake(0.2, 0.3, self.bounds.size.width-5,    self.bounds.size.height-5);//set the frames for tableview
}

- (void)awakeFromNib
{
    // Initialization code
    self.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height - 44 - 20);
    self.bounds = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height - 44 - 20);
    cellTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    cellTableView.tag = 100;
    cellTableView.delegate = self;
    cellTableView.dataSource = self;
    cellTableView.rowHeight = 55;
    [cellTableView setUserInteractionEnabled:YES];
    [cellTableView setAllowsSelection:YES];
    [self addSubview:cellTableView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_mainParentView.view endEditing:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)selectedInnerCellAtIndexPath:(NSIndexPath *)indexPath
{
    //[self deselectRowAtIndexPath:indexPath animated:YES];
    [_mainParentView selectedNumberObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"%@", [[object valueForKey:@"title"] description]);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"%f", tableView.frame.size.height);
    //NSLog(@"%f", self.frame.size.height);
    //tableView.frame = self.frame;
    //NSLog(@"%d %d %d", self.userInteractionEnabled, cellTableView.allowsSelection, cellTableView.userInteractionEnabled);
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TNCellNumberSearch *cell = (TNCellNumberSearch *)[self loadCellWithIdentifier:@"TNCellNumberSearch" ForTableView:tableView];
    [self configureCellPhoneNumber:cell atIndexPath:indexPath];
    //NSLog(@"%d %ld", cell.userInteractionEnabled, cell.selectionStyle);
    return cell;
}

- (void)configureCellPhoneNumber:(TNCellNumberSearch *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.title.text = [[object valueForKey:@"title"] description];
    cell.number.text = [[object valueForKey:@"number"] description];
    cell.selfIndexPath = indexPath;
    cell.parentTable = self;
    //cell.buttonEditNumber.itemToEdit = indexPath;
    //[cell.buttonEditNumber addTarget:self action:@selector(numberEditButton:event:) forControlEvents:UIControlEventTouchUpInside];
}

- (UITableViewCell *)loadCellWithIdentifier: (NSString *) simpleTableIdentifier ForTableView: (UITableView *) tableView
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (![cell isKindOfClass:[UITableViewCell class]]) cell = nil;
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:simpleTableIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

- (void)reloadTable {
    [cellTableView reloadData];
}

- (void)searchTable: (NSString *)searchString {
    NSPredicate *predicate = nil;
    if ([searchString length]) {
        predicate = [NSPredicate predicateWithFormat:@"temp != YES AND title contains[cd] %@", searchString];
    } else {
        self.fetchedResultsController = nil;
        [self fetchedResultsController];
    }
    
    [self fetchedResultsControllerWithPredicate:predicate];
    [self reloadTable];
}

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

- (void)setupFetchedResultsController {
    NSString *cacheName = @"NumbersSearcher";
    [NSFetchedResultsController deleteCacheWithName:cacheName];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSString *entityName = @"PhoneNumber";
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temp != YES"];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setFetchBatchSize:10];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:cacheName];
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

@end
