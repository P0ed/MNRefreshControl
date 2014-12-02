//
//  MNActivityIndicatorView.h
//  MemNow
//
//  Created by Konstantin Sukharev on 25/11/14.
//  Copyright (c) 2014 MemNow. All rights reserved.
//

#import "MNRefreshControl.h"
#import "MNActivityIndicatorView.h"
@import QuartzCore;
@import ObjectiveC.runtime;


static CGFloat const MNRefreshControlThreshold = 52;
static CGFloat const MNRefreshControlSize = 28;
static char UIScrollViewRefreshControl;


@interface MNRefreshControl ()
@property (nonatomic, copy) MNRefreshControlBlock refreshControlActionHandler;
@property (nonatomic, strong) MNActivityIndicatorView *activityIndicatorView;
@property (nonatomic) MNRefreshControlState state;
@property (nonatomic) CGFloat originalTopInset;
@property (nonatomic) CGFloat velocity;
@end


#pragma mark - UIScrollView (MNRefreshControl)

@implementation UIScrollView (MNRefreshControl)

- (void (^)(MNRefreshControlBlock actionHandler))addRefreshControlWithActionHandler { return ^(MNRefreshControlBlock actionHandler) {
	
	MNRefreshControl *refreshControl = self.refreshControl;
	if (!refreshControl) {
		refreshControl = MNRefreshControl.new;
		refreshControl.originalTopInset = self.contentInset.top;
		[self addSubview:refreshControl];
		self.refreshControl = refreshControl;
	}
	refreshControl.refreshControlActionHandler = actionHandler;
};}

- (void)setRefreshControl:(MNRefreshControl *)refreshControl {
	[self willChangeValueForKey:@"MNRefreshControl"];
	objc_setAssociatedObject(self, &UIScrollViewRefreshControl, refreshControl, OBJC_ASSOCIATION_ASSIGN);
	[self didChangeValueForKey:@"MNRefreshControl"];
}

- (MNRefreshControl *)refreshControl {
	return objc_getAssociatedObject(self, &UIScrollViewRefreshControl);
}

@end


#pragma mark - MNRefreshControl

@implementation MNRefreshControl

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.state = MNRefreshControlStateStopped;
		CGRect frame = CGRectMake(0, 0, MNRefreshControlSize, MNRefreshControlSize);
		_activityIndicatorView = [[MNActivityIndicatorView alloc] initWithFrame:frame];
		[self addSubview:_activityIndicatorView];
		_refreshing = NO;
	}
	return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	[self.superview removeObserver:self forKeyPath:@"contentOffset"];
	[self.superview removeObserver:self forKeyPath:@"frame"];
	[newSuperview addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
	[newSuperview addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"contentOffset"]) {
		[self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
	}
	else if ([keyPath isEqualToString:@"frame"]) {
		[self updateFrame];
	}
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
	
	[self updateFrame];
	
	if (!_refreshing) {
		CGFloat offset = -(self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
		if (self.scrollView.tracking) self.activityIndicatorView.progress = offset / MNRefreshControlThreshold;
		
		switch (self.state) {
			case MNRefreshControlStateStopped:
				if (self.scrollView.tracking) {
					if (offset > 0) {
						self.state = MNRefreshControlStateUnderThreshold;
					}
				}
				break;
				
			case MNRefreshControlStateUnderThreshold:
				if (self.scrollView.tracking) {
					if (offset <= 0) {
						self.state = MNRefreshControlStateStopped;
					}
					else if (offset >= MNRefreshControlThreshold) {
						self.state = MNRefreshControlStateAboveThreshold;
					}
				} else {
					self.state = MNRefreshControlStateStopped;
				}
				break;

			case MNRefreshControlStateAboveThreshold:
				if (self.scrollView.tracking) {
					if (offset < MNRefreshControlThreshold) {
						self.state = MNRefreshControlStateUnderThreshold;
					}
					self.velocity = [self.scrollView.panGestureRecognizer velocityInView:self.scrollView].y;
				} else {
					self.state = MNRefreshControlStateTriggered;
				}
				break;
				
			case MNRefreshControlStateTriggered:
				break;
		}
	}
}

- (void)layoutSubviews {
	self.activityIndicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)updateFrame {
	CGFloat height = fmaxf(MNRefreshControlThreshold, -(self.scrollView.contentOffset.y + self.originalTopInset));
	self.frame = CGRectMake(0, -height, self.scrollView.frame.size.width, height);
	[self layoutSubviews];
}

- (UIScrollView *)scrollView {
	return (UIScrollView *)self.superview;
}

#pragma mark -

- (void)beginRefreshing {
	if (!_refreshing) {
		_refreshing = YES;
		
		[self.activityIndicatorView startAnimatingWithVelocity:self.velocity];
		
		UIEdgeInsets insets = self.scrollView.contentInset;
		self.originalTopInset = insets.top;
		insets.top += MNRefreshControlThreshold;
		
		[UIView animateWithDuration:0.3
						 animations:^{
							 self.scrollView.contentInset = insets;
							 if (self.scrollView.contentOffset.y > -self.scrollView.contentInset.top) {
								 self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, -self.scrollView.contentInset.top);
							 }
							 [self layoutSubviews];
						 }];
	}
}

- (void)endRefreshing {
	if (_refreshing) {
		[UIView animateWithDuration:0.3
						 animations:^{
							 self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.01, 0.01);
							 UIEdgeInsets insets = self.scrollView.contentInset;
							 insets.top = self.originalTopInset;
							 self.scrollView.contentInset = insets;
						 }
						 completion:^(BOOL finished) {
							 _refreshing = NO;
							 self.state = MNRefreshControlStateStopped;
							 self.activityIndicatorView.transform = CGAffineTransformIdentity;
						 }];
	}
}

- (void)setState:(MNRefreshControlState)state {
	if (_state != state) {
		_state = state;
		switch (state) {
			case MNRefreshControlStateStopped:
			case MNRefreshControlStateUnderThreshold:
			case MNRefreshControlStateAboveThreshold:
				[self.activityIndicatorView stopAnimating];
				[self endRefreshing];
				break;
			case MNRefreshControlStateTriggered:
				[self beginRefreshing];
				if (self.refreshControlActionHandler) self.refreshControlActionHandler();
				break;
		}
	}
}

@end
