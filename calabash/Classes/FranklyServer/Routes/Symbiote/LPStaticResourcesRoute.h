//
//  StaticResourcesRoute.h
//  Frank
//
//  Created by phodgson on 5/30/10.
//  Copyright 2010 ThoughtWorks. See NOTICE file for details.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"

@interface LPStaticResourcesRoute : NSObject<LPRoute>

- (id) initWithStaticResourceSubDir:(NSString *)resourceSubdir;

@end