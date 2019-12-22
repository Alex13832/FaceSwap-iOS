//
//  FSMultiViewController.h
//  FaceSwap
//
//  Created by Alexander Karlsson on 2017-01-07.
//  Copyright © 2017 Alexander Karlsson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSImageUtils.h"

@interface FSMultiViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImage *swapImage, *Img;
    BOOL camInputUsed;
}

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (nonatomic, readwrite) FSImageUtils *imUtils;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIImagePickerController *imgPicker;
@property (strong, nonatomic) UIImagePickerController *imgPickerCam;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *swapButton;


- (IBAction)albumButtonPressed:(id)sender;
- (IBAction)swapPressed:(id)sender;
- (IBAction)cameraButtonPressed:(id)sender;


@end
