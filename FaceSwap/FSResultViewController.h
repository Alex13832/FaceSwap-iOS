//
//  FSResultViewController.h
//  FaceSwap
//
//  Created by Alexander Karlsson on 2017-01-02.
//  Copyright © 2017 Alexander Karlsson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSResultViewController : UIViewController
{
@public
    UIImage *swapImage;
    BOOL imSaved;
}

-(void)initialiseWithImage:(UIImage*)imageA;
- (IBAction)saveImageButtonPressed:(id)sender;


@property (weak, nonatomic) IBOutlet UIImageView *ImgResult;
@property (strong) UIImage *swapped;


@end
