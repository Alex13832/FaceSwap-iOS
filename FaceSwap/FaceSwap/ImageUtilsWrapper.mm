//
//  ImageUtilsWrapper.m
//  FaceSwap
//
//  Created by Alexander Karlsson on 2019-12-23.
//  Copyright © 2019 Alexander Karlsson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageUtilsWrapper.hpp"
#import "FSImageUtils.hpp"
#import <iostream>
#import <CoreGraphics/CoreGraphics.h>
#import <Vision/Vision.h>

@implementation ImageUtilsWrapper

-(id)init
{
    return self;
}

-(UIImage*)swap:(UIImage*)img1 face2:(UIImage*)img2 landmarks1:(NSArray*)lmarks1 landmarks2:(NSArray*)lmarks2
{
    std::cout << "SWAPPING" << std::endl;
    FSImageUtils *im_utils = [[FSImageUtils alloc] init];
    
    // Set images
    [im_utils setImg1:img1];
    [im_utils setImg2:img2];
    // Set landmarks
    [im_utils setLandmarks1:lmarks1];
    [im_utils setLandmarks2:lmarks2];
    
    FSSwapStatus_t status = FS_STATUS_OK;
    UIImage *img = [im_utils swapFaces:status];
    
    return img;
}

@end
