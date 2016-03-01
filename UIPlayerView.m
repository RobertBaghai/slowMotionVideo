//
//  UIPlayerView.m
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/16/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//
@import Foundation;
@import AVFoundation;
#import "UIPlayerView.h"

@implementation UIPlayerView

-(AVPlayer *)player {
    return self.playerLayer.player;
}

-(void)setPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

// override UIView
+(Class)layerClass {
    return [AVPlayerLayer class];
}

-(AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

@end
