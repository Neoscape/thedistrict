//
//  xhMediaViewController.m
//  AvPlayerDemo
//
//  Created by Xiaohe Hu on 12/18/14.
//  Copyright (c) 2014 Neoscape. All rights reserved.
//

#import "xhMediaViewController.h"

@interface xhMediaViewController ()
{

    NSURL           *fileURL;
    UIView          *uiv_controlPanel;
    UIView          *uiv_topContainer;
    UIButton        *uib_playPause;
    UISlider        *uisl_timerBar;
    NSTimer         *checkTimer;
    NSTimer         *sliederTimer;
    UIButton        *uib_doneButton;
}

@end

@implementation xhMediaViewController
@synthesize delegate;
@synthesize repeat;
@synthesize myAVPlayer;
@synthesize myAVPlayerLayer;
@synthesize playerItem;
@synthesize hideControl;

- (id)initWithURL:(NSURL *)url
{
    if (self == [super init]) {
        self.view.frame = [[UIScreen mainScreen] bounds];
        fileURL = url;
        [self playWithURL:fileURL];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.view.frame = [[UIScreen mainScreen] bounds];
    if (!hideControl) {
        [self addGestureToView];
        [self createControlPanel];
        [self createTopContainer];
        [self performSelector:@selector(createCheckTimer) withObject:nil afterDelay:2.0];
        [self createSliderTimer];
        [self createDoneButton];
    }
}

#pragma mark - Init AVPlayer with the URL
- (void)playWithURL:(NSURL *)url
{
    if (myAVPlayer) {
        myAVPlayer = nil;
        [myAVPlayerLayer removeFromSuperlayer];
        myAVPlayerLayer = nil;
        playerItem = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    playerItem = [AVPlayerItem playerItemWithURL:url];
    myAVPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    myAVPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:myAVPlayer];
    CGRect frame = self.view.bounds;
    myAVPlayerLayer.frame = frame;
    myAVPlayerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.view.layer addSublayer: myAVPlayerLayer];
    
    [myAVPlayer play];
}

#pragma mark Listen avplayer's notification when reaches End
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (!hideControl) {
        [uisl_timerBar setValue:0.0];
        [checkTimer invalidate];
        checkTimer = nil;
        [self createCheckTimer];
    }
    if (repeat) {
        [myAVPlayer seekToTime:kCMTimeZero];
        [myAVPlayer play];
        NSLog(@"Should repeat the movie!!");
    }
   
    [self.delegate didRemoveFromSuperView:self];
}

- (void)createTopContainer
{
    uiv_topContainer = [UIView new];
    uiv_topContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [uiv_topContainer setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.6]];
    [self.view addSubview:uiv_topContainer];
    
    // Size contstraints
    NSArray *control_constraint_H = [NSLayoutConstraint
                                     constraintsWithVisualFormat:@"V:[uiv_topContainer(60)]"
                                     options:0
                                     metrics:nil
                                     views:NSDictionaryOfVariableBindings(uiv_topContainer)];
    
    NSArray *control_constraint_V = [NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:|[uiv_topContainer]|"
                                     options:0
                                     metrics:nil
                                     views:NSDictionaryOfVariableBindings(uiv_topContainer)];
    [self.view addConstraints: control_constraint_H];
    [self.view addConstraints: control_constraint_V];
    
    // Position constraints
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:|-offsetTop-[uiv_topContainer]"
                            options:0
                            metrics:@{@"offsetTop": @0}
                            views:NSDictionaryOfVariableBindings(uiv_topContainer)];
    
    [self.view addConstraints: constraints];
    
    [self.view addConstraint:
    [NSLayoutConstraint constraintWithItem:uiv_topContainer
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                                  attribute:NSLayoutAttributeCenterX
                                  multiplier:1
                                  constant:0]];
    [self createSlider];
}

