//
//  AOPAspect.m
//  AOPAspect
//
//  Created by Andras Koczka on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AOPAspect.h"
#import "AOPMethod.h"
#import <objc/runtime.h>
#import <objc/message.h>


#pragma mark - Type definitions


typedef enum {
    AOPAspectInspectorTypeBefore,
    AOPAspectInspectorTypeAfter,
    AOPAspectInspectorTypeInstead,
}AOPAspectInspectorType;


#pragma mark - Shared instance


static AOPAspect *aspectManager = NULL;
static Class currentClass;


#pragma mark - Implementation


@implementation AOPAspect {
    NSMutableDictionary *originalMethods;
    AOPMethod *forwardingMethod;
}


#pragma mark - Object lifecycle


- (id)init {
    self = [super init];
    if (self) {
        originalMethods = [[NSMutableDictionary alloc] init];
        forwardingMethod = [[AOPMethod alloc] init];
        forwardingMethod.selector = @selector(forwardingTargetForSelector:); 
        forwardingMethod.implementation = class_getMethodImplementation([self class], forwardingMethod.selector);
        forwardingMethod.method = class_getInstanceMethod([self class], forwardingMethod.selector);
        forwardingMethod.typeEncoding = method_getTypeEncoding(forwardingMethod.method);
    }
    return self;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        aspectManager = [[AOPAspect alloc] init];
    });
}

+ (AOPAspect *)instance {
    return aspectManager;
}


#pragma mark - Helper methods


- (AOPMethod *)methodForKey:(NSString *)key {
    return [originalMethods objectForKey:key];
}

- (NSString *)keyWithClass:(Class)aClass selector:(SEL)selector {
    return [NSString stringWithFormat:@"%@%@", NSStringFromClass(aClass), NSStringFromSelector(selector)];
}

- (SEL)extendedSelectorWithClass:(Class)aClass selector:(SEL)selector {
    return NSSelectorFromString([self keyWithClass:aClass selector:selector]);
}

- (NSMutableDictionary *)originalMethods {
    return originalMethods;
}

#pragma mark - Interceptor registration


- (void)registerClass:(Class)aClass withSelector:(SEL)selector at:(AOPAspectInspectorType)type usingBlock:(aspect_block_t)block {
    NSString *key = [self keyWithClass:aClass selector:selector];
    AOPMethod *method = [originalMethods objectForKey:key];
    
    // Exit point: already registered
    if (method) {
        return;
    }
    
    // Setup the new method
    NSMethodSignature *methodSignature = [aClass instanceMethodSignatureForSelector:selector];
    
    method = [[AOPMethod alloc] init];
    method.selector = selector;
    method.hasReturnValue = [methodSignature methodReturnLength] > 0;
    method.methodSignature = methodSignature;
    method.returnValueLength = [methodSignature methodReturnLength];
    
    // Instance method only for now...
    method.method = class_getInstanceMethod(aClass, selector);
    
    if (method.returnValueLength > sizeof(double)) {
        method.implementation = class_getMethodImplementation_stret(aClass, selector);
    }
    else {
        method.implementation = class_getMethodImplementation(aClass, selector);
    }
    
    switch (type) {
        case AOPAspectInspectorTypeBefore:
            method.beforeBlock = block;
            break;
        case AOPAspectInspectorTypeAfter:
            method.afterBlock = block;
            break;
        case AOPAspectInspectorTypeInstead:
            method.insteadBlock = block;
            break;
    }
    
    [originalMethods setObject:method forKey:key];
    
    IMP interceptor = NULL;
    
    // Check method return type
    if (method.hasReturnValue && method.returnValueLength > sizeof(double)) {
        interceptor = (IMP)_objc_msgForward_stret;
    }
    else {
        interceptor = (IMP)_objc_msgForward;
    }
    
    // Change implementation
    method_setImplementation(method.method, interceptor);
    // Initiate hook to self
    class_addMethod(aClass, forwardingMethod.selector, forwardingMethod.implementation, forwardingMethod.typeEncoding);
    // Add method to self
    class_addMethod([self class], [self extendedSelectorWithClass:aClass selector:selector], method.implementation, method.typeEncoding);
}

- (void)interceptClass:(Class)aClass beforeExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeBefore usingBlock:block];
}

- (void)interceptClass:(Class)aClass afterExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeAfter usingBlock:block];
}

- (void)interceptClass:(Class)aClass insteadExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeInstead usingBlock:block];
}


#pragma mark - Hook


- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (self == [AOPAspect instance]) {
        return nil;
    }
    
    currentClass = [self class];
    return [AOPAspect instance];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(AOPMethod *)[[self originalMethods] objectForKey:NSStringFromSelector([self extendedSelectorWithClass:currentClass selector:aSelector])] methodSignature];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    AOPMethod *method = [self methodForKey:NSStringFromSelector([self extendedSelectorWithClass:currentClass selector:anInvocation.selector])];
    
    [anInvocation setSelector:[self extendedSelectorWithClass:currentClass selector:anInvocation.selector]];
    
    if (method.beforeBlock) {
        method.beforeBlock(anInvocation);
    }
    
    if (method.insteadBlock) {
        method.insteadBlock(anInvocation);
    }
    else {
        [anInvocation invoke];
    }
    
    if (method.afterBlock) {
        method.afterBlock(anInvocation);
    }
}

@end

