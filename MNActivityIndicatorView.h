//
//  MNActivityIndicatorView.h
//  MemNow
//
//  Created by Konstantin Sukharev on 25/11/14.
//  Copyright (c) 2014 MemNow. All rights reserved.
//

@import UIKit;


@interface MNActivityIndicatorView : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;
- (void)startAnimatingWithVelocity:(CGFloat)velocity;
- (void)startAnimating;
- (void)stopAnimating;
@end
