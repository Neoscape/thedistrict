//
//  ViewController.h
//  thedistrict
//
//  Created by Evan Buxton on 4/19/15.
//  Copyright (c) 2015 Evan Buxton. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <AVFoundation/AVPlayer.h>
//#import <AVFoundation/AVAsset.h>
//#import <AVFoundation/AVMediaFormat.h>
//#import <AVFoundation/AVAudioMix.h>
//#import <AVFoundation/AVAssetTrack.h>
//#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController
{
    AVPlayerItem *playerItem1;
    AVPlayer *myAVPlayer1;
    AVPlayerLayer *myAVPlayerLayer1;
}

@property (nonatomic, strong) IBOutlet UIView *uiv_myPlayerContainer;

@end

