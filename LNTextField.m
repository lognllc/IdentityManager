//
//  LNTextField.m
//
//  Created by Rex Sheng on 9/5/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LNTextField.h"

@implementation LNTextField

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		_edgeInsetX = 8;
		_placeholderAlpha = 1;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.keyboardType = UIKeyboardTypeDefault;
		self.returnKeyType = UIReturnKeySearch;
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.clipsToBounds = YES;
	}
	return self;
}

- (void)setClearImage:(UIImage *)clearImage
{
	_clearImage = clearImage;
	UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearButton setImage:clearImage forState:UIControlStateNormal];
	[clearButton addTarget:self action:@selector(cleanUp) forControlEvents:UIControlEventTouchUpInside];
	clearButton.frame = (CGRect) {.size = clearImage.size};
	self.rightView = clearButton;
	self.rightViewMode = UITextFieldViewModeAlways;
	self.rightView.hidden = YES;
	self.clearButtonMode = UITextFieldViewModeNever;
}

- (void)cleanUp
{
	if ([self.delegate textFieldShouldClear:self]) {
		self.text = nil;
		self.rightView.hidden = YES;
		if (![self isFirstResponder])
			[self becomeFirstResponder];
	}
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.rightView.bounds.size.height) / 2;
	return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake((bounds.size.height - self.font.lineHeight) / 2, _edgeInsetX, 0, self.rightView.bounds.size.width + offset));
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
	return [self textRectForBounds:bounds];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.rightView.bounds.size.height) / 2;
	return CGRectOffset(self.rightView.bounds, bounds.size.width - self.rightView.bounds.size.width - offset, offset);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
	return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake((bounds.size.height - self.font.lineHeight) / 2, _edgeInsetX, 0, _edgeInsetX));
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.leftView.bounds.size.height) / 2;
	return CGRectOffset(self.leftView.bounds, offset, offset);
}

- (void)drawPlaceholderInRect:(CGRect)rect
{
	[[self.textColor colorWithAlphaComponent:_placeholderAlpha] set];
	[self.placeholder drawAtPoint:CGPointMake(0, 0) withFont:self.font];
}

@end
