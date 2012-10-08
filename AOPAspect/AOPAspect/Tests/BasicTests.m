//
//  BasicTests.m
//  AOPAspect
//
//  Created by Marcelo Emmerich on 08.10.12.
//
//

#import <GHUnitIOS/GHUnit.h> 
#import "AOPAspect.h"

@interface BasicTests : GHAsyncTestCase {}

@end


@implementation BasicTests

- (void) testAspectOnNSArrayAfter
{
    int actualCount = 0;
    int expectedCount = 3;
    
    NSArray *array = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
    
    [[AOPAspect instance] interceptClass:[NSArray class]
                  afterExecutingSelector:@selector(count)
                              usingBlock:^(NSInvocation *invocation)
    {
        if( actualCount == expectedCount )
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAspectOnNSArrayAfter)];
        else
            [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testAspectOnNSArrayAfter)];
    }];
    
    actualCount = [array count];
}

- (void) testAspectOnNSArrayBefore
{
    int actualCount = 0;
    int expectedCount = 0;
    
    NSArray *array = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
    
    [[AOPAspect instance] interceptClass:[NSArray class]
                  beforeExecutingSelector:@selector(count)
                              usingBlock:^(NSInvocation *invocation)
     {
         if( actualCount == expectedCount )
             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAspectOnNSArrayBefore)];
         else
             [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testAspectOnNSArrayBefore)];
     }];
    
    actualCount = [array count];
}



@end
