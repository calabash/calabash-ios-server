//
//  UIScriptASTClassName.m
//  iLessPainfulServer
//
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//

#import "UIScriptASTClassName.h"
#import "UIScriptASTDirection.h"

@interface UIScriptASTClassName()
- (void) evalDescWith:(UIView*) view result:(NSMutableArray*) res;
- (void) evalChildWith:(UIView*) view result:(NSMutableArray*) res;
- (void) evalParentsWith:(UIView*) view result:(NSMutableArray*) res;
@end

@implementation UIScriptASTClassName
@synthesize className=_className;

- (id) initWithClassName:(NSString *)className {
    self = [super init];
    if (self) {
        _className = [className retain];
        _class = NSClassFromString(self.className);
    }
    return self;
}

- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:8];
    
    for (UIView* view in views) {
        switch (dir) {
            case UIScriptASTDirectionTypeDescendant:
                [self evalDescWith: view result:res];
                break;
            case UIScriptASTDirectionTypeChild:
                [self evalChildWith: view result:res];
                break;
            case UIScriptASTDirectionTypeParent:
                [self evalParentsWith: view result:res];
                break;
        }
    }
    
    
    return res;
}

static NSInteger sortFunction(UIView* v1, UIView* v2, void *ctx) {
    CGPoint p1 = v1.frame.origin;
    CGPoint p2 = v2.frame.origin;
    if (p1.x < p2.x) {
        return -1;
    } else if (p1.x == p2.x) {
        if (p1.y < p2.y) {
            return -1;
        } else if (p1.y == p2.y) {
            return 0;
        } else {
            return 1;
        }
    } else {
        return 1;
    }
    
}
- (void) evalDescWith:(UIView*) view result:(NSMutableArray*) res {
    if ([view isKindOfClass:_class]) {
        [res addObject:view];
    }
    
    for (UIView* subview in [[view subviews] sortedArrayUsingFunction:sortFunction context:view] ) {
        [self evalDescWith:subview result:res];
    }
    
}
- (void) evalChildWith:(UIView*) view result:(NSMutableArray*) res {
    for (UIView* childView in [view subviews]) {
        if ([childView isKindOfClass:_class]) {
            [res addObject:childView];
        }
    }
}
- (void) evalParentsWith:(UIView*) view result:(NSMutableArray*) res {
//    if ([view isKindOfClass:_class]) {
//        [res addObject:view];
//    }
    //I guess view itself isnt part of parents.
    UIView* parentView = [view superview];
    if ([parentView isKindOfClass:_class]) {
        [res addObject:parentView];
    }
    
    if (parentView) {
        [self evalParentsWith:parentView result:res];
    }
    
}


- (NSString*) description {
    return [NSString stringWithFormat:@"view:'%@'",self.className];
}

- (void) dealloc {
    _class = NULL;
    [_className dealloc];_className=nil;
    [super dealloc];
}

@end
