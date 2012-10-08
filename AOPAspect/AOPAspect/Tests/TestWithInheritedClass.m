//
//  TestWithInheritedClass.m
//  AOPAspect
//
//  Created by Marcelo Emmerich on 08.10.12.
//
//

#import <GHUnitIOS/GHUnit.h>
#import "AOPAspect.h"
#import "InheritedCustomClass.h"

@interface TestWithInheritedClass : GHAsyncTestCase {}

@end

@implementation TestWithInheritedClass

- (void) testWithCustomClass
{
    int valueBeforeAfterAdvice;
    
    InheritedCustomClass * inherited = [[InheritedCustomClass alloc] init];
    
    [[AOPAspect instance] interceptClass:[CustomClass class]
                  afterExecutingSelector:@selector(computeSomething)
                              usingBlock:^(NSInvocation *invocation)
     {
         if( valueBeforeAfterAdvice == 42 )
             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAspectOnNSArrayAfter)];
         else
             [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testAspectOnNSArrayAfter)];
     }];
    
    valueBeforeAfterAdvice = [inherited computeSomething];
}


@end
