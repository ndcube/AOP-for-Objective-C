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

- (void)setUp
{
    [self prepare];
}

- (void) testWithInheritedClass
{
    int valueBeforeAfterAdvice=0;
    
    InheritedCustomClass * inherited = [[InheritedCustomClass alloc] init];
    
    [[AOPAspect instance] interceptClass:[CustomClass class]
                  afterExecutingSelector:@selector(computeSomething)
                              usingBlock:^(NSInvocation *invocation)
     {
         if( valueBeforeAfterAdvice == 42 )
             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testWithInheritedClass)];
         else
             [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testWithInheritedClass)];
     }];
    
    valueBeforeAfterAdvice = [inherited computeSomething];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:1];
}


@end
