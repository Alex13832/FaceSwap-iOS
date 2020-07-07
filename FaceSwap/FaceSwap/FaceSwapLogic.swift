//
//  FaceSwapLogic.swift
//  FaceSwap
//
//  Created by Alexander Karlsson on 2020-07-06.
//  Copyright © 2020 Alexander Karlsson. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import Vision

class FaceSwapLogic {
    
    let imUtilsWrapper =  ImageUtilsWrapper()
    
    var im1: UIImage!
    var im2: UIImage!
    var imTemporary: UIImage!
    var currentImage = 0
    var landmarks1:[Int] = []
    var landmarks2:[Int] = []
    

    /**
     Returns the first image of the face swap result.
     - Returns: The first image of the resutl.
     */
    func getResultImage1() -> UIImage {
        return self.im1
    }
    
    /**
     Returns the second image of the face swap result.
     - Returns: The second image of the result.
     */
    func getResultImage2() -> UIImage {
        return self.im2
    }
    
    /**
    Swaps the faces in the input images.
     - Parameter im1: First image input.
     - Parameter im2: Second image input.
     - Returns: True if the swapping was ok, False if too few facial landmarks was found.
     */
    func swapFaces(im1: UIImage, im2: UIImage) -> Bool {
        imTemporary = im1
        currentImage = 1
        detectLandmarks(image: im1)
        
        imTemporary = im2
        currentImage = 2
        detectLandmarks(image: im2)
        
        if landmarks1.count < 5 || landmarks2.count < 5 {
            return false;
        }
        
        self.im1 = imUtilsWrapper.swap(im1, face2: im2, landmarks1: landmarks1, landmarks2: landmarks2)
        self.im2 = imUtilsWrapper.swap(im2, face2: im1, landmarks1: landmarks2, landmarks2: landmarks1)
        
        return true;
    }
    
    /**
     Detects facial landmarks for an image.
     - Parameter image: The image to detect landmarks in.
     */
    func detectLandmarks(image: UIImage) -> Void {
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
        
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: CGImagePropertyOrientation(rawValue: UInt32(3))! ,options: [:])
        
        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error)
        }
    }
    
    /**
     Handles landmarks for a face.
     - Parameter request: VNRequest
     - Parameter error: Error
     */
    func handleFaceFeatures(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected result type!")
        }
        
        for face in observations {
            getLandmarksForFace(image: imTemporary, face)
        }
    }
    
    /**
     Extracts tthe facial landmarks for one face observation.
     - Parameter image: The image to get landmarks for.
     - Parameter face: The data structure that contains the landmarks.
     */
    func getLandmarksForFace(image: UIImage, _ face: VNFaceObservation) -> Void {
        var lmrks:[Int] = []
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the image
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        let w = face.boundingBox.size.width * image.size.width
        let h = face.boundingBox.size.height * image.size.height
        let x = face.boundingBox.origin.x * image.size.width
        let y = face.boundingBox.origin.y * image.size.height
        
        // Make left eyebrow coordinates a little higher
        if let landmarks = face.landmarks?.leftEyebrow {
            for i in 0...landmarks.pointCount - 1 {
                let point = landmarks.normalizedPoints[i]
                
                let xx = x + CGFloat(point.x) * w
                let yy = (y + CGFloat(point.y) * h) * 0.85
                lmrks.append(Int(xx));
                lmrks.append(Int(yy));
            }
        }
        
        // Make right eyebrow coordinates a little higher
        if let landmarks = face.landmarks?.rightEyebrow {
            for i in 0...landmarks.pointCount - 1 {
                let point = landmarks.normalizedPoints[i]
                
                let xx = x + CGFloat(point.x) * w
                let yy = (y + CGFloat(point.y) * h) * 0.85
                lmrks.append(Int(xx));
                lmrks.append(Int(yy));
            }
        }
        
        // No need of all coordinates
        if let landmarks = face.landmarks?.faceContour {
            for i in stride(from: 0, to: landmarks.pointCount-1, by: 2) {
                let point = landmarks.normalizedPoints[i]
                
                let xx = x + CGFloat(point.x) * w
                let yy = y + CGFloat(point.y) * h
                lmrks.append(Int(xx));
                lmrks.append(Int(yy));
            }
        }
        
        if currentImage == 1 {
            landmarks1 = lmrks
        } else if currentImage == 2 {
            landmarks2 = lmrks
        }
    }
    
    /**
     Changes the size of the input image.
     - Parameter image: The image to resize.
     - Returns: A resized version of image.
     - link: https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
     */
    func resizeImage(image: UIImage) -> UIImage {
        // Calculate new size
        let size = image.size
        let ratio = size.height / size.width
        let newSize = CGSize(width: 1300, height: 1300*ratio);
        print(newSize)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
