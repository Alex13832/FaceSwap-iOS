//
//  FSImageUtils.h
//  FaceSwap
//
//  Created by Alexander Karlsson on 2016-12-31.
//  Copyright © 2016-2020 Alexander Karlsson. All rights reserved.
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

enum class SwapStatus{
    OK,
    NOK
};

/**
 @brief Swaps faces of two selfie images. (Public)
 The face in img1 will be pasted over img2's face.
 @param FSStatus [out] return status
 @return an UIImage with face swap result.
 */
-(UIImage*)swapFaces :(SwapStatus&)FSStatus;


/**
 @brief Sets image 1.
 @param img [in] Image 1.
 */
-(void)setImg1:(UIImage*) img;

/**
 @brief Sets the secondary image.
 @param img [in] image 2.
 */
-(void)setImg2:(UIImage*) img;

/**
 @brief Sets the landmarks for image 1.
 @param landmarks [in] Facial landmarks for image 1.
 */
-(void)setLandmarks1:(NSArray*) landmarks;

/**
 @brief Sets the landmarks for image 2.
 @param landmarks [in] Facial landmarks for image 2.
 */
-(void)setLandmarks2:(NSArray*) landmarks;

@end

#endif /* FSImageUtils_hpp */
