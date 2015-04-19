#import <objc/runtime.h>
#import "ATExternalScreenController.h"

#include <tgmath.h>


static void *const ViewControllerIsDoppelganger = "ATExternalScreenController.ViewControllerIsDoppelganger";
static void *const ViewControllerDoppelgangersPrimaryViewController = "ATExternalScreenController.ViewControllerDoppelgangersPrimaryViewController";


@interface ATExternalScreenController ()

@property (nonatomic) UIWindow *externalDisplayWindow;

@end



@implementation ATExternalScreenController {
    __weak UIViewController<ATExternalScreenAwareController> *_primaryViewController;
    __weak UIViewController *_presentedDoppelgangerViewController;
}

static ATExternalScreenController *sharedExternalScreenController;

+ (instancetype)sharedExternalScreenController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedExternalScreenController = [ATExternalScreenController new];
    });
    return sharedExternalScreenController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidConnect:) name:UIScreenDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];

        if ([UIScreen screens].count > 1) {
            [self setupExternalUIOnScreen:[[UIScreen screens] lastObject]];
        }
    }
    return self;
}

- (void)screenDidConnect:(NSNotification *)notification {
    [self setupExternalUIOnScreen:notification.object];
}

- (void)setupExternalUIOnScreen:(UIScreen *)secondaryScreen {
	UIScreenMode *screenMode = [[secondaryScreen availableModes] lastObject];

	CGRect rect = CGRectMake(0, 0, screenMode.size.width, screenMode.size.height);
	NSLog(@"Extscreen size: %@", NSStringFromCGSize(rect.size));

	self.externalDisplayWindow = [[UIWindow alloc] initWithFrame:CGRectZero];
	_externalDisplayWindow.screen = secondaryScreen;
	_externalDisplayWindow.screen.currentMode = screenMode;
    _externalDisplayWindow.tintColor = [[[UIApplication sharedApplication].windows firstObject] tintColor];
	_externalDisplayWindow.frame = rect;
    _externalDisplayWindow.hidden = NO;

    [self presentOnExternalScreen];
}

- (void)viewWillAppear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)viewController {
    if ([self isDoppelgangerViewController:viewController]) {
        UIViewController <ATExternalScreenAwareController> *primaryVC = [self primaryViewControllerForDoppelgangerViewController:viewController];
        if ([primaryVC respondsToSelector:@selector(doppelgangerViewControllerWillAppear)]) {
            [primaryVC doppelgangerViewControllerWillAppear];
        }
        return;
    }


}

