//
//  RecordedVideo.h
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/15/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RecordedVideo : NSObject

@property (nonatomic, strong) NSURL   *videoUrl;
@property (nonatomic, strong) UIImage *videoThumbnail;

@end
