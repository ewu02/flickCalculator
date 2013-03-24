//
//  mainViewController.m
//  flickCalculator
//
//  Created by Enming Wu on 7/17/12.
//  Copyright (c) 2012 Enming Wu. All rights reserved.
//

#import "mainViewController.h"
#import "calculation.h"
#import "flickGestureRecognizer.h"

#define MIN_FLICKSPEED 350 //minimum speed of button flick to register command

@interface mainViewController ()

//displays formatted screenValue value.
@property (weak, nonatomic) IBOutlet UILabel *screen;

@property (nonatomic) NSString *screenValue;
@property (nonatomic, strong) calculation *calc;
@property (nonatomic) BOOL stillInsertingDigits;
@property (nonatomic) BOOL waitingForOperand;
@property (nonatomic) BOOL equalButtonFlicked;
@property (nonatomic) BOOL generalOperatorButtonFlicked;
@property (nonatomic) BOOL insertingSecondOperand; //used for percent operator.
@property (nonatomic) BOOL percentButtonFlicked;
@property (nonatomic) BOOL zeroValueFromDelete;

- (calculation *)calc;

- (IBAction)displayHelpAlert:(UIButton *)sender;

//outputs formatted value from type Double.
- (void)displayFormattedScreenValue;

- (void)displayUnformattedScreenValue;
- (void)executeInput:(UIButton *)button;
- (void)insertDigit:(UIButton *)button;
- (void)storeGeneralOperator:(UIButton *)button;
- (void)deleteLastInsertedDigit;

// resets all display and internal values
- (void)resetAll;

- (void)executeCalculation;
- (void)executeCalculationWithRightOperandAsPercent;
- (void)negateInputtedNumber;

//moves button to destinationPostion at quick, linear speed.
- (void)buttonAnimate:(UIButton *)button :(CGPoint)destinationPosition;

- (void)buttonInteractionEffects:(flickGestureRecognizer *)gesture;

@end //interface mainViewController


@implementation mainViewController

@synthesize screen = _screen;
@synthesize screenValue = _screenValue;
@synthesize calc = _calc;
@synthesize stillInsertingDigits = _stillInsertingDigits;
@synthesize waitingForOperand = _waitingForOperand;
@synthesize equalButtonFlicked = _equalButtonFlicked;
@synthesize generalOperatorButtonFlicked = _generalOperatorButtonFlicked;
@synthesize insertingSecondOperand = _insertingSecondOperand;
@synthesize percentButtonFlicked = _percentButtonFlicked;
@synthesize zeroValueFromDelete = _zeroValueFromDelete;

- (calculation *)calc {
   if (!_calc) _calc = [[calculation alloc] init];
   return _calc;
}

- (IBAction)displayHelpAlert:(UIButton *)sender {
   UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Using FlickCalculator" message:@"Lightly flick or swipe a button to execute it." delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
   [alert show];
}

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
      [self storeGeneralOperator:button];
   } else if ([@"Delete" isEqualToString:buttonName]) {
      [self deleteLastInsertedDigit];
   } else if ([@"Clear" isEqualToString:buttonName]) {
      [self resetAll];
   } else if ([@"Percent" isEqualToString:buttonName]) {
      [self executeCalculationWithRightOperandAsPercent];
   } else if ([@"PositiveNegative" isEqualToString:buttonName]) {
      [self negateInputtedNumber];
   } else if ([@"Equal" isEqualToString:buttonName]) {
      [self executeCalculation];
   } else {
      [self insertDigit:button];
   }
}
         
- (void)insertDigit:(UIButton *)button {
   NSString *digit = [button currentTitle];
      
   //prohibits inserting a leading 0 digit.
   if (!(self.zeroValueFromDelete) && [self.screenValue isEqualToString:@"0"]
       && [digit isEqualToString:@"0"]) {
      self.stillInsertingDigits = NO;
      return;
   }
 
   if (self.stillInsertingDigits) {      
      if ([self.screenValue length] < 15) { //max number of digits on screen.
         if ([digit isEqualToString:@"Dot"]) {
            //prohibits more than one decimal point from appearing on screen.
            if ([self.screenValue rangeOfString:@"."].location != NSNotFound) {
               return;
            }
            digit = [self.screenValue isEqualToString:@"0"] ? @"0." : @".";
         }         
         self.screenValue = [self.screenValue isEqualToString:@"0"] ?
            digit : [self.screenValue stringByAppendingString:digit];
      }
   } else {
      self.screenValue = [digit isEqualToString:@"Dot"] ? @"0." : digit;
      self.stillInsertingDigits = YES;
      if (self.generalOperatorButtonFlicked) {
         self.insertingSecondOperand = YES;
         self.generalOperatorButtonFlicked = NO;
      }
   }
   [self displayUnformattedScreenValue];
}
      