- (void)viewDidAppear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController {
    if ([self isDoppelgangerViewController:primaryViewController]) {
        return;
    }

    if (_primaryViewController != primaryViewController) {
        _primaryViewController = primaryViewController;
        _presentedDoppelgangerViewController = nil;
        if (_externalDisplayWindow) {
            [self presentOnExternalScreen];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController {
    if ([self isDoppelgangerViewController:primaryViewController]) {
        return;
    }


}

- (void)viewDidDisappear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController {
    if ([self isDoppelgangerViewController:primaryViewController]) {
        return;
    }


}

- (void)viewDidLayoutSubviewsForViewController:(UIViewController *)viewController {
    if ([self isDoppelgangerViewController:viewController]) {
        UIViewController <ATExternalScreenAwareController> *primaryVC = [self primaryViewControllerForDoppelgangerViewController:viewController];
        if ([primaryVC respondsToSelector:@selector(doppelgangerViewControllerDidLayoutSubviews)]) {
            [primaryVC doppelgangerViewControllerDidLayoutSubviews];
        }
    }
}

- (BOOL)isDoppelgangerViewController:(UIViewController *)viewController {
    return objc_getAssociatedObject(viewController, &ViewControllerIsDoppelganger) != nil;
}

- (UIViewController<ATExternalScreenAwareController> *)primaryViewControllerForDoppelgangerViewController:(UIViewController *)viewController {
    return objc_getAssociatedObject(viewController, &ViewControllerDoppelgangersPrimaryViewController);
}

- (void)presentOnExternalScreen {
    if (_primaryViewController == nil)
        return;

    UIViewController *doppelganger = [_primaryViewController doppelgangerViewController];
    [doppelganger at_markAsDoppelgangerOfViewController:_primaryViewController];
    [doppelganger view]; // load view, now that its isDoppelganger will return YES

    if ([_primaryViewController respondsToSelector:@selector(configureDoppelgangerViewController)]) {
        [_primaryViewController configureDoppelgangerViewController];
    }

    if (_externalDisplayWindow.rootViewController == nil) {
        _externalDisplayWindow.rootViewController = doppelganger;
        if ([_primaryViewController respondsToSelector:@selector(doppelgangerViewControllerDidAppear)]) {
            [_primaryViewController doppelgangerViewControllerDidAppear];
        }
    } else {
        [UIView transitionWithView:_externalDisplayWindow
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _externalDisplayWindow.rootViewController = doppelganger;
                        }
                        completion:^(BOOL finished){
                            if ([_primaryViewController respondsToSelector:@selector(doppelgangerViewControllerDidAppear)]) {
                                [_primaryViewController doppelgangerViewControllerDidAppear];
                            }
                        }];
    }
}

- (void)screenDidDisconnect:(NSNotification *)notification {
    self.externalDisplayWindow = nil;
}

- (void)presentDoppelgangerForViewController:(UIViewController *)presentedVC0 fromViewController:(UIViewController *)presentingVC animated:(BOOL)animated {
    // TODO: track more data to catch this case (safety purposes only, though; not strictly required)
//    if (_presentedViewController != nil) {
//        [_primaryViewController dismissViewControllerAnimated:NO completion:^{}];
//        _presentedViewController = nil;
//    }

    if (![presentedVC0 conformsToProtocol:@protocol(ATExternalScreenAwareController)]) {
        return;
    }
    UIViewController<ATExternalScreenAwareController> *presentedVC = (UIViewController<ATExternalScreenAwareController> *)presentedVC0;

    UIViewController *doppelganger = [presentedVC doppelgangerViewController];
    [doppelganger at_markAsDoppelgangerOfViewController:presentedVC];
    [doppelganger view]; // load view, now that its isDoppelganger will return YES

    if ([presentedVC respondsToSelector:@selector(configureDoppelgangerViewController)]) {
        [presentedVC configureDoppelgangerViewController];
    }

    UIViewController *primaryDoppelganger = [_primaryViewController doppelgangerViewController];
    UIViewController *presentingDoppelganger = _presentedDoppelgangerViewController ?: primaryDoppelganger;

    doppelganger.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    doppelganger.view.autoresizesSubviews = YES;
    doppelganger.view.frame = presentingDoppelganger.view.frame;

    [presentingDoppelganger addChildViewController:doppelganger];
    [presentingDoppelganger.view addSubview:doppelganger.view];
    [doppelganger didMoveToParentViewController:presentingDoppelganger];

    _presentedDoppelgangerViewController = doppelganger;
}

- (void)dismissDoppelgangerViewControllerAnimated:(BOOL)animated {
    if (_presentedDoppelgangerViewController) {
//        UIViewController *primaryDoppelganger = [_primaryViewController doppelgangerViewController];
        UIViewController *presentedDoppelganger = _presentedDoppelgangerViewController;
        _presentedDoppelgangerViewController = _presentedDoppelgangerViewController.parentViewController;
        if (_presentedDoppelgangerViewController == _primaryViewController) {
            _presentedDoppelgangerViewController = nil;
        }

        [presentedDoppelganger willMoveToParentViewController:nil];
        [presentedDoppelganger.view removeFromSuperview];
        [presentedDoppelganger removeFromParentViewController];
    }
}

@end



@implementation UIViewController (ATExternalScreenController)

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
-(BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)isDoppelganger {
    return [[ATExternalScreenController sharedExternalScreenController] isDoppelgangerViewController:self];
}

- (void)at_markAsDoppelgangerOfViewController:(UIViewController *)primaryViewController {
    objc_setAssociatedObject(self, &ViewControllerIsDoppelganger, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &ViewControllerDoppelgangersPrimaryViewController, primaryViewController, OBJC_ASSOCIATION_ASSIGN);
   
}

- (void)at_presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {
    [self presentViewController:vc animated:animated completion:completion];
    [[ATExternalScreenController sharedExternalScreenController] presentDoppelgangerForViewController:(UIViewController<ATExternalScreenAwareController> *)vc fromViewController:self animated:animated];
}

- (void)at_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self dismissViewControllerAnimated:flag completion:completion];
    [[ATExternalScreenController sharedExternalScreenController] dismissDoppelgangerViewControllerAnimated:flag];
}

