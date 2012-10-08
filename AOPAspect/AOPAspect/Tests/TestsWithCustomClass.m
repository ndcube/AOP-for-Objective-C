//
//  BasicTestsWithCustomClass.m
//  AOPAspect
//
//  Created by Marcelo Emmerich on 08.10.12.
//
//

#import <GHUnitIOS/GHUnit.h> 
#import "AOPAspect.h"
#import "CustomClass.h"

@interface BasicTestsWithCustomClass : GHAsyncTestCase {}
@end

@implementation BasicTestsWithCustomClass

- (void)setUp
{
    [self prepare];
}

- (void) testWithCustomClass
{
    CustomClass * custom = [[CustomClass alloc] init];
    
    [[AOPAspect instance] interceptClass:[CustomClass class]
                  afterExecutingSelector:@selector(computeSomething)
                              usingBlock:^(NSInvocation *invocation)
     {
         [self notify:kGHUnitWaitStatusSuccess];
     }];
    
    [custom computeSomething];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:1];
}

@end
