@import UIKit;


@class MNRefreshControl;


@interface UIScrollView (MNRefreshControl)
@property (nonatomic, strong, readonly) MNRefreshControl *refreshControl;
- (void)addRefreshControlWithActionHandler:(void (^)(void))actionHandler;
@end


typedef NS_ENUM(NSUInteger, MNRefreshControlState) {
	
	MNRefreshControlStateStopped = 0,
	MNRefreshControlStateUnderThreshold,
	MNRefreshControlStateAboveThreshold,
	MNRefreshControlStateTriggered,
};


@interface MNRefreshControl : UIView
@property (nonatomic, readonly) MNRefreshControlState state;
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
- (void)beginRefreshing;
- (void)endRefreshing;
@end
