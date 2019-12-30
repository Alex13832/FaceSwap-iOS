//
//  FSImageUtils.mm
//  FaceSwap
//
//  Created by Alexander Karlsson on 2016-12-31.
//  Copyright © 2016-2019 Alexander Karlsson. All rights reserved.
//

#import "FSImageUtils.hpp"

#import <vector>
#import <string>

#import "opencv2/photo.hpp"
#import <opencv2/imgcodecs/ios.h>
//#import "opencv2/imgproc.hpp"
//#import "opencv2/imgcodecs.hpp"
//#import "opencv2/highgui.hpp"
//#import "opencv2/core.hpp"

#define SIZE_LIMIT 2000

@implementation FSImageUtils {}

-(id)init {
    if ( self = [super init] ) {}
    return self;
}

#pragma mark Global functions

/**
 @brief Sets image 1.
 @param img [in] Image 1.
 */
-(void)setImg1:(UIImage*) img {
    UIImageToMat(img, mat1);
    cv::flip(mat1, mat1, 1);
    cv::cvtColor(mat1, mat1, cv::COLOR_RGB2BGR);
}

/**
 @brief Sets the secondary image.
 @param img [in] image 2.
 */
-(void)setImg2:(UIImage*) img {
    UIImageToMat(img, mat2);
    cv::flip(mat2, mat2, 1);
    cv::cvtColor(mat2, mat2, cv::COLOR_RGB2BGR);
}

/**
 @brief Sets the landmarks for image 1.
 @param landmarks [in] Facial landmarks for image 1.
 */
- (void)setLandmarks1:(NSArray *)landmarks {
    int x, y;
    for(int i=0; i<[landmarks count]; i+=2) {
        x = [((NSNumber*)[landmarks objectAtIndex:i]) intValue];
        y = [((NSNumber*)[landmarks objectAtIndex:i+1]) intValue];
        cv::Point2f pt(x, y);
        landmarks1.push_back(pt);
    }
}

/**
 @brief Sets the landmarks for image 2.
 @param landmarks [in] Facial landmarks for image 2.
 */
- (void)setLandmarks2:(NSArray *)landmarks {
    int x, y;
    for(int i=0; i<[landmarks count]; i+=2) {
        x = [((NSNumber*)[landmarks objectAtIndex:i]) intValue];
        y = [((NSNumber*)[landmarks objectAtIndex:i+1]) intValue];
        cv::Point2f pt(x, y);
        landmarks2.push_back(pt);
    }
}

/**
 @brief Swaps faces of two selfie images. (Public)
 The face in img1 will be pasted over img2's face.
 @param FSStatus [out] return status
 @return an UIImage with face swap result.
 */
-(UIImage*)swapFaces :(FSSwapStatus_t&)FSStatus {
    FSStatus = FS_STATUS_OK;
    cv::Mat mat = [self faceSwap:mat1 :mat2 :landmarks1 :landmarks2];
    
    cv::cvtColor(mat, mat, cv::COLOR_BGR2RGB);
    cv::flip(mat, mat, 1);
    // Convert back to UIImage
    return MatToUIImage(mat);
}

#pragma mark FaceSwap section

/**
 @brief Swaps faces between img1 and img2.
 @param img1 [in] Image 1, the face from this image will be inserted in img2.
 @param img2 [in] Image 2, face face in image img1 will be inserted here.
 @param points1 [in] Facial landmarks for image 1.
 @param points2 [in] Facial landmarks for image 2.
 @return an OpenCV Mat with the face swap result.
 */
-(cv::Mat)faceSwap:(cv::Mat)img1 :(cv::Mat)img2 :(std::vector<cv::Point2f>)points1 :(std::vector<cv::Point2f>)points2 {
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
    img1Warped.convertTo(img1Warped, CV_8UC3);
    cv::Rect r = cv::boundingRect(hull2);
    cv::Mat img1WarpedSub = img1Warped(r);
    cv::Mat img2Sub = img2(r);
    cv::Mat maskSub = mask(r);
    cv::Point center(r.width/2, r.height/2);
    cv::Mat output;
    
    cv::seamlessClone(img1WarpedSub, img2Sub, maskSub, center, output, cv::NORMAL_CLONE);
    output.copyTo(img2(r));
    
    return img2;
}

/**
 @brief Warps and apha blends triangular regions from img1 and img2 to img
 @param img1 [in] Image 1.
 @param img2 [intout] Image 2.
 @param t1 [in] Triangles that belong to img1.
 @param t2 [in] Triangles that belong to img2.
 */
-(void)warpTriangle:(cv::Mat&)img1 :(cv::Mat&)img2 :(std::vector<cv::Point2f>&)t1 :(std::vector<cv::Point2f>&)t2 {
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
 @brief Apply affine transform calculated using srcTri and dstTri to src.
 @param warpImage [inout] Warps to this image.
 @param src [in] Warps from this image.
 @param srcTri [in] Triangles source.
 @param dstTri [in] Triangles destination.
 */
-(void)applyAffineTransform:(cv::Mat&)warpImage :(cv::Mat&)src :(std::vector<cv::Point2f>&)srcTri :(std::vector<cv::Point2f>&)dstTri {
    // Given a pair of triangles, find the affine transform.
    cv::Mat warpMat = cv::getAffineTransform( srcTri, dstTri );
    // Apply the Affine Transform just found to the src image
    cv::warpAffine( src, warpImage, warpMat, warpImage.size(), cv::INTER_LINEAR, cv::BORDER_REFLECT_101);
}

/**
 @brief Calculates the Delaunay triangulation of a set of points.
 @param rect [in] Rectangle.
 @param points [in] Points.
 @param delaunayTri [inout] Result of the triangulation.
 */
-(void)calculateDelaunayTriangles:(cv::Rect)rect :(std::vector<cv::Point2f>&)points :(std::vector<std::vector<int>>&)delaunayTri {
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
            for (int j = 0; j < 3; j++) {
                for (size_t k = 0; k < points.size(); k++) {
                    if (std::abs(pt[j].x - points[k].x) < 1.0 && std::abs(pt[j].y - points[k].y) < 1) {
                        ind[j] = (int)k;
                    }
                }
            }
            delaunayTri.push_back(ind);
        }
    }
}

@end
