//
//  LPNDElementWrapper.m
//  ProjectX
//
//  Created by Karl Krukow on 28/01/12.
//  Copyright (c) 2012 Danske Bank Group. All rights reserved.
//

#import "LPNDElementWrapper.h"

@implementation LPNDElementWrapper
@synthesize webElement;

-(id) initWithElement:(NDWebElement*) element {
    self = [super init];
    if (self) {
        self.webElement = element;
    }
    return self;
}

-(BOOL) isHidden {
    return ![self.webElement isDisplayed];
}

-(NSString*) description {
    return [NSString stringWithFormat:@"<%@>%@</%@>",self.webElement.tagName, self.webElement.text,self.webElement.tagName];
}


@end
