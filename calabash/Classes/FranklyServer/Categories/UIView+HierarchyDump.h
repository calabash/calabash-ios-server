//
//  UIView+HierarchyDump.h
//  calabash
//
//  Created by Olivier Larivain on 3/6/13.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HierarchyDump)

- (NSDictionary *) dumpHierarchyWithMapping: (NSDictionary *) classMapping;

@end