- (void)createSlider
{
    uisl_timerBar = [UISlider new];
    uisl_timerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [uisl_timerBar setBackgroundColor:[UIColor clearColor]];
    uisl_timerBar.minimumValue = 0.0;
    uisl_timerBar.maximumValue = [self currentItemDuration];;
    uisl_timerBar.continuous = YES;
    [uisl_timerBar addTarget:self action:@selector(sliding:) forControlEvents:UIControlEventValueChanged];
    [uisl_timerBar addTarget:self action:@selector(finishedSliding:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    [uiv_topContainer addSubview:uisl_timerBar];

    // Position constraints
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:|-offsetTop-[uisl_timerBar]"
                            options:0
                            metrics:@{@"offsetTop": @10}
                            views:NSDictionaryOfVariableBindings(uisl_timerBar)];
    NSArray *constraints1 = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|-offsetLeft-[uisl_timerBar]"
                            options:0
                            metrics:@{@"offsetLeft": @100}
                            views:NSDictionaryOfVariableBindings(uisl_timerBar)];
    NSArray *constraints2 = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:[uisl_timerBar]-offsetRight-|"
                            options:0
                            metrics:@{@"offsetRight": @100}
                            views:NSDictionaryOfVariableBindings(uisl_timerBar)];
    
    [self.view addConstraints: constraints];
    [self.view addConstraints: constraints1];
    [self.view addConstraints: constraints2];
    [self.view addConstraint:
     [NSLayoutConstraint constraintWithItem:uisl_timerBar
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                                  attribute:NSLayoutAttributeCenterX
                                  multiplier:1
                                  constant:0]];
}

- (void)sliding:(id)sender
{
    [checkTimer invalidate];
    checkTimer = nil;
    uiv_controlPanel.alpha = 1.0;
    uiv_controlPanel.hidden = NO;
    uiv_topContainer.alpha = 1.0;
    uiv_topContainer.hidden = NO;
    myAVPlayerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    UISlider *slider = sender;
    CMTime newTime = CMTimeMakeWithSeconds(slider.value/1000,600);
    [myAVPlayer seekToTime:newTime
                toleranceBefore:kCMTimeZero
                toleranceAfter:kCMTimeZero];
}

- (void)finishedSliding:(id)sener
{
    [self createCheckTimer];
}

- (void)createSliderTimer
{
    sliederTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
}

- (void)updateSlider
{
    uisl_timerBar.maximumValue = [self currentItemDuration];
    uisl_timerBar.value = [self curretnItemTime];
}

- (float)currentItemDuration
{
    AVAsset *asset = [myAVPlayer.currentItem asset];
    float duration = CMTimeGetSeconds([asset duration]);
    return duration*1000;
}

- (float)curretnItemTime
{
    float time = CMTimeGetSeconds([myAVPlayer currentTime]);
    return time*1000;
}

#pragma mark - Create Done Button

