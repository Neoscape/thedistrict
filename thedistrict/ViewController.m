//
//  ViewController.m
//  thedistrict
//
//  Created by Evan Buxton on 4/19/15.
//  Copyright (c) 2015 Evan Buxton. All rights reserved.
//

#import "ViewController.h"
#import "xhMediaViewController.h"
#import "FGalleryViewController.h"

@interface ViewController () <xhMediaDelegate, FGalleryViewControllerDelegate, UIGestureRecognizerDelegate>
{
    IBOutlet UISlider            *uisl_timerBar;
    
    NSTimer             *sliederTimer;
    UISwipeGestureRecognizer *pinchInRecognizer;
    UISwipeGestureRecognizer *swipeLeftRecognizer;
    UISwipeGestureRecognizer *swipeUpRecognizer;
    UISwipeGestureRecognizer *swipeDownRecognizer;
    FGalleryViewController	*localGallery;
    NSArray					*localImages;
    NSArray					*localCaptions;
}
// AVPlayer
@property (nonatomic, strong)           AVPlayerItem               *playerItem;
@property (nonatomic, strong)           AVPlayer                   *myAVPlayer;
@property (nonatomic, strong)           AVPlayerLayer              *myAVPlayerLayer;
@property (nonatomic, strong) xhMediaViewController     *player1;
@property (nonatomic, retain) IBOutlet UISegmentedControl *movieBtns;
@end

static NSUInteger kFrameFixer = 1;

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; //if you want superclass's behaviour...
    // resize your layers based on the view's new frame
    self.myAVPlayerLayer.frame = self.uiv_myPlayerContainer.bounds;
}

#pragma mark - menu actions
-(void)playMovie:(id)sender
{
    _uiv_myPlayerContainer.hidden = NO;
    NSString *url = [[NSBundle mainBundle] pathForResource:@"Trademark_VictoryPark_FinalCut_040114_for_mac_HD_HD" ofType:@"mov"];
    [self createMainAVPlayer:url];
    [self addGestureToAvPlayer];
//    //[self.view addSubview: _uiv_myPlayerContainer];
    [_myAVPlayer play];
}

-(IBAction)loadGallery:(id)sender {
    localImages= nil;
    localImages = [[NSArray alloc] initWithObjects:
                   @"Simon_Clearfork_View_01_2015_04_10.jpg",
                   @"Simon_Clearfork_View_02_2015_04_10.jpg",
                   @"Simon_Clearfork_View_03_2015_04_10.jpg",
                   @"Simon_Clearfork_View_04_2015_04_10.jpg",
                   @"Simon_Clearfork_View_05_2015_04_10.jpg",
                   @"Simon_Clearfork_View_06_2015_04_10.jpg",
                   @"Simon_Clearfork_View_07_2015_04_10.jpg",
                   @"Simon_Clearfork_View_08_2015_04_10.jpg",
                   @"Simon_Clearfork_View_09_2015_04_10.jpg",
                   @"Simon_Clearfork_View_10_2015_04_10.jpg",
                   nil];
    localGallery = [[FGalleryViewController alloc] initWithPhotoSource:self];
    UINavigationController*_navigationController = [[UINavigationController alloc]
                             initWithRootViewController:localGallery];
    _navigationController.view.frame = [self.view bounds];
    [self addChildViewController: _navigationController];
    [_navigationController setNavigationBarHidden:YES];
    
    [self.view addSubview:_navigationController.view];
}


#pragma mark - Create Main AVPlayer

