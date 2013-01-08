//
//  LNTextView.m
//  imfldemo
//
//  Created by Rex Sheng on 12/25/12.
//  Copyright (c) 2012 Log(N). All rights reserved.
//

#import "LNTextView.h"

@implementation LNTextView

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.clipsToBounds = YES;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setTextAttributes:(NSDictionary *)textAttributes
{
	_textAttributes = textAttributes;
	UIFont *font = textAttributes[UITextAttributeFont];
	if (font) self.font = font;
	UIColor *textColor = textAttributes[UITextAttributeTextColor];
	if (textColor) self.textColor = textColor;
}

@end