- (void)at_dismissThisViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self.presentingViewController at_dismissViewControllerAnimated:flag completion:completion];
}

- (IBAction)at_dismissThisViewController:(id)sender {
    [self at_dismissThisViewControllerAnimated:YES completion:^{}];
}

@end


void ATSyncHorizontallyPagedScrollViews(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView, BOOL animated) {
    if (!destinationScrollView) {
        return;
    }
    
    CGPoint sourceContentOffset = sourceScrollView.contentOffset;
    NSInteger sourcePageCount = (NSInteger) ceil(sourceScrollView.contentSize.width / sourceScrollView.bounds.size.width);
    NSInteger sourcePageIndex = (NSInteger) round(sourceContentOffset.x / sourceScrollView.bounds.size.width);
    sourcePageIndex = MIN(sourcePageIndex, sourcePageCount - 1);
    sourcePageIndex = MAX(sourcePageIndex, 0);
    
    CGPoint newOffset = CGPointMake(sourcePageIndex * destinationScrollView.bounds.size.width, 0);
    
    if (animated) {
        [destinationScrollView setContentOffset:newOffset animated:YES];
    } else {
        destinationScrollView.contentOffset = newOffset;
    }
}


void ATSyncScrollViews(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView) {
    if (!destinationScrollView) {
        return;
    }
#if 0
    destinationScrollView.backgroundColor = [UIColor redColor];
    ((UIView *)[destinationScrollView.subviews firstObject]).backgroundColor = [UIColor greenColor];
#endif

    CGPoint sourceContentOffset = sourceScrollView.contentOffset;
    CGSize sourceContentSize = sourceScrollView.contentSize;

    CGSize sourceBoundsSize = sourceScrollView.bounds.size;
    CGFloat sourceScale = sourceScrollView.zoomScale;

    CGSize contentSize = CGSizeMake(sourceContentSize.width / sourceScale,
                                    sourceContentSize.height / sourceScale);

    NSLog(@"ATSyncScrollViews: sourceOrigin = %@, sourceContentSize = %@, sourceBoundsSize = %@, sourceScale = %.1lf", NSStringFromCGPoint(sourceContentOffset), NSStringFromCGSize(sourceContentSize), NSStringFromCGSize(sourceBoundsSize), (double)sourceScale);

    CGSize sourceVisibleContentAreaSize = CGSizeMake(MIN(sourceBoundsSize.width / sourceScale, contentSize.width),
                                                     MIN(sourceBoundsSize.height / sourceScale, contentSize.height));

    CGPoint centerOfSourceVisibleContentArea = CGPointMake(sourceContentOffset.x / sourceScale + sourceVisibleContentAreaSize.width / 2,
                                                           sourceContentOffset.y / sourceScale + sourceVisibleContentAreaSize.height / 2);

    NSLog(@"ATSyncScrollViews: centerOfSourceVisibleContentArea = %@, contentSize = %@, sourceVisibleContentAreaSize = %@", NSStringFromCGPoint(centerOfSourceVisibleContentArea), NSStringFromCGSize(contentSize), NSStringFromCGSize(sourceVisibleContentAreaSize));

    CGSize destinationBoundsSize = destinationScrollView.bounds.size;
    CGPoint destinationScaleCandidates = CGPointMake(destinationBoundsSize.width / sourceVisibleContentAreaSize.width,
                                                     destinationBoundsSize.height / sourceVisibleContentAreaSize.height);
    CGFloat destinationScale = MAX(destinationScaleCandidates.x, destinationScaleCandidates.y);

    CGSize destinationVisibleContentAreaSize = CGSizeMake(MIN(destinationBoundsSize.width / destinationScale, contentSize.width),
                                                          MIN(destinationBoundsSize.height / destinationScale, contentSize.height));

    CGPoint destinationVisibleContentAreaOrigin = CGPointMake((centerOfSourceVisibleContentArea.x - destinationVisibleContentAreaSize.width / 2),
                                                              (centerOfSourceVisibleContentArea.y - destinationVisibleContentAreaSize.height / 2));
    NSLog(@"ATSyncScrollViews: destinationVisibleContentAreaOrigin = %@, destinationVisibleContentAreaSize = %@, destinationBoundsSize = %@, destinationScaleCandidates = %@, destinationScale = %.1lf", NSStringFromCGPoint(destinationVisibleContentAreaOrigin), NSStringFromCGSize(destinationVisibleContentAreaSize), NSStringFromCGSize(destinationBoundsSize), NSStringFromCGPoint(destinationScaleCandidates), (double)destinationScale);

    // this may result in negative coordinates, but they'll be fixed on the next step
    if (destinationVisibleContentAreaOrigin.x > contentSize.width - destinationVisibleContentAreaSize.width)
        destinationVisibleContentAreaOrigin.x = contentSize.width - destinationVisibleContentAreaSize.width;
    if (destinationVisibleContentAreaOrigin.y > contentSize.height - destinationVisibleContentAreaSize.height)
        destinationVisibleContentAreaOrigin.y = contentSize.height - destinationVisibleContentAreaSize.height;

    if (destinationVisibleContentAreaOrigin.x < 0)
        destinationVisibleContentAreaOrigin.x = 0;
    if (destinationVisibleContentAreaOrigin.y < 0)
        destinationVisibleContentAreaOrigin.y = 0;

    CGRect destinationContentRect = (CGRect) { .origin = destinationVisibleContentAreaOrigin, .size = destinationVisibleContentAreaSize };
    static const CGFloat kComparisonPrecision = 1e-4;
    if (fabs(destinationScrollView.minimumZoomScale - destinationScrollView.maximumZoomScale) < kComparisonPrecision) {
        [destinationScrollView scrollRectToVisible:destinationContentRect animated:NO];
    } else {
        [destinationScrollView zoomToRect:destinationContentRect animated:NO];
    }

    NSLog(@"ATSyncScrollViews: resulting destination contentOffset = %@, contentSize = %@, zoomScale = %.1lf, destinationContentRect = %@", NSStringFromCGPoint(destinationScrollView.contentOffset), NSStringFromCGSize(destinationScrollView.contentSize), (double)destinationScrollView.zoomScale, NSStringFromCGRect(destinationContentRect));
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"ATSyncScrollViews after delay: resulting destination contentOffset = %@, contentSize = %@, zoomScale = %.1lf", NSStringFromCGPoint(destinationScrollView.contentOffset), NSStringFromCGSize(destinationScrollView.contentSize), (double)destinationScrollView.zoomScale);
//    });
}


