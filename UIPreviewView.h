//
//  UIPreviewView.h
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/11/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

#import <UIKit/UIKit.h>
@import AVFoundation;
@class AVCaptureSession;

@interface UIPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (nonatomic) CMTime defaultVideoMaxFrameDuration;
- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS;
- (void)resetFormat;

@end
