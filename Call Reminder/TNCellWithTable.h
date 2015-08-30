//
//  TNCellWithTable.h
//  Call Reminder
//
//  Created by Timur Nasyrov on 6/26/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FREditNumberViewController;

@interface TNCellWithTable : UITableViewCell <UITableViewDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource>
{
    UITableView *cellTableView;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) FREditNumberViewController *mainParentView;

- (void)reloadTable;
- (void)searchTable: (NSString *)searchString;
- (void)selectedInnerCellAtIndexPath:(NSIndexPath *)indexPath;

@end
