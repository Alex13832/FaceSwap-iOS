//
//  FSResultViewController.m
//  FaceSwap
//
//  Created by Alexander Karlsson on 2017-01-02.
//  Copyright © 2017 Alexander Karlsson. All rights reserved.
//

#import "FSResultViewController.h"

@interface FSResultViewController ()

@end

@implementation FSResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ImgResult.image = self.swapped;
    imSaved = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void)initialiseWithImage:(UIImage*)imageA
{
    self.swapped = imageA;
    self.ImgResult.image = self.swapped;
}

- (IBAction)saveImageButtonPressed:(id)sender {
    
    if (self.swapped != nil) {
        if (!imSaved) {
            UIImageWriteToSavedPhotosAlbum(self.swapped, nil, nil, nil);
    
            [self topText:@"Photo successfully saved" undertext:@"The photo can now be found in the camera roll" buttonText:@"OK"];
            
            imSaved = YES;
        }
    }
    
    
}

-(void)topText:(NSString*)text1 undertext:(NSString*)text2 buttonText:(NSString*)text3 {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:text1 message:text2 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *firstAction = [UIAlertAction actionWithTitle:text3 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        // Insert an action here, if needed.
        
    }];
    
    [alert addAction:firstAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

@end
