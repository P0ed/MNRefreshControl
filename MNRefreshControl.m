#import "MNRefreshControl.h"
#import "MNActivityIndicatorView.h"
@import QuartzCore;
@import ObjectiveC.runtime;


static CGFloat const MNRefreshControlThreshold = 52;
static CGFloat const MNRefreshControlSize = 28;


@interface MNRefreshControl ()
@property (nonatomic, copy) void (^refreshControlActionHandler)(void);
@property (nonatomic, strong) MNActivityIndicatorView *activityIndicatorView;
@property (nonatomic) MNRefreshControlState state;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic) CGFloat originalTopInset;
@property (nonatomic) CGFloat velocity;
@end


#pragma mark - UIScrollView (MNRefreshControl)

static char UIScrollViewRefreshControl;


@implementation UIScrollView (MNRefreshControl)

@dynamic refreshControl;

- (void)addRefreshControlWithActionHandler:(void (^)(void))actionHandler {
	
	MNRefreshControl *view = self.refreshControl;
	if (!view) {
		view = [[MNRefreshControl alloc] initWithFrame:CGRectMake(0, -MNRefreshControlThreshold, self.bounds.size.width, MNRefreshControlThreshold)];
		view.scrollView = self;
		[self addSubview:view];
		
		view.originalTopInset = self.contentInset.top;
		self.refreshControl = view;
		self.showsRefreshControl = YES;
	}
	view.refreshControlActionHandler = actionHandler;
}

- (void)setRefreshControl:(MNRefreshControl *)refreshControl {
	[self willChangeValueForKey:@"MNRefreshControl"];
	objc_setAssociatedObject(self, &UIScrollViewRefreshControl, refreshControl, OBJC_ASSOCIATION_ASSIGN);
	[self didChangeValueForKey:@"MNRefreshControl"];
}

- (MNRefreshControl *)refreshControl {
	return objc_getAssociatedObject(self, &UIScrollViewRefreshControl);
}

- (void)setShowsRefreshControl:(BOOL)showsRefreshControl {
	self.refreshControl.hidden = !showsRefreshControl;
}

- (BOOL)showsRefreshControl {
	return !self.refreshControl.hidden;
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
	if (!newSuperview) self.scrollView = nil;
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
		
		CGFloat pullWidth = -(_scrollView.contentOffset.y + _scrollView.contentInset.top);
		self.activityIndicatorView.progress = pullWidth / MNRefreshControlThreshold;
		
		switch (self.state) {
			case MNRefreshControlStateStopped: {
				if (_scrollView.tracking) {
					if (pullWidth > 0) {
						self.state = MNRefreshControlStateUnderThreshold;
					}
				}
				break;
			}
			case MNRefreshControlStateUnderThreshold: {
				if (_scrollView.tracking) {
					if (pullWidth <= 0) {
						self.state = MNRefreshControlStateStopped;
					}
					else if (pullWidth >= MNRefreshControlThreshold) {
						self.state = MNRefreshControlStateAboveThreshold;
					}
				} else {
					self.state = MNRefreshControlStateStopped;
				}
				break;
			}
			case MNRefreshControlStateAboveThreshold: {
				if (_scrollView.tracking) {
					if (pullWidth < MNRefreshControlThreshold) {
						self.state = MNRefreshControlStateUnderThreshold;
					}
					self.velocity = [_scrollView.panGestureRecognizer velocityInView:_scrollView].y;
				} else {
					self.state = MNRefreshControlStateTriggered;
				}
				break;
			}
			case MNRefreshControlStateTriggered: {
				break;
			}
		}
	}
}

- (void)layoutSubviews {
	self.activityIndicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)updateFrame {
	CGFloat height = fmaxf(MNRefreshControlThreshold, -(_scrollView.contentOffset.y + self.originalTopInset));
	self.frame = CGRectMake(0, -height, _scrollView.frame.size.width, height);
	[self layoutSubviews];
}

- (void)setScrollView:(UIScrollView *)scroll {
	[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
	[_scrollView removeObserver:self forKeyPath:@"frame"];
	_scrollView = scroll;
	[_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
	[_scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
	[self updateFrame];
	[_scrollView addSubview:self];
}

#pragma mark -

- (void)rotateActivityIndicatorView {
	CAKeyframeAnimation *rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotationAnimation.duration = fmin(fmax(900 / self.velocity, 1.2), 3);
	rotationAnimation.values = @[@0, @(M_PI / 2), @(M_PI * 3 / 2), @(M_PI * 2)];
	rotationAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
										  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
										  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	[self.activityIndicatorView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)beginRefreshing {
	
	if (!_refreshing) {
		_refreshing = YES;
		
		[self.activityIndicatorView startAnimating];
		[self rotateActivityIndicatorView];
		
		UIEdgeInsets insets = _scrollView.contentInset;
		self.originalTopInset = insets.top;
		insets.top += MNRefreshControlThreshold;
		
		[UIView animateWithDuration:0.3
						 animations:^{
							 _scrollView.contentInset = insets;
							 if (_scrollView.contentOffset.y > -_scrollView.contentInset.top) {
								 _scrollView.contentOffset = CGPointMake(_scrollView.contentOffset.x, -_scrollView.contentInset.top);
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
							 
							 UIEdgeInsets insets = _scrollView.contentInset;
							 insets.top = self.originalTopInset;
							 _scrollView.contentInset = insets;
						 }
						 completion:^(BOOL finished) {
							 
							 _refreshing = NO;
							 self.state = MNRefreshControlStateStopped;
							 self.activityIndicatorView.transform = CGAffineTransformIdentity;
							 [self.activityIndicatorView.layer removeAllAnimations];
						 }];
	}
}

- (void)setState:(MNRefreshControlState)state {
	
	if (_state != state) {
		_state = state;
		
		switch (state) {
			case MNRefreshControlStateStopped:
			case MNRefreshControlStateUnderThreshold:
			case MNRefreshControlStateAboveThreshold: {
				[self.activityIndicatorView stopAnimating];
				[self endRefreshing];
				break;
			}
			case MNRefreshControlStateTriggered: {
				[self beginRefreshing];
				if (self.refreshControlActionHandler) self.refreshControlActionHandler();
				break;
			}
		}
	}
}

@end
