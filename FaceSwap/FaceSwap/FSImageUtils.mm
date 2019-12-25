//
//  FSImageUtils.mm
//  FaceSwap
//
//  Created by Alexander Karlsson on 2016-12-31.
//  Copyright © 2016 Alexander Karlsson. All rights reserved.
//


#import "FSImageUtils.hpp"
#include <vector>
#include <string>

#import "opencv2/photo.hpp"
#import "opencv2/imgproc.hpp"
#import "opencv2/imgcodecs.hpp"
#import "opencv2/highgui.hpp"
#import "opencv2/core.hpp"

#define SIZE_LIMIT 20000

@implementation FSImageUtils
{
}

-(id)init {
    if ( self = [super init] ) {}
    return self;
}

#pragma mark Global functions

/**
 Sets the primary image.
 */
-(void)setImg1:(UIImage*) img
{
    mat1 = [self cvMatFromUIImage:img];
}


/**
 Sets the secondary image.
 */
-(void)setImg2:(UIImage*) img
{
    mat2 = [self cvMatFromUIImage:img];
}

/**
 Rotates the primarey image, is to be used when using camera as input.
 */
-(void)rotateImg1
{
    cv::transpose(mat1, mat1);
    cv::flip(mat1, mat1, 1);
    cv::resize(mat1, mat1, cv::Size(mat1.rows, mat1.cols));
}

/**
 Rotates the secondary image, is to be used when using camera as input.
 */
-(void)rotateImg2
{
    cv::transpose(mat2, mat2);
    cv::flip(mat2, mat2, 1);
    cv::resize(mat2, mat2, cv::Size(mat2.rows, mat2.cols));
}


/**
 Swappes faces of two selfie images. (Public)
 The face in img1 will be pasted over img2's face.
 img1: first selfie image.
 img2: second selfie image.
 */
-(UIImage*)swapFaces :(FSSwapStatus_t&)FSStatus
{
    FSStatus = FS_STATUS_OK;
    
    
    // Convert back to UIImage
    UIImage* swUI = [self UIImageFromCVMat:mat1];
    
    return swUI;
}


/**
 Swaps faces for images with >= 2 faces. (Public)
 */
-(UIImage*)swapFacesMulti :(FSSwapStatus_t&)FSStatus
{
    FSStatus = FS_STATUS_OK;
    
    
    UIImage* swUI = [self UIImageFromCVMat:mat1];
    
    return swUI;
}


/**
 Replaces the faces in image 2 with the face in image1.
 */
-(UIImage*)swapFacesOneToMany :(FSSwapStatus_t&)FSStatus
{
    FSStatus = FS_STATUS_OK;
    // Convert UIImages to OpenCV Mat
    // Convert back to UIImage
    UIImage* swUI = [self UIImageFromCVMat:mat1];
    
    return swUI;
}


#pragma mark Facial landmarks section


#pragma mark FaceSwap section


/**
 Main faceSwap function
 */
-(cv::Mat)faceSwap:(cv::Mat)img1 :(cv::Mat)img2 :(std::vector<cv::Point2f>)points1 :(std::vector<cv::Point2f>)points2
{
    cv::Mat img1Warped = img2.clone();
    
    //convert Mat to float data type
    img1.convertTo(img1, CV_32F);
    img1Warped.convertTo(img1Warped, CV_32F);
    
    cv::Mat img11 = img1, img22 = img2;
    img11.convertTo(img11, CV_8UC3);
    img22.convertTo(img22, CV_8UC3);
    
    // Find convex hull
    std::vector<cv::Point2f> hull1;
    std::vector<cv::Point2f> hull2;
    std::vector<int> hullIndex;
    
    cv::convexHull(points2, hullIndex, false, false);
    
    for (size_t i = 0; i < hullIndex.size(); i++) {
        hull1.push_back(points1[hullIndex[i]]);
        hull2.push_back(points2[hullIndex[i]]);
    }
    
    // Find delaunay triangulation for points on the convex hull
    std::vector< std::vector<int> > dt;
    cv::Rect rect(0, 0, img1Warped.cols, img1Warped.rows);
    
    [self calculateDelaunayTriangles:rect :hull2 :dt];
    
    // Apply affine transformation to Delaunay triangles
    for (size_t i = 0; i < dt.size(); i++) {
        std::vector<cv::Point2f> t1, t2;
        // Get points for img1, img2 corresponding to the triangles
        for(size_t j = 0; j < 3; j++) {
            t1.push_back(hull1[dt[i][j]]);
            t2.push_back(hull2[dt[i][j]]);
        }
        
        [self warpTriangle:img1 :img1Warped :t1 :t2];
    }
    
    // Calculate mask
    std::vector<cv::Point> hull8U;
    for (size_t i = 0; i < hull2.size(); i++) {
        cv::Point pt(hull2[i].x, hull2[i].y);
        hull8U.push_back(pt);
    }
    
    cv::Mat mask = cv::Mat::zeros(img2.rows, img2.cols, img2.depth());
    //cv::fillConvexPoly(mask,&hull8U[0], (int)hull8U.size(), cv::Scalar(255,255,255));
    
    // Clone seamlessly.
    cv::Rect r = cv::boundingRect(hull2);
    img1Warped.convertTo(img1Warped, CV_8UC3);
    cv::Mat img1WarpedSub = img1Warped(r);
    cv::Mat img2Sub       = img2(r);
    cv::Mat maskSub       = mask(r);
    
    cv::Point center(r.width/2, r.height/2);
    
    cv::Mat output;
    cv::seamlessClone(img1WarpedSub, img2Sub, maskSub, center, output, cv::NORMAL_CLONE);
    output.copyTo(img2(r));
    
    return img2;
}


