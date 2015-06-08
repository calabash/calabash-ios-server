//
//  LPIntrospectionTestView.h
//  calabash
//
//  Created by Chris Fuentes on 6/8/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPIntrospectionTestView : UITableView
@property (strong) NSString *string;
@property (readonly, strong) NSString *readonlyString;
@property (strong, getter=customStringGetter) NSString *customGetterString;
@property (strong, setter=customStringSetter:) NSString *customSetterString;
@property (strong, getter=customStringGetter, setter=customStringSetter:) NSString *customGetterCustomGetterString;
- (void)voidMethodNoArgs;
- (void)voidMethodWithArg:(id)arg;
- (void)voidMethodWithArg:(id)arg andAnother:(id)arg2;
- (id)idMethodNoArgs;
- (id)idMethodWithArg:(id)arg;
- (id)idMethodWithArg:(id)arg andAnother:(id)arg2;
@end
