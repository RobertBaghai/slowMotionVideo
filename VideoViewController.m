//
//  VideoViewController.m
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/14/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

#import "VideoViewController.h"
#import "CollectionViewCell.h"
#import "ViewController.h"
#import "RecordedVideo.h"
#import "VideoPlayerViewController.h"

@interface VideoViewController ()

@property (nonatomic, strong) NSMutableArray *arrayOfThumbnails;
@property (nonatomic, strong) NSMutableArray *arrayOfVideoUrls;
@property (nonatomic, strong) NSURL *videoUrl;

@end

@implementation VideoViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.arrayOfThumbnails = [[NSMutableArray alloc] init];
    self.arrayOfVideoUrls = [[NSMutableArray alloc] init];
    [self retrieveVideoThumbnails];
    [self retrieveVideos];
}

- (void)retrieveVideoThumbnails {
    NSError *error = nil;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"myThumbnails/"];
    [self.arrayOfThumbnails addObjectsFromArray:[fileMgr contentsOfDirectoryAtPath:path error:nil]];
    NSLog(@"Array of Thumbnails count ==== %lu", self.arrayOfThumbnails.count);
    NSLog(@"Documents directory: Files in myThumbnails Folder: %@", [fileMgr contentsOfDirectoryAtPath:path error:&error]);
}

-(void)retrieveVideos {
    NSError *error = nil;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"myVideos/"];
    [self.arrayOfVideoUrls addObjectsFromArray:[fileMgr contentsOfDirectoryAtPath:path error:nil]];
    NSLog(@"Array of Video URLs count ==== %lu", self.arrayOfVideoUrls.count);
    NSLog(@"Documents directory: Files in myVideos Folder: %@", [fileMgr contentsOfDirectoryAtPath:path error:&error]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showRecipeDetail"]) {
        VideoPlayerViewController *destViewController = (VideoPlayerViewController*)segue.destinationViewController;
        destViewController.passedInUrlForVideo = (NSURL*)sender;
    }
}

#pragma mark <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrayOfThumbnails.count;
}

- (CollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"myThumbnails/"];
    NSString *stringFile = [path stringByAppendingPathComponent:[self.arrayOfThumbnails objectAtIndex:indexPath.row]];
    RecordedVideo *recVideo = [[RecordedVideo alloc] init];
    recVideo.videoThumbnail = [UIImage imageWithContentsOfFile:stringFile];
    NSLog(@"%@",recVideo.videoThumbnail);
    cell.thumbnail.image = recVideo.videoThumbnail;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"myVideos/"];
    NSString *stringFile = [path stringByAppendingPathComponent:[self.arrayOfVideoUrls objectAtIndex:indexPath.row]];
    NSLog(@"FILES??? %@",stringFile);
    
    RecordedVideo *recVideo = [[RecordedVideo alloc] init];
    recVideo.videoUrl = [NSURL fileURLWithPath:stringFile];
    NSLog(@"Url to pass %@",recVideo.videoUrl);
    
    [self performSegueWithIdentifier:@"showRecipeDetail" sender:recVideo.videoUrl];
}

- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Collection view layout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"SETTING SIZE FOR ITEM AT INDEX %ld", (long)indexPath.row);
    CGSize mElementSize = CGSizeMake(150, 104);
    return mElementSize;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 2.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout
                              :(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10,30,10,30);  // top, left, bottom, right
}

@end
