//
//  MNActivityIndicatorView.h
//  MemNow
//
//  Created by Konstantin Sukharev on 25/11/14.
//  Copyright (c) 2014 MemNow. All rights reserved.
//

@import UIKit;


typedef enum {
	SpinnerModeActivityIndicator = 0,
	SpinnerModeProgressBar,
} SpinnerMode;


@interface MNActivityIndicatorView : UIView

@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;

@end
