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


static CGFloat const MNRefreshControlThreshold = 60;
static CGFloat const MNRefreshControlInsets = 52;
static CGFloat const MNRefreshControlSize = 28;
static char UIScrollViewRefreshControl;


@interface MNRefreshControl ()
@property (nonatomic, copy) MNRefreshControlBlock refreshControlActionHandler;
@property (nonatomic, strong) MNActivityIndicatorView *activityIndicatorView;
@property (nonatomic) MNRefreshControlState state;
@property (nonatomic, getter=isModifiedInsets) BOOL modifiedInsets;
@property (nonatomic) CGFloat originalTopInset;
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
		CGRect frame = CGRectMake(0, 0, MNRefreshControlSize, MNRefreshControlSize);
		_activityIndicatorView = [[MNActivityIndicatorView alloc] initWithFrame:frame];
		[self addSubview:_activityIndicatorView];
		self.state = MNRefreshControlStateIdle;
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
	CGFloat offset = -(self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
	self.activityIndicatorView.progress = offset / MNRefreshControlThreshold;
	
	switch (self.state) {
		case MNRefreshControlStateIdle:
			if (self.scrollView.tracking && offset >= MNRefreshControlThreshold) {
				self.state = MNRefreshControlStateTriggered;
			}
			break;
		case MNRefreshControlStateTriggered:
		case MNRefreshControlStateReleased:
		case MNRefreshControlStateGrabbed:
			self.state = self.scrollView.tracking ? MNRefreshControlStateGrabbed : MNRefreshControlStateReleased;
			break;
	}
}

- (void)layoutSubviews {
	self.activityIndicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)updateFrame {
	CGFloat height = fmaxf(0, -(self.scrollView.contentOffset.y + self.originalTopInset));
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
		CGFloat velocity = [self.scrollView.panGestureRecognizer velocityInView:self.scrollView].y;
		[self.activityIndicatorView startAnimatingWithVelocity:velocity];
	}
}

- (void)endRefreshing {
	if (_refreshing) {
		_refreshing = NO;
		if (self.state == MNRefreshControlStateReleased) [self hideActivityIndicator];
	}
}

- (void)addInsets {
	if (!self.isModifiedInsets) {
		self.modifiedInsets = YES;
		[UIView animateWithDuration:0.3
						 animations:^{
							 UIEdgeInsets insets = self.scrollView.contentInset;
							 self.originalTopInset = insets.top;
							 insets.top += MNRefreshControlInsets;
							 self.scrollView.contentInset = insets;
							 if (self.scrollView.contentOffset.y > -self.scrollView.contentInset.top) {
								 self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, -self.scrollView.contentInset.top);
							 }
							 [self layoutSubviews];
						 }];
	}
}

- (void)hideActivityIndicator {
	[UIView animateWithDuration:0.3
					 animations:^{
						 self.activityIndicatorView.transform = CGAffineTransformMakeScale(0.01, 0.01);
						 if (self.isModifiedInsets) {
							 UIEdgeInsets insets = self.scrollView.contentInset;
							 insets.top = self.originalTopInset;
							 self.scrollView.contentInset = insets;
							 self.modifiedInsets = NO;
						 }
					 }
					 completion:^(BOOL finished) {
						 self.state = MNRefreshControlStateIdle;
						 [self.activityIndicatorView stopAnimating];
						 self.activityIndicatorView.transform = CGAffineTransformIdentity;
					 }];
}

- (void)setState:(MNRefreshControlState)state {
	if (_state != state) {
		_state = state;
		switch (state) {
			case MNRefreshControlStateIdle:
				break;
			case MNRefreshControlStateTriggered:
				[self beginRefreshing];
				if (self.refreshControlActionHandler) self.refreshControlActionHandler();
				break;
			case MNRefreshControlStateReleased:
				if (_refreshing) [self addInsets];
				else [self hideActivityIndicator];
				break;
			case MNRefreshControlStateGrabbed:
				break;
		}
	}
}

@end
