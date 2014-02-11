//
//  MapRoute.h
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "UIScriptParser.h"

@interface LPMapRoute : NSObject <LPRoute>

@property(nonatomic, retain) UIScriptParser *parser;

@end
