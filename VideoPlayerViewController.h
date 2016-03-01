//
//  VideoPlayerViewController.h
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/16/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

@import UIKit;
@class UIPlayerView;
@import AVFoundation;

@interface VideoPlayerViewController : UIViewController

@property (readonly) AVPlayer *player;
@property AVURLAsset *asset;
@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;
@property (nonatomic, strong) NSURL *passedInUrlForVideo;

@end

