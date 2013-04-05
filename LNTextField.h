//
//  LNTextField.h
//
//  Created by Rex Sheng on 9/5/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EMPLOYEE_PATTERN @"^\\S+@flyfrontier.com"

//This is special. "isValid:" method returns YES if ANY ONE of flag's predicate is true. ATTENTION!
typedef NS_ENUM(NSUInteger, LNTextValidateType) {
	LNTextValidateNone = 0,
	LNTextValidateEmail = 1 << 0,
	LNTextValidateRequired = 1 << 1,
    LNTextValidateFlyFrontierEmployeeAccount = 1 << 2,
    LNTextValidateEarlyReturnsID = 1 << 3,
	LNTextValidateCustom = 1 << 4
};

@interface LNTextField : UITextField

@property (nonatomic) CGFloat edgeInsetX UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *clearImage;
@property (nonatomic) CGFloat placeholderAlpha UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSPredicate *validatePredicate;
@property (nonatomic) LNTextValidateType validateType;
@property (nonatomic, strong) NSString *failedValidateText;
@property (nonatomic, strong) NSDictionary *textAttributes UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

- (BOOL)isValid;
- (BOOL)isValid:(NSString *)text;
- (void)cleanUp;

@end
