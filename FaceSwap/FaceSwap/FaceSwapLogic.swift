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
    
    var maxSize: Int
    var im1: UIImage!
    var im1Backup: UIImage!
    var im2: UIImage!
    var im2Backup: UIImage!
    var imTemporary: UIImage!
    var currentImage = 0
    var selectedIndex = 0
    var landmarks1:[Int] = []
    var landmarks2:[Int] = []
    
    
    init(maxSizeIm: Int) {
        maxSize = maxSizeIm;
        im1 = nil
        im2 = nil
        im1Backup = nil
        im2Backup = nil
    }
    
    func getIm1() -> UIImage {
        return im1
    }
    
    func getIm2() -> UIImage {
        return im2
    }
    
    func setIm1(img1: UIImage) -> Void {
        im1 = img1
    }
    
    func setIm2(img2: UIImage) -> Void {
        im2 = img2
    }
    
    func swapFaces() -> UIImage {
        return im1
    }
    
    /**
     Detects facial landmarks for an image.
     - parameter image: The image to detect landmarks in.
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
     - parameter request: VNRequest
     - parameter error: Error
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
     - parameter image: The image to get landmarks for.
     - parameter face: The data structure that contains the landmarks.
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
     - parameter image: The image to resize.
     - returns: A resized version of image.
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
