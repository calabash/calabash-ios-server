//
//  CalabashServer.m
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "CalabashLoader.h"
#import "RequestRouter.h"
#import "LPAsyncPlaybackRoute.h"
#import "CalabashUISpecSelectorEngine.h"
#import "LPUserPrefCommand.h"
#import "LPVersionCommand.h"
#import "LPConditionRoute.h"
#import "LPRecordRoute.h"
#import "FrankCommandRoute.h"
#import <dlfcn.h>


@interface SelectorEngineRegistry
+(void)registerSelectorEngine:(id <SelectorEngine>)engine WithName:(NSString *)name;
@end


@implementation CalabashLoader


+ (void)applicationDidBecomeActive:(NSNotification *)notification {
    [SelectorEngineRegistry registerSelectorEngine:[[CalabashUISpecSelectorEngine alloc] init] WithName:@"calabash_uispec"];
    NSLog(@"Calabash %@ registered with Frank as selector engine named 'calabash_uispec'",kLPCALABASHVERSION);

    
    LPRecordRoute *recordRoute = [LPRecordRoute new];
    [[RequestRouter singleton] registerRoute:recordRoute];
    [recordRoute release];

    
    LPAsyncPlaybackRoute *apr =[LPAsyncPlaybackRoute new];
    [[RequestRouter singleton] registerRoute:apr];
    [apr release];

    LPConditionRoute *condition =[LPConditionRoute new];
    [[RequestRouter singleton] registerRoute:condition];
    [condition release];

    
    
    [[FrankCommandRoute singleton] registerCommand:[[[LPUserPrefCommand alloc] init] autorelease]
                                          withName:@"userprefs"];
    [[FrankCommandRoute singleton] registerCommand:[[[LPVersionCommand alloc] init] autorelease]
                                          withName:@"calabash_version"];
    
    
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:@"UIApplicationDidBecomeActiveNotification"
                                               object:nil];
    dlopen([@"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation" fileSystemRepresentation], RTLD_LOCAL);
}


@end
