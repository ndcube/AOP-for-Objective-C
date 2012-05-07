AOPAspect is a small aspect oriented programming library for iOS. Licensed under the MIT license.

**Note:** Current implementation is **not thread safe**. Also there is a **bug** when intercepting the same method in subclasses when it is only implemented on the superclass. If all the subclasses override the method than it works OK. I will try to fix these in the next few days.

For more information on how it works, please check out the my article:

<http://codeshaker.blogspot.com/2012/01/aop-delivered.html>
