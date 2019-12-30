//
//  FSImageUtils.h
//  FaceSwap
//
//  Created by Alexander Karlsson on 2016-12-31.
//  Copyright © 2016-2019 Alexander Karlsson. All rights reserved.
//

#ifndef FSImageUtils_hpp
#define FSImageUtils_hpp

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

#import "opencv2/core.hpp"

@interface FSImageUtils : NSObject
{
    cv::Mat mat1, mat2;
    std::vector<cv::Point2f> landmarks1, landmarks2;
}

typedef enum FSSwapStatus_t
{
    FS_STATUS_OK,
    FS_STATUS_NO_FACE_FOUND,
    FS_STATUS_SINGLE_FACE_ERROR,
    FS_STATUS_IMAGE_TOO_SMALL
} FSSwapStatus_t;

-(UIImage*)swapFaces :(FSSwapStatus_t&)FSStatus;
-(void)setImg1:(UIImage*) img;
-(void)setImg2:(UIImage*) img;
-(void)setLandmarks1:(NSArray*) landmarks;
-(void)setLandmarks2:(NSArray*) landmarks;

@end

#endif /* FSImageUtils_hpp */