- (void)createMainAVPlayer:(NSString *)movieUrl
{
//    if (_uiv_myPlayerContainer) {
//        [_uiv_myPlayerContainer removeFromSuperview];
//        _uiv_myPlayerContainer = nil;
//    }
    
    //_uiv_myPlayerContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 86.0, 1024.0, 576.0)];
    _playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:movieUrl]];
    _myAVPlayer = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    _myAVPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:_myAVPlayer];
    _myAVPlayerLayer.frame = _uiv_myPlayerContainer.bounds;
    _myAVPlayerLayer.backgroundColor = [UIColor clearColor].CGColor;
    
    _myAVPlayerLayer.needsDisplayOnBoundsChange = YES;
    [_uiv_myPlayerContainer.layer addSublayer:_myAVPlayerLayer];
    
    UIButton *uib_closeMainPlayer = [UIButton buttonWithType:UIButtonTypeCustom];
    uib_closeMainPlayer.frame = CGRectMake(0.0, 0.0, 100.0, 40.0);
    uib_closeMainPlayer.backgroundColor = [UIColor blackColor];
    [uib_closeMainPlayer setTitle:@"DONE" forState:UIControlStateNormal];
    [_uiv_myPlayerContainer addSubview: uib_closeMainPlayer];
    [uib_closeMainPlayer addTarget:self action:@selector(closeMainPlayer:) forControlEvents:UIControlEventTouchUpInside];
    
    [self createSlider];
    [self createSliderTimer];
}
#pragma mark Slider Action
- (void)createSlider
{
    //uisl_timerBar = [UISlider new];
    //uisl_timerBar.frame = CGRectMake(250.0, 0.0, 500.0, 40.0);
    uisl_timerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [uisl_timerBar setBackgroundColor:[UIColor clearColor]];
    uisl_timerBar.minimumValue = 0.0;
    uisl_timerBar.maximumValue = CMTimeGetSeconds([[_myAVPlayer.currentItem asset] duration]);
    uisl_timerBar.continuous = YES;
    [uisl_timerBar addTarget:self action:@selector(sliding:) forControlEvents:UIControlEventValueChanged];
    [uisl_timerBar addTarget:self action:@selector(finishedSliding:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    [_uiv_myPlayerContainer addSubview:uisl_timerBar];
}

- (void)sliding:(id)sender
{
    [_myAVPlayer pause];
    UISlider *slider = sender;
    CMTime newTime = CMTimeMakeWithSeconds(slider.value,600);
    [_myAVPlayer seekToTime:newTime
           toleranceBefore:kCMTimeZero
            toleranceAfter:kCMTimeZero];
}

- (void)finishedSliding:(id)sener
{
    [_myAVPlayer play];
}

/*
 Add Timer to slider
 */
- (void)createSliderTimer
{
    sliederTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(updateSliderAndTimelabel) userInfo:nil repeats:YES];
}

/*
 Slider action -- adjust slider's positon and update number of time label
 */
- (void)updateSliderAndTimelabel
{
    uisl_timerBar.maximumValue = CMTimeGetSeconds([[_myAVPlayer.currentItem asset] duration]);
    uisl_timerBar.value = CMTimeGetSeconds(_myAVPlayer.currentTime);
}


#pragma mark Close Main Movie Player
- (void)closeMainPlayer:(id)sender
{
    [UIView animateWithDuration:0.50 delay:0.0 options:0
                     animations:^{
//                         movieBtns.selectedSegmentIndex = 0;
//                         
//                         movieThumb.frame = CGRectMake(26, 284, 314, 180);
//                         movieThumb02.frame = CGRectMake(354, 284, 314, 180);
//                         movieThumb03.frame = CGRectMake(682, 284, 314, 180);
//                         
//                         if (movieTag==0) {
//                             movieViewBlack.frame = CGRectMake(26, 284, 314, 180);
//                         } else if (movieTag==1) {
//                             movieViewBlack.frame = CGRectMake(354, 284, 314, 180);
//                         } else if (movieTag==2){
//                             movieViewBlack.frame = CGRectMake(682, 284, 314, 180);
//                         }
//                         movieViewBlack.alpha = 0.0;
//                         movieShadow.alpha = 1.0;
//                         movieViewBottom.transform = CGAffineTransformIdentity;
//                         movieViewTop.transform = CGAffineTransformIdentity;
//                         uiv_profileContainer.alpha = 0.0;
                         [_uiv_myPlayerContainer setHidden:YES];
//                         [self.view bringSubviewToFront:playButton03];
//                         [self.view bringSubviewToFront:playButton02];
//                         [self.view bringSubviewToFront:playButton];
                         
                     }
                     completion:^(BOOL finished) {
//                         playButton.hidden = NO;
//                         playButton02.hidden = NO;
//                         playButton03.hidden = NO;
//                         
//                         movieViewTop.layer.cornerRadius = 0;
//                         movieViewTop.layer.shadowOffset = CGSizeMake(0,0);
//                         movieViewTop.layer.shadowRadius = 0;
//                         movieViewTop.layer.shadowOpacity = 0.0;
                         
                         //Kill AVplayer
                         [_myAVPlayer pause];
                         [_myAVPlayerLayer removeFromSuperlayer];
                         _myAVPlayerLayer = nil;
                         _myAVPlayer = nil;
                         _playerItem = nil;
                         
//                         //Kill profiles container
//                         [uiv_profileContainer removeFromSuperview];
//                         [uiv_profileContainer release];
//                         uiv_profileContainer = nil;
                         [sliederTimer invalidate];
                         
                         //kill swipe gestures
                         pinchInRecognizer.enabled = NO;
                         pinchInRecognizer.delegate = nil;
                         swipeLeftRecognizer.enabled = NO;
                         swipeLeftRecognizer.delegate = nil;
                         swipeUpRecognizer.enabled = NO;
                         swipeUpRecognizer.delegate = nil;
                         swipeDownRecognizer.enabled = NO;
                         swipeDownRecognizer.delegate = nil;
                         
                         _uiv_myPlayerContainer.hidden = YES;

                     }];
    
}

#pragma mark add Gesture to AVPlayer container

- (void)addGestureToAvPlayer
{
    pinchInRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeNextSection:)];
    [pinchInRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [pinchInRecognizer setDelegate:self];
    [_uiv_myPlayerContainer addGestureRecognizer:pinchInRecognizer];
    
    swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePrevSection:)];
    [swipeLeftRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [swipeLeftRecognizer setDelegate:self];
    [_uiv_myPlayerContainer addGestureRecognizer:swipeLeftRecognizer];
    
    swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUpPlay:)];
    [swipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [swipeUpRecognizer setDelegate:self];
    [_uiv_myPlayerContainer addGestureRecognizer:swipeUpRecognizer];
    
    swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDownPause:)];
    [swipeDownRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [swipeDownRecognizer setDelegate:self];
    [_uiv_myPlayerContainer addGestureRecognizer:swipeDownRecognizer];
}

