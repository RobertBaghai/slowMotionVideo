//
//  VideoViewController.h
//  slowmotionVideo
//
//  Created by Robert Baghai on 12/14/15.
//  Copyright © 2015 Robert Baghai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
- (IBAction)dismissView:(id)sender;

@end
