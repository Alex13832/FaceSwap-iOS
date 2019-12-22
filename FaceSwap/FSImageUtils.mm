//
//  FSImageUtils.mm
//  FaceSwap
//
//  Created by Alexander Karlsson on 2016-12-31.
//  Copyright © 2016 Alexander Karlsson. All rights reserved.
//


#import "FSImageUtils.h"
#include <vector>
#include <string>

#include <dlib/image_processing/frontal_face_detector.h>

#import "opencv2/photo.hpp"
#import "opencv2/imgproc.hpp"
#import "opencv2/imgcodecs.hpp"
#import "opencv2/highgui.hpp"
#import "opencv2/core.hpp"

#define SIZE_LIMIT 20000

@implementation FSImageUtils
{
    dlib::shape_predictor sp;
}

-(id)init {
    if ( self = [super init] ) {
        // Predictor for facial landmark positions
        NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
        const char* modelFileNameCString = [modelFileName UTF8String];
        
        // Load predictor with trained model
        dlib::deserialize(modelFileNameCString) >> sp;
    }
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
    
    // Check size
    if (mat1.rows * mat1.cols < SIZE_LIMIT) FSStatus = FS_STATUS_IMAGE_TOO_SMALL;
    if (mat2.rows * mat2.cols < SIZE_LIMIT) FSStatus = FS_STATUS_IMAGE_TOO_SMALL;
    if (FSStatus == FS_STATUS_IMAGE_TOO_SMALL)
        return [self UIImageFromCVMat:mat1];
    
    // Use correct color space
    cv::cvtColor(mat1, mat1, cv::COLOR_BGR2RGB);
    cv::cvtColor(mat2, mat2, cv::COLOR_BGR2RGB);
    
    // Adjust image size
    mat1 = [self resizeImage:mat1];
    mat2 = [self resizeImage:mat2];
    
    // Convert to dlib images
    dlib::cv_image<dlib::bgr_pixel> img1Dlib = [self CVMat2DlibImage:mat1];
    dlib::cv_image<dlib::bgr_pixel> img2Dlib = [self CVMat2DlibImage:mat2];
    
    // Get facial landmarks
    std::cout << "landmarks start" << std::endl;
    std::vector<std::vector<cv::Point2f>> lm1 = [self DLibFacialLandmarks:img1Dlib];
    if (lm1.size() == 0) FSStatus = FS_STATUS_NO_FACE_FOUND;
    std::vector<std::vector<cv::Point2f>> lm2 = [self DLibFacialLandmarks:img2Dlib];
    if (lm2.size() == 0) FSStatus = FS_STATUS_NO_FACE_FOUND;
    std::cout << "landmarks end" << std::endl;
    
    if (FSStatus == FS_STATUS_NO_FACE_FOUND)
        return [self UIImageFromCVMat:mat1];
    
    // Swap faces!
    std::cout << "face swap begin" << std::endl;
    cv::Mat swImg = [self faceSwap:mat1 :mat2 :lm1[0] :lm2[0]];
    std::cout << "face swap end" << std::endl;
    
    // Convert back to UIImage
    UIImage* swUI = [self UIImageFromCVMat:swImg];

    return swUI;
}


/** 
 Swaps faces for images with >= 2 faces. (Public)
 */
-(UIImage*)swapFacesMulti :(FSSwapStatus_t&)FSStatus
{
    FSStatus = FS_STATUS_OK;
    
    // Use correct color space
    cv::cvtColor(mat1, mat1, cv::COLOR_BGR2RGB);
    
    // Check size
    if (mat1.rows * mat1.cols < SIZE_LIMIT) FSStatus = FS_STATUS_IMAGE_TOO_SMALL;
    if (FSStatus == FS_STATUS_IMAGE_TOO_SMALL) return [self UIImageFromCVMat:mat1];
    
    // Adjust image size if needed
    mat1 = [self resizeImage:mat1];
    
    // Convert image to dlib compatible image
    dlib::cv_image<dlib::bgr_pixel> imgDlib = [self CVMat2DlibImage:mat1];
    
    // Get facial landmarks of input image
    std::cout << "landmarks start" << std::endl;
    std::vector<std::vector<cv::Point2f>> lm = [self DLibFacialLandmarks:imgDlib];
    std::cout << "landmarks end " << std::endl;
    std::cout << "faces found " <<  lm.size() << std::endl;
    
    if (lm.size() == 0) FSStatus = FS_STATUS_NO_FACE_FOUND;
    if (lm.size() == 1) FSStatus = FS_STATUS_SINGLE_FACE_ERROR;
    
    if (lm.size() <= 1) return [self UIImageFromCVMat:mat1];
    
    
    // Swap faces
    // Make a copy of input
    cv::Mat swImg = mat1.clone();

    // Loop all faces
    for (size_t i = 0; i < lm.size()-1; i++)
        swImg = [self faceSwap:mat1.clone() :swImg :lm[i+1] :lm[i]];

    swImg = [self faceSwap:mat1.clone() :swImg :lm[0] :lm.back()];

    
    UIImage* swUI = [self UIImageFromCVMat:swImg];

    return swUI;
}


