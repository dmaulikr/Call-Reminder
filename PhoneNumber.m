//
//  Call Reminder.m
//  Call Reminder
//
//  Created by Timur Nasyrov on 7/1/14.
//  Copyright (c) 2014 Тимур Насыров. All rights reserved.
//
//  Класс для сохраненных телефонных номеров.

#import "PhoneNumber.h"
#import "Reminder.h"


@implementation PhoneNumber

@dynamic created;
@dynamic modified;
@dynamic note;
@dynamic number;
@dynamic t_firstLetter;
@dynamic temp;
@dynamic title;
@dynamic reminder;

-(void) setTitle:(NSString *)title
{
    [self willChangeValueForKey:@"title"];
    [self setPrimitiveValue:title forKey:@"title"];
    [self didChangeValueForKey:@"title"];
    
    [self willChangeValueForKey:@"t_firstLetter"];
    
    // сохраняем первую букву для построения секций в таблице номеров
    if ([title length] > 0) {
        unichar firstLetter = [title characterAtIndex:0];
        if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:firstLetter] || [[NSCharacterSet punctuationCharacterSet] characterIsMember:firstLetter]) {
            //[self setValue:@"#" forKey:@"t_firstLetter"];
            self.t_firstLetter = @"#";
        } else {
            //[self setValue:[[NSString stringWithCharacters:&firstLetter length:1] uppercaseString] forKey:@"t_firstLetter"];
            self.t_firstLetter = [[NSString stringWithCharacters:&firstLetter length:1] uppercaseString];
        }
    } else {
        //[self setValue:@"" forKey:@"t_firstLetter"];
        self.t_firstLetter = @"";
    }
    
    [self didChangeValueForKey:@"t_firstLetter"];
}

-(void) setModified:(NSDate *)modified
{
    [self willChangeValueForKey:@"modified"];
    [self setPrimitiveValue:modified forKey:@"modified"];
    [self didChangeValueForKey:@"modified"];
    
    if (self.created == NULL) {
        [self willChangeValueForKey:@"created"];
        [self setPrimitiveValue:modified forKey:@"created"];
        [self didChangeValueForKey:@"created"];
    }
}

+ (void) load {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter] addObserver: (id)[self class]
                                                 selector: @selector(objectContextWillSave:)
                                                     name: NSManagedObjectContextWillSaveNotification
                                                   object: nil];
    }
}

+ (void) objectContextWillSave: (NSNotification*) notification {
    NSManagedObjectContext* context = [notification object];
    NSSet* allModified = [context.insertedObjects setByAddingObjectsFromSet: context.updatedObjects];
    NSPredicate* predicate = [NSPredicate predicateWithFormat: @"self isKindOfClass: %@", [self class]];
    NSSet* modifiable = [allModified filteredSetUsingPredicate: predicate];
    [modifiable makeObjectsPerformSelector: @selector(setModified:) withObject: [NSDate date]];
}

@end