/**
 Warps and apha blends triangular regions from img1 and img2 to img
 */
-(void)warpTriangle:(cv::Mat&)img1 :(cv::Mat&)img2 :(std::vector<cv::Point2f>&)t1 :(std::vector<cv::Point2f>&)t2
{
    cv::Rect r1 = cv::boundingRect(t1);
    cv::Rect r2 = cv::boundingRect(t2);
    
    // Offset points by left top corner of the respective rectangles
    std::vector<cv::Point2f> t1Rect, t2Rect;
    std::vector<cv::Point> t2RectInt;
    for (int i = 0; i < 3; i++) {
        t1Rect.push_back( cv::Point2f( t1[i].x - r1.x, t1[i].y -  r1.y) );
        t2Rect.push_back( cv::Point2f( t2[i].x - r2.x, t2[i].y - r2.y) );
        t2RectInt.push_back( cv::Point(t2[i].x - r2.x, t2[i].y - r2.y) ); // for fillConvexPoly
    }
    
    // Get mask by filling triangle
    cv::Mat mask = cv::Mat::zeros(r2.height, r2.width, img1.type());
    //cv::fillConvexPoly(mask, t2RectInt, cv::Scalar(1.0, 1.0, 1.0), 16, 0);
    
    // Apply warpImage to small rectangular patches
    cv::Mat img1Rect;
    img1(r1).copyTo(img1Rect);
    
    cv::Mat img2Rect = cv::Mat::zeros(r2.height, r2.width, img1Rect.type());
    
    [self applyAffineTransform:img2Rect :img1Rect :t1Rect :t2Rect];
    
    cv::multiply(img2Rect,mask, img2Rect);
    cv::multiply(img2(r2), cv::Scalar(1.0,1.0,1.0) - mask, img2(r2));
    img2(r2) = img2(r2) + img2Rect;
}


/**
 Apply affine transform calculated using srcTri and dstTri to src
 */
-(void)applyAffineTransform:(cv::Mat&)warpImage :(cv::Mat&)src :(std::vector<cv::Point2f>&)srcTri :(std::vector<cv::Point2f>&)dstTri
{
    // Given a pair of triangles, find the affine transform.
    cv::Mat warpMat = cv::getAffineTransform( srcTri, dstTri );
    // Apply the Affine Transform just found to the src image
    cv::warpAffine( src, warpImage, warpMat, warpImage.size(), cv::INTER_LINEAR, cv::BORDER_REFLECT_101);
}


/**
 Calculates the Delaunay triangulation of a set of points.
 */
-(void)calculateDelaunayTriangles:(cv::Rect)rect :(std::vector<cv::Point2f>&)points :(std::vector<std::vector<int>>&)delaunayTri
{
    // Create an instance of Subdiv2D
    cv::Subdiv2D subdiv(rect);
    
    // Insert points into subdiv
    for (std::vector<cv::Point2f>::iterator it = points.begin(); it != points.end(); it++)
        subdiv.insert(*it);
    
    std::vector<cv::Vec6f> triangleList;
    subdiv.getTriangleList(triangleList);
    std::vector<cv::Point2f> pt(3);
    std::vector<int> ind(3);
    
    for (size_t i = 0; i < triangleList.size(); i++) {
        cv::Vec6f t = triangleList[i];
        pt[0] = cv::Point2f(t[0], t[1]);
        pt[1] = cv::Point2f(t[2], t[3]);
        pt[2] = cv::Point2f(t[4], t[5 ]);
        
        if (rect.contains(pt[0]) && rect.contains(pt[1]) && rect.contains(pt[2])){
            for (int j = 0; j < 3; j++)
                for (size_t k = 0; k < points.size(); k++)
                    if (std::abs(pt[j].x - points[k].x) < 1.0 && std::abs(pt[j].y - points[k].y) < 1)
                        ind[j] = (int)k;
            
            delaunayTri.push_back(ind);
        }
    }
}


/**
 Debug function for plotting found landmarks
 */
-(void)drawPoints:(cv::Mat&)mat :(std::vector<std::vector<cv::Point2f>>)landmarks
{
    for (size_t i = 0; i < landmarks[0].size(); i++)
        cv::circle(mat, cv::Point((int)landmarks[0][i].x, (int)landmarks[0][i].y), 5, cv::Scalar(0,255,0));
}


# pragma mark Conversion section


/**
 Adjusts the size of input image.
 */
-(cv::Mat)resizeImage:(cv::Mat)img
{
    int limit = 1500;
    if (img.rows < limit || img.cols < limit) // Risky? Could one of them potentially be huge?
        return img;
    
    // Calculate ratio  to keep proportions
    float ratio = (float)img.rows / (float)img.cols;
    
    cv::resize(img, img, cv::Size(limit, limit*ratio));
    
    return img;
}


/**
 Converts UIImage to OpenCV Mat
 http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
 */
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


/**
 Converts UIImage to grayscale OpenCV Mat
 http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
 */
- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


/**
 Converts OpenCV Mat to UIImage
 http://docs.opencv.org/2.4/doc/tutorials/ios/image_manipulation/image_manipulation.html
 */
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
