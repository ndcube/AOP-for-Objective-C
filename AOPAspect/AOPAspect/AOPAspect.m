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
    AOPAspectInspectorTypeBefore = 0,
    AOPAspectInspectorTypeInstead = 1,
    AOPAspectInspectorTypeAfter = 2
}AOPAspectInspectorType;


#pragma mark - Shared instance


static AOPAspect *aspectManager = NULL;
static NSMutableDictionary *currentClasses;


#pragma mark - Implementation


@implementation AOPAspect {
    NSMutableDictionary *originalMethods;
    AOPMethod *forwardingMethod;
    aspect_block_t methodInvoker;
}


#pragma mark - Object lifecycle


- (id)init {
    self = [super init];
    if (self) {
        originalMethods = [[NSMutableDictionary alloc] init];
        currentClasses = [[NSMutableDictionary alloc] init];
        forwardingMethod = [[AOPMethod alloc] init];
        forwardingMethod.selector = @selector(forwardingTargetForSelector:);
        forwardingMethod.implementation = class_getMethodImplementation([self class], forwardingMethod.selector);
        forwardingMethod.method = class_getInstanceMethod([self class], forwardingMethod.selector);
        forwardingMethod.typeEncoding = method_getTypeEncoding(forwardingMethod.method);
        methodInvoker = [^(NSInvocation *invocation) {
            [invocation invoke];
        } copy];
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


- (NSString *)addInterceptorBlock:(aspect_block_t)block toMethod:(AOPMethod *)method withType:(AOPAspectInspectorType)type {
    NSMutableArray *interceptors = [method.interceptors objectForKey:[NSNumber numberWithInt:type]];
    
    if (!interceptors) {
        interceptors = [[NSMutableArray alloc] init];
        [method.interceptors setObject:interceptors forKey:[NSNumber numberWithInt:type]];
    }
    
    NSDictionary *interceptor = [NSDictionary dictionaryWithObject:[block copy] forKey:[NSDate date]];
    
    if (type == AOPAspectInspectorTypeInstead && interceptors.count == 1) {
        if ([[[interceptors lastObject] allValues] lastObject] == (id)methodInvoker) {
            [interceptors removeLastObject];
        }
    }
    
    [interceptors addObject:interceptor];
    
    return [NSString stringWithFormat:@"%p", interceptor];
}


- (NSString *)registerClass:(Class)aClass withSelector:(SEL)selector at:(AOPAspectInspectorType)type usingBlock:(aspect_block_t)block {
    NSString *key = [self keyWithClass:aClass selector:selector];
    AOPMethod *method = [originalMethods objectForKey:key];
    
    // Setup the new method
    if (!method) {
        NSMethodSignature *methodSignature = [aClass instanceMethodSignatureForSelector:selector];
        
        method = [[AOPMethod alloc] init];
        method.baseClass = aClass;
        method.selector = selector;
        method.extendedSelector = [self extendedSelectorWithClass:aClass selector:selector];
        method.hasReturnValue = [methodSignature methodReturnLength] > 0;
        method.methodSignature = methodSignature;
        method.returnValueLength = [methodSignature methodReturnLength];
        
        // Add the default method invoker block
        [self addInterceptorBlock:methodInvoker toMethod:method withType:AOPAspectInspectorTypeInstead];
        
        // Instance method only for now...
        method.method = class_getInstanceMethod(aClass, selector);
        
        if (method.returnValueLength > sizeof(double)) {
            method.implementation = class_getMethodImplementation_stret(aClass, selector);
        }
        else {
            method.implementation = class_getMethodImplementation(aClass, selector);
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
        class_addMethod([self class], method.extendedSelector, method.implementation, method.typeEncoding);
    }
    
    // Set the interceptor block
    return [self addInterceptorBlock:block toMethod:method withType:type];
}

- (NSString *)interceptClass:(Class)aClass beforeExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    return [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeBefore usingBlock:block];
}

- (NSString *)interceptClass:(Class)aClass afterExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    return [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeAfter usingBlock:block];
}

- (NSString *)interceptClass:(Class)aClass insteadExecutingSelector:(SEL)selector usingBlock:(aspect_block_t)block {
    return [self registerClass:aClass withSelector:selector at:AOPAspectInspectorTypeInstead usingBlock:block];
}

- (void)deregisterMethod:(AOPMethod *)method {
    
    method_setImplementation(method.method, method.implementation);
    [originalMethods removeObjectForKey:[self keyWithClass:method.baseClass selector:method.selector]];
}

- (void)removeInterceptorWithKey:(NSString *)key {
    
    for (AOPMethod *method in [originalMethods allValues]) {
        NSInteger interceptorCount = 0;
        
        for (int i = 0; i < 3; i++) {
            NSMutableArray *interceptors = [method.interceptors objectForKey:[NSNumber numberWithInt:i]];
            
            for (NSDictionary *dictionary in [NSArray arrayWithArray:interceptors]) {
                
                if ([[NSString stringWithFormat:@"%p", dictionary] isEqualToString:key]) {
                    [interceptors removeObject:dictionary];
                    
                    // Add back the default method invoker block
                    if (i == AOPAspectInspectorTypeInstead && interceptors.count == 0) {
                        [self addInterceptorBlock:methodInvoker toMethod:method withType:i];
                    }
                }
            }
            
            interceptorCount += interceptors.count;
        }
        
        if (interceptorCount == 1) {
            [self deregisterMethod:method];
        }
    }
}


#pragma mark - Hook


- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (self == [AOPAspect instance]) {
        return nil;
    }
    
    [currentClasses setObject:[self class] forKey:[[NSThread currentThread] description]];
    
    return [AOPAspect instance];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(AOPMethod *)[[self originalMethods] objectForKey:NSStringFromSelector([self extendedSelectorWithClass:[currentClasses objectForKey:[[NSThread currentThread] description]] selector:aSelector])] methodSignature];
}

- (void)executeInterceptorsOfMethod:(AOPMethod *)method withInvocation:(NSInvocation *)anInvocation {
    
    // Executes interceptors before, instead and after
    for (int i = 0; i < 3; i++) {
        NSArray *interceptors = [method.interceptors objectForKey:[NSNumber numberWithInt:i]];
        
        for (NSDictionary *interceptor in interceptors) {
            aspect_block_t block = [[interceptor allValues] lastObject];
            block(anInvocation);
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    AOPMethod *method = [self methodForKey:NSStringFromSelector([self extendedSelectorWithClass:[currentClasses objectForKey:[[NSThread currentThread] description]] selector:anInvocation.selector])];
    
    [anInvocation setSelector:method.extendedSelector];
    
    [self executeInterceptorsOfMethod:method withInvocation:anInvocation];
}

@end
