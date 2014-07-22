//
//  LPCalabashFrankRegistrar.h
//  calabash
//
//  Created by Karl Krukow on 22/07/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SelectorEngine <NSObject>

@optional

/* Multi-window behaviour for selector engines that only implement this method is
 * undefined. If an engine supports querying across multiple windows, it should
 * implement the below method instead.
 */
- (NSArray *) selectViewsWithSelector:(NSString *)selector;

/* If a selector engine implements this method, it should return all matching views in
 * any of the windows provided. Currently only supported on iOS.
 */
- (NSArray *) selectViewsWithSelector:(NSString *)selector inWindows:(NSArray *)windows;

@end

@interface SelectorEngineRegistry : NSObject{
}

+ (void) registerSelectorEngine:(id<SelectorEngine>)engine WithName:(NSString *)name;
+ (NSArray *) selectViewsWithEngineNamed:(NSString *)engineName usingSelector:(NSString *)selector;

+ (NSArray *)getEngineNames;
@end

@interface LPCalabashFrankRegistrar : NSObject<SelectorEngine>

@end
