//
//  LPIntrospectionTestView.m
//  calabash
//
//  Created by Chris Fuentes on 6/8/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPIntrospectionTestView.h"

@interface LPIntrospectionTestView ()
- (void)privateMethod;
- (void)privateMethodWithArg:(id)arg;
- (void)privateMethodWithArg:(id)arg andAnother:(id)arg2;
@end

@implementation LPIntrospectionTestView

- (void)voidMethodNoArgs {}
- (void)voidMethodWithArg:(id)arg {}
- (void)voidMethodWithArg:(id)arg andAnother:(id)arg2 {}
- (void)privateMethod {}
- (void)privateMethodWithArg:(id)arg {}
- (void)privateMethodWithArg:(id)arg andAnother:(id)arg2 {}
- (id)idMethodNoArgs { return nil; }
- (id)idMethodWithArg:(id)arg { return nil; }
- (id)idMethodWithArg:(id)arg andAnother:(id)arg2 { return nil; }


@end
