//
//  flickGestureRecognizer.h
//  flickCalculator
//
//  Created by Enming Wu on 8/18/12.
//  Copyright (c) 2012 Enming Wu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface flickGestureRecognizer : UIPanGestureRecognizer

@property (nonatomic) BOOL minVelocityReached;
- (id)initWithTarget:(id)target action:(SEL)action;

@end
