//
//  FSViewController.h
//  FaceSwap
//
//  Created by Alexander Karlsson on 2017-01-02.
//  Copyright © 2017 Alexander Karlsson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSResultViewController.h"
#import "FSImageUtils.h"

@interface FSViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImage *swapImage, *ImgA, *ImgB, *ImgASw, *ImgBSw;
    BOOL camInputIsUsed;
}

@property (weak, nonatomic) IBOutlet UISegmentedControl *PortraitSwitch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *swapButton;
@property (strong, nonatomic) UIImagePickerController *imgPicker;
@property (strong, nonatomic) UIImagePickerController *imgPickerCam;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (nonatomic, readwrite) FSImageUtils *imUtils;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;


- (IBAction)switchModeChanged:(id)sender;
- (IBAction)albumButtonPressed:(id)sender;
- (IBAction)swapPressed:(id)sender;
- (IBAction)cameraButtonPressed:(id)sender;


@end
