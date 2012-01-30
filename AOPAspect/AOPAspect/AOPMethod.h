//
//  AOPMethod.h
//  AOPAspect
//
//  Created by Andras Koczka on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AOPAspect.h"
#import <objc/runtime.h>

@interface AOPMethod : NSObject

@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) IMP implementation;
@property (assign, nonatomic) Method method;
@property (assign, nonatomic) const char *typeEncoding;
@property (strong, nonatomic) NSMethodSignature *methodSignature;
@property (assign, nonatomic) BOOL hasReturnValue;
@property (assign, nonatomic) NSUInteger returnValueLength;

@property (copy, nonatomic) aspect_block_t beforeBlock;
@property (copy, nonatomic) aspect_block_t afterBlock;
@property (copy, nonatomic) aspect_block_t insteadBlock;

@end
