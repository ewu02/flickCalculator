//
//  calculation.m
//  flickCalculator
//
//  Created by Enming Wu on 7/17/12.
//  Copyright (c) 2012 Enming Wu. All rights reserved.
//

#import "calculation.h"

@interface calculation ()

@property NSDecimalNumber *leftOperand;
@property NSDecimalNumber *rightOperand;
@property NSString *operator;

@end

@implementation calculation

@synthesize leftOperand = _leftOperand;
@synthesize rightOperand = _rightOperand;
@synthesize operator = _operator;


- (void)storeLeftOperand:(NSDecimalNumber *)value {
   [self setLeftOperand:value];
}

- (void)storeRightOperand:(NSDecimalNumber *)value {
   [self setRightOperand:value];
}

- (void)storeOperator:(NSString *)operator {
   [self setOperator:operator];
}

//apply operator to firstOperand and secondOperand. 
- (NSString *)calculate:(BOOL)rightOperandAsPercent {
NSDecimalNumberHandler *handler =
      [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:
         NSRoundBankers scale:NSDecimalNoScale
         raiseOnExactness:NO raiseOnOverflow:YES
         raiseOnUnderflow:YES raiseOnDivideByZero:YES];
   
   NSDecimalNumber *result;
   
   @try {
      if (rightOperandAsPercent) {
         [self setRightOperand:
            [self.rightOperand decimalNumberByMultiplyingByPowerOf10:-2]];
         [self setRightOperand:
            [self.leftOperand decimalNumberByMultiplyingBy:
               self.rightOperand]];
      }
      
      if ([@"Add" isEqualToString:self.operator]) {
         result = [self.leftOperand decimalNumberByAdding:
                     self.rightOperand withBehavior:handler];
      } else if ([@"Subtract" isEqualToString :self.operator]) {
         result = [self.leftOperand decimalNumberBySubtracting:
                     self.rightOperand withBehavior:handler];
      } else if ([@"Multiply" isEqualToString :self.operator]) {
         result = [self.leftOperand decimalNumberByMultiplyingBy:
                     self.rightOperand withBehavior:handler];
      } else if ([@"Divide" isEqualToString :self.operator]) {
         result = [self.leftOperand decimalNumberByDividingBy:
                     self.rightOperand withBehavior:handler];
      } else {
         result = self.leftOperand;
      }
   }
   @catch (NSException *exception) {
       NSString *exceptionName = [exception name];
      if ([@"NSDecimalNumberOverflowException" isEqualToString:exceptionName]) {
         return @"ERROR: Overflow";
      } else if ([@"NSDecimalNumberUnderflowException" isEqualToString:
            exceptionName]) {
         return @"ERROR: Underflow";
      } else if ([@"NSDecimalNumberDivideByZeroException" isEqualToString:
            exceptionName]) {
         return @"ERROR: Division By Zero";
      }
   }
   return [result stringValue];
}

@end

