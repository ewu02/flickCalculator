//
//  calculation.h
//  flickCalculator
//
//  Created by Enming Wu on 7/17/12.
//  Copyright (c) 2012 Enming Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface calculation : NSObject 

// infix operations
- (void)storeLeftOperand:(NSDecimalNumber *)value;
- (void)storeRightOperand:(NSDecimalNumber *)value;
- (void)storeOperator:(NSString *)operator; 
- (NSString *)calculate:(BOOL)rightOperandAsPercent;

@end
