//
//  ewuViewController.m
//  flickCalculator
//
//  Created by Enming Wu on 7/17/12.
//  Copyright (c) 2012 Tufts. All rights reserved.
//

#import "ewuViewController.h"
#import "calculation.h"
#import "flickGestureRecognizer.h"

#define MIN_FLICKSPEED 350

@interface ewuViewController ()

//displays formatted screenValue value.
@property (weak, nonatomic) IBOutlet UILabel *screen;

@property (nonatomic) NSString *screenValue;
@property (nonatomic, strong) calculation *calc;
@property (nonatomic) BOOL stillInsertingDigits;
@property (nonatomic) BOOL waitingForOperand;
@property (nonatomic) BOOL equalPressed;
@property (nonatomic) BOOL operatorPressed;
@property (nonatomic) BOOL insertingSecondOperand; //used for percent operator.
@property (nonatomic) BOOL percentOperatorUsed;
@property (nonatomic) BOOL zeroValueFromDelete;

@end


@implementation ewuViewController

@synthesize screen = _screen;
@synthesize screenValue = _screenValue;
@synthesize calc = _calc;
@synthesize stillInsertingDigits = _stillInsertingDigits;
@synthesize waitingForOperand = _waitingForOperand;
@synthesize equalPressed = _equalPressed;
@synthesize operatorPressed = _operatorPressed;
@synthesize insertingSecondOperand = _insertingSecondOperand;
@synthesize percentOperatorUsed = _percentOperatorUsed;
@synthesize zeroValueFromDelete = _zeroValueFromDelete;

- (calculation *)calc {
   if (!_calc) _calc = [[calculation alloc] init];
   return _calc;
}

