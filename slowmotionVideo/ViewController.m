//
//  ViewController.m
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/10/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

@import AVFoundation;
@import Photos;

#import "ViewController.h"
#import "UIPreviewView.h"
#import "RecordedVideo.h"

@interface ViewController () <AVCaptureFileOutputRecordingDelegate>
{
    BOOL isNeededToSave;
    CMTime defaultVideoMaxFrameDuration;
    NSTimeInterval startTime;
}

#pragma mark For Storyboard
@property (weak, nonatomic) IBOutlet UIPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *recordingButton;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fpsControl;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

#pragma mark Session Management
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDevice *audioDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput; //record into somewhere
@property (nonatomic, strong) AVCaptureConnection *captureConnection; //to be used later on
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;

#pragma mark Miscellaneous
@property (nonatomic, assign) NSTimer  *timer;
@property (nonatomic, strong) NSString *documentsDirectoryForVideos;
@property (nonatomic, strong) NSString *documentsDirectoryForThumbnails;
@property (nonatomic, strong) NSString *outputFilePath;
@property (nonatomic, strong) NSString *outputFileForThumbnailPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSession];
    [self createOrUseFileInDocumentsDirectoryForVideos];
    [self createOrUseFileInDocumentsDirectoryForThumbnails];
    [self listFileAtPath:self.documentsDirectoryForVideos];
    [self listFileAtPath:self.documentsDirectoryForThumbnails];
}

#pragma mark Set Up Session
-(void)makeSession {
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
    self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice error:nil];
    
    self.previewView.defaultFormat = self.videoDevice.activeFormat;
    self.previewView.defaultVideoMaxFrameDuration = self.videoDevice.activeVideoMaxFrameDuration;
    
    self.session = [[AVCaptureSession alloc] init];
    self.previewView.session = self.session;
    
    if ([self.session canAddInput:self.videoDeviceInput]) {
        [self.session addInput:self.videoDeviceInput];
    }
    if ([self.session canAddInput:self.audioDeviceInput]) {
        [self.session addInput:self.audioDeviceInput];
    }
    
    if ([self.captureVideoPreviewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    } else {
        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:_movieFileOutput]) {
        [self.session addOutput:_movieFileOutput];
        self.captureConnection = [_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( self.captureConnection.isVideoStabilizationSupported ) {
            self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
}

#pragma mark Create Files In Doc Directory
-(void)createOrUseFileInDocumentsDirectoryForVideos {
    NSString *directoryName = @"myVideos";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *applicationDirectory = [paths objectAtIndex:0];
    self.documentsDirectoryForVideos = [applicationDirectory stringByAppendingPathComponent:directoryName];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:self.documentsDirectoryForVideos
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    } else {
        NSLog(@"%@",self.documentsDirectoryForVideos);
    }
}

-(void)createOrUseFileInDocumentsDirectoryForThumbnails {
    NSString *directoryName = @"myThumbnails";
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *applicationDirectory = [paths objectAtIndex:0];
    self.documentsDirectoryForThumbnails = [applicationDirectory stringByAppendingPathComponent:directoryName];
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:self.documentsDirectoryForThumbnails
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    } else {
        NSLog(@"%@",self.documentsDirectoryForThumbnails);
    }
}

-(BOOL)shouldAutorotate {
    return !self.movieFileOutput.isRecording;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.session startRunning];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Capture And Save Video