void ATSyncScrollViewsAspectFit(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView) {
    if (!destinationScrollView) {
        return;
    }
#if 0
    destinationScrollView.backgroundColor = [UIColor redColor];
    ((UIView *)[destinationScrollView.subviews firstObject]).backgroundColor = [UIColor greenColor];
#endif

    CGPoint sourceContentOffset = sourceScrollView.contentOffset;
    CGSize sourceContentSize = sourceScrollView.contentSize;
    
    CGSize sourceBoundsSize = sourceScrollView.bounds.size;
    CGFloat sourceScale = sourceScrollView.zoomScale;
    
    CGSize contentSize = CGSizeMake(sourceContentSize.width / sourceScale,
                                    sourceContentSize.height / sourceScale);
    
    NSLog(@"ATSyncScrollViewsAspectFit: sourceOrigin = %@, sourceContentSize = %@, sourceBoundsSize = %@, sourceScale = %.1lf", NSStringFromCGPoint(sourceContentOffset), NSStringFromCGSize(sourceContentSize), NSStringFromCGSize(sourceBoundsSize), (double)sourceScale);
    
    CGSize sourceVisibleContentAreaSize = CGSizeMake(MIN(sourceBoundsSize.width / sourceScale, contentSize.width),
                                                     MIN(sourceBoundsSize.height / sourceScale, contentSize.height));
    
    CGPoint centerOfSourceVisibleContentArea = CGPointMake(sourceContentOffset.x / sourceScale + sourceVisibleContentAreaSize.width / 2,
                                                           sourceContentOffset.y / sourceScale + sourceVisibleContentAreaSize.height / 2);
    
    NSLog(@"ATSyncScrollViewsAspectFit: centerOfSourceVisibleContentArea = %@, contentSize = %@, sourceVisibleContentAreaSize = %@", NSStringFromCGPoint(centerOfSourceVisibleContentArea), NSStringFromCGSize(contentSize), NSStringFromCGSize(sourceVisibleContentAreaSize));
    
    CGSize destinationBoundsSize = destinationScrollView.bounds.size;
    CGPoint destinationScaleCandidates = CGPointMake(destinationBoundsSize.width / sourceVisibleContentAreaSize.width,
                                                     destinationBoundsSize.height / sourceVisibleContentAreaSize.height);
    CGFloat destinationScale = MIN(destinationScaleCandidates.x, destinationScaleCandidates.y);
    
    CGSize destinationVisibleContentAreaSize = CGSizeMake(MIN(destinationBoundsSize.width / destinationScale, contentSize.width),
                                                          MIN(destinationBoundsSize.height / destinationScale, contentSize.height));
    
    CGPoint destinationVisibleContentAreaOrigin = CGPointMake((centerOfSourceVisibleContentArea.x - destinationVisibleContentAreaSize.width / 2),
                                                              (centerOfSourceVisibleContentArea.y - destinationVisibleContentAreaSize.height / 2));
    NSLog(@"ATSyncScrollViewsAspectFit: destinationVisibleContentAreaOrigin = %@, destinationVisibleContentAreaSize = %@, destinationBoundsSize = %@, destinationScaleCandidates = %@, destinationScale = %.1lf", NSStringFromCGPoint(destinationVisibleContentAreaOrigin), NSStringFromCGSize(destinationVisibleContentAreaSize), NSStringFromCGSize(destinationBoundsSize), NSStringFromCGPoint(destinationScaleCandidates), (double)destinationScale);
    
    // this may result in negative coordinates, but they'll be fixed on the next step
    if (destinationVisibleContentAreaOrigin.x > contentSize.width - destinationVisibleContentAreaSize.width)
        destinationVisibleContentAreaOrigin.x = contentSize.width - destinationVisibleContentAreaSize.width;
    if (destinationVisibleContentAreaOrigin.y > contentSize.height - destinationVisibleContentAreaSize.height)
        destinationVisibleContentAreaOrigin.y = contentSize.height - destinationVisibleContentAreaSize.height;
    
    if (destinationVisibleContentAreaOrigin.x < 0)
        destinationVisibleContentAreaOrigin.x = 0;
    if (destinationVisibleContentAreaOrigin.y < 0)
        destinationVisibleContentAreaOrigin.y = 0;
    
    CGRect destinationContentRect = (CGRect) { .origin = destinationVisibleContentAreaOrigin, .size = destinationVisibleContentAreaSize };
    static const CGFloat kComparisonPrecision = 1e-4;
    if (fabs(destinationScrollView.minimumZoomScale - destinationScrollView.maximumZoomScale) < kComparisonPrecision) {
        [destinationScrollView scrollRectToVisible:destinationContentRect animated:NO];
    } else {
        [UIView performWithoutAnimation:^{
            [destinationScrollView zoomToRect:destinationContentRect animated:NO];
        }];
    }
    
    NSLog(@"ATSyncScrollViewsAspectFit: resulting destination contentOffset = %@, contentSize = %@, zoomScale = %.1lf, destinationContentRect = %@", NSStringFromCGPoint(destinationScrollView.contentOffset), NSStringFromCGSize(destinationScrollView.contentSize), (double)destinationScrollView.zoomScale, NSStringFromCGRect(destinationContentRect));
    if (destinationScrollView.contentOffset.x < -1) {
        NSLog(@">> Negative offset <<");
        destinationScrollView.contentOffset = CGPointMake(0, destinationScrollView.contentOffset.y);
    }
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"ATSyncScrollViewsAspectFit after delay: resulting destination contentOffset = %@, contentSize = %@, zoomScale = %.1lf", NSStringFromCGPoint(destinationScrollView.contentOffset), NSStringFromCGSize(destinationScrollView.contentSize), (double)destinationScrollView.zoomScale);
//    });
}