/** 
 Replaces the faces in image 2 with the face in image1.
 */
-(UIImage*)swapFacesOneToMany :(FSSwapStatus_t&)FSStatus
{
    FSStatus = FS_STATUS_OK;
    // Convert UIImages to OpenCV Mat
    //cv::Mat img1Mat = [self cvMatFromUIImage:img1];
    //cv::Mat img2Mat = [self cvMatFromUIImage:img2];
    
    //std::cout << img1Mat.size() << std::endl;
    
    // Is to be used with camera image
    // TODO: add something that indicates if it is a camera image
    //cv::transpose(img1Mat, img1Mat);
    
    // Check size
    if (mat1.rows * mat1.cols < SIZE_LIMIT) FSStatus = FS_STATUS_IMAGE_TOO_SMALL;
    if (mat2.rows * mat2.cols < SIZE_LIMIT) FSStatus = FS_STATUS_IMAGE_TOO_SMALL;
    if (FSStatus == FS_STATUS_IMAGE_TOO_SMALL) return [self UIImageFromCVMat:mat1];
    
    // Use correct color space
    cv::cvtColor(mat1, mat1, cv::COLOR_BGR2RGB);
    cv::cvtColor(mat2, mat2, cv::COLOR_BGR2RGB);
    
    // Adjust image size
    mat1 = [self resizeImage:mat1];
    mat2 = [self resizeImage:mat2];
    
    // Convert to dlib images
    dlib::cv_image<dlib::bgr_pixel> img1Dlib = [self CVMat2DlibImage:mat1];
    dlib::cv_image<dlib::bgr_pixel> img2Dlib = [self CVMat2DlibImage:mat2];
    
    // Get facial landmarks
    std::vector<std::vector<cv::Point2f>> lm1 = [self DLibFacialLandmarks:img1Dlib];
    if (lm1.size() == 0) FSStatus = FS_STATUS_NO_FACE_FOUND;
    std::vector<std::vector<cv::Point2f>> lm2 = [self DLibFacialLandmarks:img2Dlib];
    if (lm2.size() == 0) FSStatus = FS_STATUS_NO_FACE_FOUND;
    
    if (FSStatus == FS_STATUS_NO_FACE_FOUND) return [self UIImageFromCVMat:mat1];
    
    // Swap faces!
    cv::Mat img2Cl = mat2.clone();
    // Replace all faces in image 2 with the face in image 1.
    for (size_t i = 0; i < lm2.size(); i++)
        img2Cl = [self faceSwap:mat1 :img2Cl :lm1[0] :lm2[i]];
        
    // Convert back to UIImage
    UIImage* swUI = [self UIImageFromCVMat:img2Cl];
    
    return swUI;
}


#pragma mark Facial landmarks section


/** 
 Returns 68 facial landmarks of the input image.
 */
-(std::vector<std::vector<cv::Point2f>>)DLibFacialLandmarks:(dlib::cv_image<dlib::bgr_pixel>)img
{
    dlib::frontal_face_detector detector = dlib::get_frontal_face_detector();

    // Get a list of bounding boxes for found faces
    std::vector<dlib::rectangle> dets = detector(img);
    std::vector<std::vector<cv::Point2f>> landmarks;
    
    // Can be used for multiple face detection
    for (unsigned long j = 0; j < dets.size(); ++j) {
        dlib::full_object_detection shape = sp(img, dets[j]);

        // Store temporary x and y coordinates here, will be used for the swapping stage.
        std::vector<cv::Point2f> lm;
        for (size_t i = 0; i < shape.num_parts(); i++) {
            lm.push_back(cv::Point2f((float)shape.part(i).x(), (float)shape.part(i).y()));
        }
        std::cout << j << std::endl;
        landmarks.push_back(lm);
    }
    
    return landmarks;
}


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
    cv::fillConvexPoly(mask,&hull8U[0], (int)hull8U.size(), cv::Scalar(255,255,255));
    
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
    cv::fillConvexPoly(mask, t2RectInt, cv::Scalar(1.0, 1.0, 1.0), 16, 0);
    
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


/**
 Converts OpenCV Mat to Dlib image object
 http://stackoverflow.com/questions/37516675/opencv-dlib-mat-object-outputed-as-black-image
 http://dlib.net/webcam_face_pose_ex.cpp.html
 */
-(dlib::cv_image<dlib::bgr_pixel>)CVMat2DlibImage:(cv::Mat)cvMat
{
    cv::cvtColor(cvMat, cvMat, CV_RGBA2BGR);
    
    dlib::cv_image<dlib::bgr_pixel> dimg(cvMat);
    
    
    return dimg;
}

@end
