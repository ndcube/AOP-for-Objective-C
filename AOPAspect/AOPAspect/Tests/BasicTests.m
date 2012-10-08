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

- (void) testAspectOnNSArray
{
    int actualCount = 0;
    int expectedCount = 3;
    
    NSArray *array = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
    
    [[AOPAspect instance] interceptClass:[NSArray class]
                  afterExecutingSelector:@selector(count)
                              usingBlock:^(NSInvocation *invocation)
    {
        if( actualCount == expectedCount )
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testAspectOnNSArray)];
        else
            [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testAspectOnNSArray)];
    }];
    
    actualCount = [array count];
}



@end
