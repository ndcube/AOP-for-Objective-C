//
//  AOPMethod.h
//  AOPAspect
//
//  Created by Andras Koczka on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <objc/runtime.h>

@interface AOPMethod : NSObject

@property (strong, nonatomic) Class baseClass;
@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) SEL extendedSelector;
@property (assign, nonatomic) IMP implementation;
@property (assign, nonatomic) Method method;
@property (assign, nonatomic) const char *typeEncoding;
@property (strong, nonatomic) NSMethodSignature *methodSignature;
@property (assign, nonatomic) BOOL hasReturnValue;
@property (assign, nonatomic) NSUInteger returnValueLength;

@property (strong, nonatomic, readonly) NSMutableDictionary *interceptors;

@end
