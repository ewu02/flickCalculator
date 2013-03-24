//
//  flickGestureRecognizer.m
//  flickCalculator
//
//  Created by Enming Wu on 8/18/12.
//  Copyright (c) 2012 Enming Wu. All rights reserved.
//

#import "flickGestureRecognizer.h"

@implementation flickGestureRecognizer

@synthesize minVelocityReached = _minVelocityReached;

- (id)initWithTarget:(id)target action:(SEL)action {
   self = [super initWithTarget:target action:action];
   if (self) self.minVelocityReached = NO;
   return self;
}


@end
