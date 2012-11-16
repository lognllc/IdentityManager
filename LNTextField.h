//
//  LNTextField.h
//
//  Created by Rex Sheng on 9/5/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LNTextValidateType) {
	LNTextValidateNone,
	LNTextValidateEmail,
	LNTextValidateRequired,
	LNTextValidateCustom,
};

@interface LNTextField : UITextField

@property (nonatomic) CGFloat edgeInsetX;
@property (nonatomic, strong) UIImage *clearImage;
@property (nonatomic) CGFloat placeholderAlpha;
@property (nonatomic, readonly) NSString *safeText;
@property (nonatomic, strong) NSPredicate *validatePredicate;
@property (nonatomic) LNTextValidateType validateType;
@property (nonatomic, strong) NSString *failedValidateText;

- (BOOL)isValid;
- (BOOL)isValid:(NSString *)text;
- (void)cleanUp;

@end
