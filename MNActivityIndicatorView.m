//
//  MNActivityIndicatorView.m
//  MemNow
//
//  Created by Konstantin Sukharev on 25/11/14.
//  Copyright (c) 2014 MemNow. All rights reserved.
//

#import "MNActivityIndicatorView.h"


static const NSInteger numberOfSectors = 12;


@implementation MNActivityIndicatorView {
	NSTimer *_timer;
	CGFloat _angle;
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = NO;
		self.tintColor = [UIColor grayColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	if (!CGRectIsEmpty(rect)) {
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		[self.tintColor setFill];
		
		CGPoint center = CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0);
		CGFloat radius = fminf(rect.size.width, rect.size.height) / 2.0;
		CGFloat circleLength = 2 * M_PI * radius;
		CGFloat sectorWidth = circleLength / 3.9 / numberOfSectors;
		CGFloat sectorLength = radius * 0.57;
		
		NSInteger numberOfSectorsToDraw = numberOfSectors;
		if (!self.isAnimating) {
			numberOfSectorsToDraw *= _progress;
			_angle = 2 * M_PI / (CGFloat)numberOfSectors * (numberOfSectorsToDraw - 1);
		}
		
		for (NSInteger i = 0; i < numberOfSectorsToDraw; ++i) {
			// Animation offset
			CGFloat spinnerOffset = (self.isAnimating ? -1 : 0);
			CGFloat sectorAngle = 2 * M_PI / (CGFloat)numberOfSectors * (i + spinnerOffset);
			// Rotation
			CGContextSaveGState(ctx);
			CGContextTranslateCTM(ctx, center.x, center.y);
			CGContextRotateCTM(ctx, sectorAngle);
			CGContextTranslateCTM(ctx, -center.x, -center.y);
			// AlphaChannel
			CGFloat distance = _angle - sectorAngle + M_PI * 2;
			distance = fmodf(distance, M_PI * 2);
			distance = 1.0 - distance / (M_PI * 2);
			CGFloat kCorr = 0.25;
			distance = kCorr + (1.0 - kCorr) * distance;
			CGContextSetAlpha(ctx, distance);
			// Segment drawing
			CGContextAddRect(ctx, CGRectMake(center.x - sectorWidth / 2, 0, sectorWidth, sectorLength));
			CGContextFillPath(ctx);
			CGContextRestoreGState(ctx);
		}
	}
}

#pragma mark - Properties

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	if (!self.isAnimating) {
		[self setNeedsDisplay];
	}
}

- (void)setTintColor:(UIColor *)tintColor {
	[super setTintColor:tintColor];
	if (!self.isAnimating) {
		[self setNeedsDisplay];
	}
}

- (BOOL)isAnimating {
	return _timer.isValid;
}

- (void)setProgress:(CGFloat)progress {
	_progress = fminf(1, fmaxf(0, progress));
	if (!self.isAnimating) {
		[self setNeedsDisplay];
	}
}

#pragma mark - Actions

- (void)startAnimatingWithVelocity:(CGFloat)velocity {
	if (!self.isAnimating) {
		_angle = 0;
		_timer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(animate) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
		
		CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
		rotationAnimation.duration = fmin(fmax(900 / velocity, 1.1), 2.3);
		rotationAnimation.values = @[@0, @(M_PI / 2), @(M_PI * 3 / 2), @(M_PI * 2)];
		rotationAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
											  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
											  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
		[self.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
	}
}

- (void)startAnimating {
	[self startAnimatingWithVelocity:500];
}

- (void)stopAnimating {
	if (self.isAnimating) {
		[self.layer removeAllAnimations];
		_progress = 0;
		[_timer invalidate], _timer = nil;
		[self setNeedsDisplay];
	}
}

- (void)animate {
	_angle = fmodf(_angle + 0.3, M_PI * 2);
	[self setNeedsDisplay];
}

@end
