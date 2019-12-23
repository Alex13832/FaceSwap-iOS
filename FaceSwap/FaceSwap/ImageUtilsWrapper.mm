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

@implementation ImageUtilsWrapper

-(id)init
{
    return self;
}

-(UIImage*)swap:(UIImage*)img1 face2:(UIImage*)img2
{
    std::cout << "SWAPPING" << std::endl;
    FSImageUtils *im_utils = [[FSImageUtils alloc] init];
    
    [im_utils setImg1:img1];
    [im_utils setImg2:img2];
    
    return img2;
}


@end
