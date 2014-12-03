//
//  MNActivityIndicatorView.h
//  MemNow
//
//  Created by Konstantin Sukharev on 25/11/14.
//  Copyright (c) 2014 MemNow. All rights reserved.
//

@import UIKit;


@class MNRefreshControl;
typedef void (^MNRefreshControlBlock)(void);


@interface UIScrollView (MNRefreshControl)
@property (nonatomic, readonly) MNRefreshControl *refreshControl;
- (void (^)(MNRefreshControlBlock))addRefreshControlWithActionHandler;
@end


typedef NS_ENUM(NSUInteger, MNRefreshControlState) {
	
	MNRefreshControlStateIdle,
	MNRefreshControlStateTriggered,
	MNRefreshControlStateReleased,
	MNRefreshControlStateGrabbed,
};


@interface MNRefreshControl : UIView
@property (nonatomic, readonly) MNRefreshControlState state;
@property (nonatomic, readonly, getter=isRefreshing) BOOL refreshing;
- (void)beginRefreshing;
- (void)endRefreshing;
@end
