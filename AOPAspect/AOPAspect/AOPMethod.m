//
//  AOPMethod.m
//  AOPAspect
//
//  Created by Andras Koczka on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AOPMethod.h"

@implementation AOPMethod

@synthesize selector;
@synthesize implementation;
@synthesize method;
@synthesize typeEncoding;
@synthesize methodSignature;
@synthesize hasReturnValue;
@synthesize returnValueLength;

@synthesize beforeBlock;
@synthesize afterBlock;
@synthesize insteadBlock;

@end