- (void)storeGeneralOperator:(UIButton *)button {
   if (!self.equalButtonFlicked && !self.generalOperatorButtonFlicked) [self executeCalculation];
   self.stillInsertingDigits = NO;
   self.waitingForOperand = YES;
   [self.calc storeOperator:[button currentTitle]];
   [self.calc storeLeftOperand:
      [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   self.equalButtonFlicked = NO;
   self.generalOperatorButtonFlicked = YES;
   self.zeroValueFromDelete = NO;
}

- (void)deleteLastInsertedDigit {
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

- (void)resetAll {
   self.screenValue = @"0";
   [self displayUnformattedScreenValue];
   self.stillInsertingDigits = NO;
   self.waitingForOperand = NO;
   self.insertingSecondOperand = NO;
   self.zeroValueFromDelete = NO;
   [self.calc storeLeftOperand:[NSDecimalNumber zero]];
   [self.calc storeRightOperand:[NSDecimalNumber zero]];
   [self.calc storeOperator:@""];
}

- (void)executeCalculationWithRightOperandAsPercent {
   if (self.insertingSecondOperand) {
      self.percentButtonFlicked = YES;
      [self executeCalculation];
      self.percentButtonFlicked = NO;
      self.zeroValueFromDelete = NO;
   }
}

- (void)negateInputtedNumber {
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

- (void)executeCalculation {
   self.stillInsertingDigits = NO;
   self.equalButtonFlicked = YES;
   self.insertingSecondOperand = NO;
   self.zeroValueFromDelete = NO;
   if (self.waitingForOperand) {
      [self.calc storeRightOperand:
         [NSDecimalNumber decimalNumberWithString:self.screenValue]];
      self.waitingForOperand = NO;
   } else {
      [self.calc storeLeftOperand:
         [NSDecimalNumber decimalNumberWithString:self.screenValue]];
   }
   
   //checks if calculation returned a error message. 
   NSString *resultValue = [self.calc calculate:self.percentButtonFlicked];
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
- (void)buttonAnimate:(UIButton *)button :(CGPoint)destinationPosition {
   [UIView animateWithDuration:0.1 delay:0
      options:UIViewAnimationOptionCurveLinear
      animations:^ {button.center = destinationPosition;}
      completion:NULL];
}

- (void)buttonInteractionEffects:(flickGestureRecognizer *)gesture {
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
   BOOL iPad = NO;
   BOOL iPhone4in = NO;
#ifdef UI_USER_INTERFACE_IDIOM
   iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
   
   [super viewDidLoad];
   
   //initializes an appropriate background image for device.
   if (iPad) {
      [self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:
         [UIImage imageNamed:@"flickCalcBackground.png"]]];
   } else { //defaults to iphone3.5 storyboard.
      iPhone4in = [UIScreen mainScreen].bounds.size.height == 568.0;
      if (iPhone4in){
         [self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:
            [UIImage imageNamed:@"flickCalcBackground_iPhone-568h.png"]]];
      } else { //iPhone 3.5
         [self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:
            [UIImage imageNamed:@"flickCalcBackground_iPhone.png"]]];
      }
   }
   
   self.screenValue = @"0";
   
   //initializes button state images and assign gesture recognizers.
   //excludes help button.
   NSString *pressedButtonImageFileName;
   UIButton *button;
   for (id object in self.view.subviews) {
      if ([object isKindOfClass:[UIButton class]]) {
         button = object;
         if (button.buttonType == UIButtonTypeInfoDark) continue; //help button
         [button addGestureRecognizer:
            [[flickGestureRecognizer alloc] initWithTarget:self
               action:@selector(buttonInteractionEffects:)]];
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


@end //implementation mainViewController
