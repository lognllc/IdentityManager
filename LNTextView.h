//
//  LNTextView.h
//
//  Created by Rex Sheng on 12/25/12.
//  Copyright (c) 2012 Log(N). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LNTextView : UITextView

@property (nonatomic) CGFloat edgeInsetX UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *textAttributes UI_APPEARANCE_SELECTOR;

@end
