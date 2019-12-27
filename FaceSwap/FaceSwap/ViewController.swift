//
//  ViewController.swift
//  FaceSwap
//
//  Created by Alexander Karlsson on 2019-12-22.
//  Copyright © 2019 Alexander Karlsson. All rights reserved.
//

// TODO:
// 2 Insert them in image utils together with the images.

import UIKit
import MobileCoreServices
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    var im1: UIImage!
    var im2: UIImage!
    
    var currentImage = 0
    var imTemporary: UIImage!
    var selected_index = 0
    
    var landmarks1:[Int] = []
    var landmarks2:[Int] = []
    
    @IBOutlet weak var swap_button: UIBarButtonItem!
    var sequenceHandler = VNSequenceRequestHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /**
     @brief Listens for tap gesture. When tapped, the camera roll will be opened.
     */
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerController.SourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerController.SourceType.photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /**
     @brief Listens for swap button press. Is enabled if both images are not nil.
     */
    @IBAction func onSwapPressed(_ sender: Any) {
        imTemporary = im1
        currentImage = 1
        detectLandmarks(image: im1)
        
        imTemporary = im2
        currentImage = 2
        detectLandmarks(image: im2)
        
        let imUtils = ImageUtilsWrapper()
        let swapped1 = imUtils.swap(im1, face2: im2, landmarks1: landmarks1, landmarks2: landmarks2)
        let swapped2 = imUtils.swap(im2, face2: im1, landmarks1: landmarks2, landmarks2: landmarks1)
        
        im1 = swapped2
        im2 = swapped1
        
        if selected_index == 0 {
            imageView.image = swapped2
        } else if selected_index == 1 {
            imageView.image = swapped1
        }
    }
    
    /**
     @brief Opens the camera roll and gets the selected image.
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            imageView.image = image
            
            if selected_index == 0 {
                im1 = image
            } else if selected_index == 1 {
                im2 = image
            }
            
            if (im1 != nil) && (im2 != nil) {
                swap_button.isEnabled = true
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     @brief Listens for dismiss of camera roll.
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     @brief Listens for segment (button) change.
     */
    @IBAction func onSegmentChange(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            imageView.image = im1
        } else if sender.selectedSegmentIndex == 1 {
            imageView.image = im2
        }
        selected_index = sender.selectedSegmentIndex
    }
    
    /**
     @brief Detects facial landmarks for an image.
     */
    func detectLandmarks(image: UIImage) -> Void {
        
        var orientation:Int32 = 0
        
        // detect image orientation, we need it to be accurate for the face detection to work
        switch image.imageOrientation {
        case .up:
            orientation = 1
        case .right:
            orientation = 6
        case .down:
            orientation = 3
        case .left:
            orientation = 8
        default:
            orientation = 1
        }
        
        //TODO: Figure out orientation.
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
        
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: CGImagePropertyOrientation(rawValue: UInt32(3))! ,options: [:])

        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error)
        }
    }
    
    /**
     @brief Handles landmarks for a face.
     */
    func handleFaceFeatures(request: VNRequest, errror: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected result type!")
        }
        
        for face in observations {
            addFaceLandmarksToImage(image: imTemporary, face)
            getLandmarksForFace(image: imTemporary, face)
//            addFaceLandmarksToImage(image: imTemporary, face)
        }
    }
    
    /**
     @brief Gets all landmarks for a face.
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
        
        if let landmarks = face.landmarks?.allPoints {
            for i in 0...landmarks.pointCount - 1 {
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
     @brief Draws the landmarks to an input image.
     */
    func addFaceLandmarksToImage(image: UIImage, _ face: VNFaceObservation) {
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        // draw the image
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // draw the face rect
        let w = face.boundingBox.size.width * image.size.width
        let h = face.boundingBox.size.height * image.size.height
        let x = face.boundingBox.origin.x * image.size.width
        let y = face.boundingBox.origin.y * image.size.height
        let faceRect = CGRect(x: x, y: y, width: w, height: h)
        
        context?.saveGState()
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.setLineWidth(8.0)
        context?.addRect(faceRect)
        context?.drawPath(using: .stroke)
        context?.restoreGState()
        
        context?.saveGState()
        context?.setStrokeColor(UIColor.green.cgColor)
        
        // Plot all points
        if let landmarks = face.landmarks?.allPoints {
            for i in 0...landmarks.pointCount - 1 {
                let point = landmarks.normalizedPoints[i]
                
                context?.addEllipse(in: CGRect(
                    origin: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h),
                    size:CGSize(width: 5, height: 5)))
            }
        }
        
        context?.setLineWidth(5.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
        
        // get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end drawing context
        UIGraphicsEndImageContext()
        
        imageView.image = finalImage
    }
}