- (void)createDoneButton
{
    uib_doneButton = [UIButton buttonWithType: UIButtonTypeCustom];
    uib_doneButton.frame = CGRectMake(0.0, 0.0, 80.0, 60.0);
    uib_doneButton.backgroundColor = [UIColor clearColor];
    [uib_doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [uib_doneButton setTintColor:[UIColor grayColor]];
    uib_doneButton.showsTouchWhenHighlighted = YES;
    [uiv_topContainer addSubview: uib_doneButton];
    [uib_doneButton addTarget:self action:@selector(tapDoneButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) tapDoneButton:(id)sender
{
    [myAVPlayer pause];
    [self.delegate didRemoveFromSuperView:self];
}

#pragma mark - Create the Control Panle
- (void)createControlPanel
{
    uiv_controlPanel = [UIView new];
    uiv_controlPanel.translatesAutoresizingMaskIntoConstraints = NO;
    uiv_controlPanel.backgroundColor = [UIColor blackColor];
    uiv_controlPanel.layer.borderWidth = 2.0;
    uiv_controlPanel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    uiv_controlPanel.layer.cornerRadius = 10.0;
    [self.view addSubview:uiv_controlPanel];
 
    // Size contstraints
    NSArray *control_constraint_H = [NSLayoutConstraint
                                     constraintsWithVisualFormat:@"V:[uiv_controlPanel(60)]"
                                     options:0
                                     metrics:nil
                                     views:NSDictionaryOfVariableBindings(uiv_controlPanel)];

    NSArray *control_constraint_V = [NSLayoutConstraint
                                     constraintsWithVisualFormat:@"H:[uiv_controlPanel(300)]"
                                     options:0
                                     metrics:nil
                                     views:NSDictionaryOfVariableBindings(uiv_controlPanel)];
    [self.view addConstraints: control_constraint_H];
    [self.view addConstraints: control_constraint_V];
    
    // Position constraints
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:[uiv_controlPanel]-offsetBottom-|"
                            options:0
                            metrics:@{@"offsetBottom": @60}
                            views:NSDictionaryOfVariableBindings(uiv_controlPanel)];

    [self.view addConstraints: constraints];
    
    [self.view addConstraint:
        [NSLayoutConstraint constraintWithItem:uiv_controlPanel
                                     attribute:NSLayoutAttributeCenterX
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.view
                                     attribute:NSLayoutAttributeCenterX
                                     multiplier:1
                                     constant:0]];
    
    [self addControlButtons];

}

- (void)addControlButtons
{
    uib_playPause = [UIButton buttonWithType: UIButtonTypeCustom];
    uib_playPause.frame = CGRectMake(0.0, 0.0, 300.0, 60.0);
    [uib_playPause setTitle:@"PAUSE" forState:UIControlStateNormal];
    [uib_playPause setTitle:@"PLAY" forState:UIControlStateSelected];
    [uiv_controlPanel addSubview: uib_playPause];
    [uib_playPause addTarget:self action:@selector(tapPlayPause:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)tapPlayPause:(id)sender
{
    UIButton *tappedBtn = sender;
    if (tappedBtn.selected) {
        [myAVPlayer play];
    }
    else
    {
        [myAVPlayer pause];
    }
    tappedBtn.selected = !tappedBtn.selected;
}

#pragma mark - Add Tap Gesutre to whole view
- (void)addGestureToView
{
    UITapGestureRecognizer *tapOnplayer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnPlayer:)];
    tapOnplayer.numberOfTapsRequired = 1;
    self.view.userInteractionEnabled = YES;
    [self.view addGestureRecognizer: tapOnplayer];
}

- (void)tapOnPlayer:(UIGestureRecognizer *)gesture
{
    [checkTimer invalidate];
    checkTimer = nil;
    [self hidePanel];
    [self unhidePanel];
    [self createCheckTimer];
}

#pragma mark - Add timer to hide control panel

- (void)createCheckTimer
{
    checkTimer =[NSTimer scheduledTimerWithTimeInterval:3.0
                         target:self
                         selector:@selector(checkControlPanel)
                         userInfo:nil
                         repeats:YES];
}

- (void) checkControlPanel
{
    if (!uiv_controlPanel.hidden) {
        [checkTimer invalidate];
        checkTimer = nil;
        [self hidePanel];
        [self createCheckTimer];
    }
}

#pragma mark - Un/Hide control panel
- (void)hidePanel
{
    if (!uiv_controlPanel.hidden) {
        [UIView animateWithDuration:0.3 animations:^{
            myAVPlayerLayer.backgroundColor = [UIColor blackColor].CGColor;
            uiv_controlPanel.alpha = 0.0;
            uiv_topContainer.alpha = 0.0;
        } completion:^(BOOL finished){
            uiv_controlPanel.hidden = YES;
            uiv_topContainer.hidden = YES;
        }];
    }
    else
        return;
}

- (void)unhidePanel
{
    if (uiv_controlPanel.hidden) {
        uiv_controlPanel.hidden = NO;
        uiv_topContainer.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            myAVPlayerLayer.backgroundColor = [UIColor whiteColor].CGColor;
            uiv_controlPanel.alpha = 1.0;
            uiv_topContainer.alpha = 1.0;
        } completion:^(BOOL finished){        }];
    }
    else
        return;
}

-(void) viewWillLayoutSubviews {
    self.view.frame = self.view.superview.bounds;
    myAVPlayerLayer.frame = self.view.bounds;
}

#pragma mark - Clean Memory
- (void)viewDidDisappear:(BOOL)animated
{
    [myAVPlayer pause];
    myAVPlayer = nil;
    [myAVPlayerLayer removeFromSuperlayer];
    myAVPlayerLayer = nil;
    
    fileURL = nil;
    [uiv_controlPanel removeFromSuperview];
    uiv_controlPanel = nil;
    [uiv_topContainer removeFromSuperview];
    uiv_topContainer = nil;
    [uib_playPause removeFromSuperview];
    uib_playPause = nil;
    [uisl_timerBar removeFromSuperview];
    uisl_timerBar = nil;
    [uib_doneButton removeFromSuperview];
    uib_doneButton = nil;
    [checkTimer invalidate];
    checkTimer = nil;
    [sliederTimer invalidate];
    sliederTimer = nil;
    
//    [self removeObserver:self forKeyPath:AVPlayerItemDidPlayToEndTimeNotification];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
