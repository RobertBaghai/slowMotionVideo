//
//  UIPlayerView.h
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/16/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

@import UIKit;
@class AVPlayer;

@interface UIPlayerView : UIView

@property AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;

@end