//outputs formatted value from type Double.
- (void)displayFormattedScreenValue {      
   NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
   [formatter setRoundingMode:NSNumberFormatterRoundHalfEven];
   [formatter setMaximumFractionDigits:9];
   [formatter setMinimumIntegerDigits:1];
   NSString *decimalTruncatedValue = [formatter stringFromNumber:
      [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   if ([decimalTruncatedValue length] > 15) {
      [formatter setNumberStyle:NSNumberFormatterScientificStyle];
      [formatter setExponentSymbol:@"e"];
      self.screen.text = [formatter stringFromNumber:
         [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   } else {
      self.screen.text = decimalTruncatedValue;
   }
}

- (void)displayUnformattedScreenValue {
   self.screen.text = self.screenValue;
}

- (void)executeInput:(UIButton *)button {
   NSString *buttonName = [button currentTitle];
   if ([@"Add" isEqualToString:buttonName]
       || [@"Subtract" isEqualToString :buttonName]
       || [@"Multiply" isEqualToString :buttonName]
       || [@"Divide" isEqualToString :buttonName]) {
      [self pressedOperator:button];
   } else if ([@"Delete" isEqualToString:buttonName]) {
      [self pressedDelete];
   } else if ([@"Clear" isEqualToString:buttonName]) {
      [self pressedClear];
   } else if ([@"Percent" isEqualToString:buttonName]) {
      [self pressedPercent];
   } else if ([@"PositiveNegative" isEqualToString:buttonName]) {
      [self pressedPositiveNegative];
   } else if ([@"Equal" isEqualToString:buttonName]) {
      [self pressedEqual];
   } else {
      [self pressedOperand:button];
   }
}
         
- (void)pressedOperand:(UIButton *)button {
   NSString *operand = [button currentTitle];
      
   //prohibits leading 0 numbers.
   if (!(self.zeroValueFromDelete) && [self.screenValue isEqualToString:@"0"]
       && [operand isEqualToString:@"0"]) {
      self.stillInsertingDigits = NO;
      return;
   }
 
   if (self.stillInsertingDigits) {      
      if ([self.screenValue length] < 15) { //max number of digits on screen.
         if ([operand isEqualToString:@"Dot"]) {
            //prohibits more than one decimal point from appearing on screen.
            if ([self.screenValue rangeOfString:@"."].location != NSNotFound) {
               return;
            }
            operand = [self.screenValue isEqualToString:@"0"] ? @"0." : @".";
         }         
         self.screenValue = [self.screenValue isEqualToString:@"0"] ?
            operand : [self.screenValue stringByAppendingString:operand];
      }
   } else {
      self.screenValue = [operand isEqualToString:@"Dot"] ? @"0." : operand;
      self.stillInsertingDigits = YES;
      if (self.operatorPressed) self.insertingSecondOperand = YES;
      self.operatorPressed = NO;
   }
   [self displayUnformattedScreenValue];
}
      
- (void)pressedOperator:(UIButton *)button {
   if (!self.equalPressed && !self.operatorPressed) [self pressedEqual];
   self.stillInsertingDigits = NO;
   self.waitingForOperand = YES;
   [self.calc storeOperator:[button currentTitle]];
   [self.calc storeFirstOperand:
      [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   self.equalPressed = NO;
   self.operatorPressed = YES;
   self.zeroValueFromDelete = NO;
}

- (void)pressedDelete {
   if (self.stillInsertingDigits) {
      if ([self.screenValue length] > 1) {
         self.screenValue =
            [self.screenValue substringToIndex:[self.screenValue length] - 1];         
         if ([self.screenValue isEqualToString:@"-0."]) {
            self.screenValue = @"0.";
         } else if ([self.screenValue isEqualToString:@"-"]) {
            self.screenValue = @"0";
         }
      } else {
         self.zeroValueFromDelete = YES;
         self.screenValue = @"0";
      }
      [self displayUnformattedScreenValue];
   }
}

- (void)pressedClear {
   self.screenValue = @"0";
   [self displayUnformattedScreenValue];
   self.stillInsertingDigits = NO;
   self.waitingForOperand = NO;
   self.insertingSecondOperand = NO;
   self.zeroValueFromDelete = NO;
   [self.calc storeFirstOperand:[NSDecimalNumber zero]];
   [self.calc storeSecondOperand:[NSDecimalNumber zero]];
   [self.calc storeOperator:@""];
}

- (void)pressedPercent {
   if (self.insertingSecondOperand) {
      self.percentOperatorUsed = YES;
      [self pressedEqual];
      self.percentOperatorUsed = NO;
      self.zeroValueFromDelete = NO;
   }
}

- (void)pressedPositiveNegative {
   if (self.stillInsertingDigits) {
      if ([self.screenValue hasPrefix:@"-"]) {
         self.screenValue = [self.screenValue substringFromIndex:1];
      } else {
         if (![self.screenValue isEqualToString:@"0"] &&
             ![self.screenValue isEqualToString:@"0."]) {
            self.screenValue = [@"-" stringByAppendingString:self.screenValue];
         }
      }
   [self displayUnformattedScreenValue];
   }
}

- (void)pressedEqual {
   self.stillInsertingDigits = NO;
   self.equalPressed = YES;
   self.insertingSecondOperand = NO;
   self.zeroValueFromDelete = NO;
   if (self.waitingForOperand) {
      [self.calc storeSecondOperand:
         [NSDecimalNumber decimalNumberWithString:self.screenValue]];
      self.waitingForOperand = NO;
   } else {
      [self.calc storeFirstOperand:
         [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   }
   
   //checks if calculation returned a error message. 
   NSString *resultValue = self.percentOperatorUsed ?
      [self.calc calculate:YES] : [self.calc calculate:NO];
   NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
   if (![formatter numberFromString:resultValue]) {
      self.screen.text = resultValue;
      self.screenValue = @"0";
   } else {
      self.screenValue = resultValue;
      [self displayFormattedScreenValue];
   }
}

//moves button to destinationPostion at quick, linear speed.
- (void)buttonAnimate:(UIButton *)button:(CGPoint)destinationPosition {
   [UIView animateWithDuration:0.1 delay:0
      options:UIViewAnimationOptionCurveLinear
      animations:^ {button.center = destinationPosition;}
      completion:NULL];
}

- (void)buttonFlicked:(flickGestureRecognizer *)gesture {
	UIButton *button = (UIButton *)gesture.view;
   NSString *buttonImageName;

   CGPoint originalButtonCenter = button.center;
   
   //displays blue highlighted button after input is registered.
   buttonImageName = [gesture minVelocityReached] ?
      [NSString stringWithFormat:@"highlightedPressedButton%@.png",
         [button currentTitle]] :
      [NSString stringWithFormat:@"pressedButton%@.png", [button currentTitle]];
   [button.imageView setImage:[UIImage imageNamed:buttonImageName]];  

   [[button superview] bringSubviewToFront:button];
   CGPoint translation = [gesture translationInView:button];

   button.center = CGPointMake(button.center.x + translation.x,
                               button.center.y + translation.y);
   [gesture setTranslation:CGPointZero inView:button];
   
   CGPoint velocity = [gesture velocityInView:button];
   CGFloat currentSpeedSum = fabsf(velocity.x) + fabsf(velocity.y);

   if (currentSpeedSum > MIN_FLICKSPEED) [gesture setMinVelocityReached:YES];
   
   [self buttonAnimate:button:originalButtonCenter];
   
   if (gesture.state == UIGestureRecognizerStateEnded ||
         gesture.state == UIGestureRecognizerStateCancelled) {
      if ([gesture minVelocityReached]) [self executeInput:button];  
      buttonImageName = [NSString stringWithFormat:
         @"unpressedButton%@.png", [button currentTitle]];
      [button.imageView setImage:[UIImage imageNamed:buttonImageName]];
      [gesture setMinVelocityReached:NO];
   }
}

- (void)viewDidLoad {
   [super viewDidLoad];
   [self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:
      [UIImage imageNamed:@"flickCalcBackground.png"]]];
   self.screenValue = @"0";
   
   //initialize button state images and gesture recognizers.
   NSString *pressedButtonImageFileName;
   UIButton *button;
   for (id object in self.view.subviews) {
      if ([object isKindOfClass:[UIButton class]]) {
         button = object;
         [button addGestureRecognizer:
            [[flickGestureRecognizer alloc] initWithTarget:self
               action:@selector(buttonFlicked:)]];
         pressedButtonImageFileName =
            [NSString stringWithFormat:@"pressedButton%@.png",
               [button currentTitle]];
         [button setImage:[UIImage imageNamed:pressedButtonImageFileName]
            forState: UIControlStateHighlighted];        
      }
   }
}

- (void)viewDidUnload {
   [self setScreen:nil];
   [super viewDidUnload];
}


@end
