//
//  LPCalabashSelfRegisteringSelectorEngine.h
//  calabash
//
//  Created by Karl Krukow on 03/11/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol SelectorEngine
- (NSArray *)selectViewsWithSelector:(NSString *)query;
@end

@interface CalabashUISpecSelectorEngine : NSObject<SelectorEngine>

@end
