//
//  ebZoomingScrollView.h
//  quadrangle
//
//  Created by Evan Buxton on 6/27/13.
//  Copyright (c) 2013 neoscape. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ebZoomingScrollView;

@protocol ebZoomingScrollViewDelegate

@optional
-(void)didRemove:(ebZoomingScrollView *)customClass;
-(void)ebScrollViewDidScroll:(ebZoomingScrollView *)scrollView;
-(void)ebScrollViewDidZoom:(ebZoomingScrollView *)scrollView;

@end

@interface ebZoomingScrollView : UIView <UIScrollViewDelegate,UIGestureRecognizerDelegate>
{
	CGFloat maximumZoomScale;
	CGFloat minimumZoomScale;
	CGRect incomingFrame;
	BOOL isFullScreen;
}
 
- (id)initWithFrame:(CGRect)frame image:(UIImage*)thisImage overlay:(NSString*)secondImage shouldZoom:(BOOL)zoomable;
@property (assign) BOOL canZoom;
@property (nonatomic, strong) NSString *overlay;
@property (nonatomic, strong) UIImage *firstImg;

@property (assign) BOOL imageToggle;
// define delegate property
@property (nonatomic, weak) id  delegate;
@property (nonatomic, readwrite) BOOL  closeBtn;
@property (nonatomic, strong)	UIImageView *blurView;
@property (nonatomic, strong) UIScrollView *scrollView;

// define public functions
-(void)didRemove;
-(void)resetScroll;
- (void)recenterImage;

@end