-(void)swipePrevSection:(id)sender {
    NSLog(@"Swipe left");
    if([(UISwipeGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
        if (_movieBtns.selectedSegmentIndex != 0) {
            _movieBtns.selectedSegmentIndex--;
            UISegmentedControl *button = (UISegmentedControl *)sender;
            [self movieShouldJump:button];
        } else {
            return;
        }
    }
}

-(void)swipeNextSection:(id)sender {
    NSLog(@"Swipe right");
    if([(UISwipeGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if (_movieBtns.selectedSegmentIndex == 6) {
            return;
        } else {
            NSLog(@"Not Yet");
            _movieBtns.selectedSegmentIndex++;
            UISegmentedControl *button = (UISegmentedControl *)sender;
            [self movieShouldJump:button];
        }
    }
}

-(void)swipeUpPlay:(id)sender
{
    [_myAVPlayer play];
}


-(void)swipeDownPause:(id)sender
{
    [_myAVPlayer pause];
}


#pragma mark - Jump movie
-(IBAction)movieShouldJump:(id)sender {
    
    NSUInteger i = _movieBtns.selectedSegmentIndex;
    
    [_myAVPlayer pause];
    
    NSArray *arr_Timecode = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithFloat:0], //intro
                    [NSNumber numberWithFloat:50+kFrameFixer], //map
                    [NSNumber numberWithFloat:61+kFrameFixer], // cont - OK
                    [NSNumber numberWithFloat:92+kFrameFixer], //2 level
                    [NSNumber numberWithFloat:128+kFrameFixer], //glass
                    nil];
    
    NSString *myString = [arr_Timecode objectAtIndex:i];
    Float64 stringfloat = [myString floatValue];
    
    CMTime jumpTime = CMTimeMakeWithSeconds(stringfloat, 1);
    [_myAVPlayer seekToTime:jumpTime];
    [_myAVPlayer pause];
}

#pragma mark - FGallery Delegate Method
#pragma mark - FGalleryViewControllerDelegate Methods
- (int)numberOfPhotosForPhotoGallery:(FGalleryViewController *)gallery
{
    int num = (int)[localImages count];
    return num;
}

- (FGalleryPhotoSourceType)photoGallery:(FGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index
{
    if( gallery == localGallery ) {
        return FGalleryPhotoSourceTypeLocal;
    }
    else return FGalleryPhotoSourceTypeNetwork;
}

- (NSString*)photoGallery:(FGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index
{
    NSString *caption;
    if( gallery == localGallery ) {
        caption = [localCaptions objectAtIndex:index];
    }
    //    else if( gallery == networkGallery ) {
    //        caption = [networkCaptions objectAtIndex:index];
    //    }
    return caption;
}

- (NSString*)photoGallery:(FGalleryViewController*)gallery filePathForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    return [localImages objectAtIndex:index];
}

- (void)handleTrashButtonTouch:(id)sender {
    // here we could remove images from our local array storage and tell the gallery to remove that image
    // ex:
    //[localGallery removeImageAtIndex:[localGallery currentIndex]];
}

- (void)handleEditCaptionButtonTouch:(id)sender {
    // here we could implement some code to change the caption for a stored image
}


#pragma mark - Boilerplate

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end