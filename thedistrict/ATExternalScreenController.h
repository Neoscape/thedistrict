
#import <Foundation/Foundation.h>


@protocol ATExternalScreenAwareController;

// This class helps you to present a copy of your application's UI on an external screen.
// It works by running a copy of your view controller on the external screen's window.
// The copy is called a “doppelgänger”.
//
// Your view controllers:
//
// * create their doppelgängers
// * sync their state to their doppelgängers
// * forwards lifecycle events (viewDidAppear, etc) to ATExternalScreenController
//
// ATExternalScreenController:
//
// * monitors connection and disconnection of external displays
// * asks your view controller for a doppelgänger at an appropriate time
// * decides which doppelgänger to display, based on the lifecycle events forwarded by your view controllers
// * animates (cross-fades) between doppelgänger views when switching doppelgängers
//
//
// Here's a step-by-step guide to using ATExternalScreenController in your view controller:
//
// 1. #import "ATExternalScreenController.h"
//
// 2. Forward all lifecycle methods to ATExternalScreenController:
//
//    - (void)viewWillAppear:(BOOL)animated {
//        [super viewWillAppear:animated];
//        [[ATExternalScreenController sharedExternalScreenController] viewWillAppear:animated forViewController:self];
//    }
//
//    - (void)viewDidAppear:(BOOL)animated {
//        [super viewDidAppear:animated];
//        [[ATExternalScreenController sharedExternalScreenController] viewDidAppear:animated forViewController:self];
//    }
//
//    - (void)viewWillDisappear:(BOOL)animated {
//        [super viewWillDisappear:animated];
//        [[ATExternalScreenController sharedExternalScreenController] viewWillDisappear:animated forViewController:self];
//    }
//
//    - (void)viewDidDisappear:(BOOL)animated {
//        [super viewDidDisappear:animated];
//        [[ATExternalScreenController sharedExternalScreenController] viewDidDisappear:animated forViewController:self];
//    }
//
// 3. Declare conformance to protocol ATExternalScreenAwareController
//
// 4. Declare a field to hold the doppelgänger:
//
//    @implementation MyViewController {
//        MyViewController *_doppelgangerViewController;
//    }
//
// 5. Implement doppelgangerViewController getter to create the doppelgänger lazily:
//
//    - (UIViewController *)doppelgangerViewController {
//        if (_doppelgangerViewController == nil) {
//            _doppelgangerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MyViewController"];
//            _doppelgangerViewController.somePropertyu = self.somePropertyu;
//        }
//        return _doppelgangerViewController;
//    }
//
// 6. Optionally, when the user does something like scrolling your view controller, mirror the action on the doppelgänger:
//
// ...
//
@interface ATExternalScreenController : NSObject

+ (instancetype)sharedExternalScreenController;

- (void)viewWillAppear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController;
- (void)viewDidAppear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController;
- (void)viewWillDisappear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController;
- (void)viewDidDisappear:(BOOL)animated forViewController:(UIViewController<ATExternalScreenAwareController> *)primaryViewController;

- (void)viewDidLayoutSubviewsForViewController:(UIViewController *)viewController;

- (void)presentDoppelgangerForViewController:(UIViewController *)presentedVC fromViewController:(UIViewController *)presentingVC animated:(BOOL)animated;

- (void)dismissDoppelgangerViewControllerAnimated:(BOOL)animated;

@end


@protocol ATExternalScreenAwareController <NSObject>

@property (nonatomic, readonly) UIViewController *doppelgangerViewController;

@optional

- (void)configureDoppelgangerViewController;
- (void)doppelgangerViewControllerWillAppear;
- (void)doppelgangerViewControllerDidAppear;
- (void)doppelgangerViewControllerDidLayoutSubviews;

@end


@interface UIViewController (ATExternalScreenController)

@property (nonatomic, readonly, getter = isDoppelganger) BOOL dopperganger;

- (void)at_markAsDoppelgangerOfViewController:(UIViewController *)primaryViewController;

- (void)at_presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion;

- (void)at_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

- (void)at_dismissThisViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

- (IBAction)at_dismissThisViewController:(id)sender;

@end


void ATSyncHorizontallyPagedScrollViews(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView, BOOL animated);
void ATSyncScrollViews(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView);
void ATSyncScrollViewsAspectFit(UIScrollView *sourceScrollView, UIScrollView *destinationScrollView);
