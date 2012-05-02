//
//  ScrollOperation.m
//  Calabash
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPScrollToRowOperation.h"

@implementation LPScrollToRowOperation

- (NSString *) description {
	return [NSString stringWithFormat:@"ScrollToRow: %@",_arguments];
}

-(NSIndexPath *)indexPathForRow:(NSUInteger) row inTable:(UITableView*) table {
	int numberOfSections = [table numberOfSections];
    int i=0;
	for(; i< numberOfSections; i++) {
		NSInteger numberOfRowsInSection = [table numberOfRowsInSection:i];
		if (row<numberOfRowsInSection) {
            return [NSIndexPath indexPathForRow:row inSection:i];
        } else {
            row -= numberOfSections;
        }
	}
	return nil;
}

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    if ([_view isKindOfClass:[UIScrollView class]]) {
        UITableView* table = (UITableView*) _view;
        NSNumber *idxNum = [_arguments objectAtIndex:0];
        NSIndexPath* indexPathForRow = [self indexPathForRow:[idxNum unsignedIntegerValue] inTable:table];
        if (!indexPathForRow)
        {
            return nil;
        }
        [table scrollToRowAtIndexPath:indexPathForRow atScrollPosition:UITableViewScrollPositionTop animated:YES];
        return _view;
        
    }
	return nil;
}
@end