-(IBAction)toggleMovieRecording:(id)sender {
    self.switchButton.enabled = NO;
    self.switchButton.alpha = 0.3;
    self.recordingButton.enabled = NO;
    self.fpsControl.enabled = NO;
    
    if (!self.movieFileOutput.isRecording) {
        startTime = [[NSDate date] timeIntervalSince1970];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                      target:self
                                                    selector:@selector(timerHandler:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        [ViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
        
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EE:LLLL-d-yyyy-HH:mm:ss"];
        NSString *timeStamp = [formatter stringFromDate:[NSDate date]];
        self.outputFilePath = [self.documentsDirectoryForVideos stringByAppendingPathComponent:[timeStamp stringByAppendingPathExtension:@"mov"]];
        self.outputFileForThumbnailPath = [self.documentsDirectoryForThumbnails stringByAppendingPathComponent:[timeStamp stringByAppendingPathExtension:@"png"]];
        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:self.outputFilePath] recordingDelegate:self];
        NSLog(@"OUTPUT FILE PATH VIDEOS --- %@",[NSURL fileURLWithPath:self.outputFilePath]);
        NSLog(@"OUTPUT FILE PATH THUMBNAILS --- %@",[NSURL fileURLWithPath:self.outputFileForThumbnailPath]);
        
    } else {
        [self.timer invalidate];
        self.timer = nil;
        isNeededToSave = YES;
        [self.movieFileOutput stopRecording];
        self.fpsControl.enabled = YES;
    }
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    dispatch_async( dispatch_get_main_queue(), ^{
        self.recordingButton.enabled = YES;
        [self.recordingButton setTitle:NSLocalizedString( @"Stop", @"Recording button stop title") forState:UIControlStateNormal];
    });
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    BOOL success = YES;
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    
    if ( success ) {
        // Make Thumbnail
        [self thumbnailImageFromURL:[NSURL fileURLWithPath:self.outputFilePath]];
        [self listFileAtPath:_documentsDirectoryForVideos];
        [self listFileAtPath:_documentsDirectoryForThumbnails];
        // Check authorization status.
        //for saving to photo Library
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                    // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                    if ( [PHAssetResourceCreationOptions class] ) {
                        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                        options.shouldMoveFile = NO;
                        PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                        [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                    } else {
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                    }
                } completionHandler:^( BOOL success, NSError *error ) {
                    if ( ! success ) {
                        NSLog( @"Could not save movie to photo library: %@", error );
                    }
                }];
            }
        }];
    }
    dispatch_async( dispatch_get_main_queue(), ^{
        self.recordingButton.enabled = YES;
        self.switchButton.enabled = YES;
        self.switchButton.alpha = 1.0;
        [self.recordingButton setTitle:NSLocalizedString( @"Record", @"Recording button record title" ) forState:UIControlStateNormal];
    });
}

#pragma mark Timer/Get Files At Path/ ThumbNails
-(NSArray *)listFileAtPath:(NSString *)path {
    NSLog(@"LISTING ALL FILES FOUND");
    int count;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (count = 0; count < (int)[directoryContent count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
    }
    return directoryContent;
}

- (void)timerHandler:(NSTimer *)timer {
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval recorded = current - startTime;
    self.timerLabel.text = [NSString stringWithFormat:@"%.2f", recorded];
}

- (UIImage *)thumbnailImageFromURL:(NSURL *)videoURL {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL: videoURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime requestedTime = CMTimeMake(0.0, 10.0);     // To create thumbnail image 0, 10th of a second
    CGImageRef imgRef = [generator copyCGImageAtTime:requestedTime actualTime:NULL error:&err];
    NSLog(@"err = %@, imageRef = %@", err, imgRef);
    
    UIImage *thumbnailImage = [[UIImage alloc] initWithCGImage:imgRef];
    NSData *pngData = UIImagePNGRepresentation(thumbnailImage);
    [pngData writeToFile:self.outputFileForThumbnailPath atomically:YES];
    CGImageRelease(imgRef);    // MUST release explicitly to avoid memory leak
    
    return thumbnailImage;
}

#pragma mark Switch Camera View
-(IBAction)changeCamera:(id)sender {
    AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
    AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
    AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
    
    switch ( currentPosition ) {
        case AVCaptureDevicePositionUnspecified:
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
    }
    
    AVCaptureDevice *videoDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    [self.session beginConfiguration];
    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
    [self.session removeInput:self.videoDeviceInput];
    
    if ( [self.session canAddInput:videoDeviceInput] ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
        [ViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
        
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
    } else {
        [self.session addInput:self.videoDeviceInput];
    }
    
    AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ( connection.isVideoStabilizationSupported ) {
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    [self.session commitConfiguration];
}

#pragma mark Configure The Device
+(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

-(void)subjectAreaDidChange:(NSNotification *)notification {
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange  {
    AVCaptureDevice *device = self.videoDeviceInput.device;
    NSError *error = nil;
    if ( [device lockForConfiguration:&error] ) {
        // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
        // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
        if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
            device.focusPointOfInterest = point;
            device.focusMode = focusMode;
        }
        
        if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
        }
        device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
        [device unlockForConfiguration];
    } else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

+(void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        } else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

-(IBAction)focusOnTap:(UITapGestureRecognizer *)sender {
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:[sender locationInView:sender.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    // Note that the app delegate controls the device orientation notifications required to use the device orientation.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

#pragma mark Change FPS With Segmented Control
- (IBAction)fpsChanged:(UISegmentedControl *)sender {
    
    CGFloat desiredFps = 0.0;;
    switch (self.fpsControl.selectedSegmentIndex) {
        case 0:
        default:
        {
            break;
        }
        case 1:
            desiredFps = 120.0;
            break;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        if (desiredFps > 0.0) {
            [self.previewView switchFormatWithDesiredFPS:desiredFps];
        } else {
            [self.previewView resetFormat];
        }
    });
}

@end
