//
//  ViewController.swift
//  FaceSwap
//
//  Created by Alexander Karlsson on 2019-12-22.
//  Copyright © 2019 Alexander Karlsson. All rights reserved.
//

import UIKit
import MobileCoreServices
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var swap_button: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var sequenceHandler = VNSequenceRequestHandler()
    var im1: UIImage!
    var im2: UIImage!
    var imTemporary: UIImage!
    var currentImage = 0
    var selected_index = 0
    var landmarks1:[Int] = []
    var landmarks2:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /**
     Listens for tap gesture. When tapped, the camera roll will be opened.
     - parameter sender: UITapGestureRecognizer
     */
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerController.SourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    /**
     Listens for swap button press. Is enabled if both images are not nil.
     - parameter sender: Any
     */
    @IBAction func onSwapPressed(_ sender: Any) {
        imTemporary = im1
        currentImage = 1
        detectLandmarks(image: im1)
        
        imTemporary = im2
        currentImage = 2
        detectLandmarks(image: im2)
        
        if landmarks1.count > 0 && landmarks2.count > 0 {
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
            
            shareButton.isEnabled = true
        }
    }
    
    /**
     Listens for segment (button) change.
     - parameter sender: UISegmentedControl
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
     Opens a menu with possible share actions such as save photo and assign to contact.
     - parameter sender: UIBarButtonItem
     */
    @IBAction func onShareButtonPressed(_ sender: UIBarButtonItem) {
        var im: UIImage!
        
        if selected_index == 0 {
            im = im1
        } else if selected_index == 1 {
            im = im2
        }
        
        if let image = im {
            let vc = UIActivityViewController(activityItems: [image], applicationActivities: [])
            present(vc, animated: true)
        }
    }
    
    /**
     Opens the camera roll and gets the selected image.
     - parameter picker: UIImagePickerController
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        shareButton.isEnabled = false
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
     Listens for dismiss of camera roll.
     - parameter picker: UIImagePickerController
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
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
        /*
        if let landmarks = face.landmarks?.allPoints {
            for i in 0...landmarks.pointCount - 1 {
                let point = landmarks.normalizedPoints[i]
                
                let xx = x + CGFloat(point.x) * w
                let yy = y + CGFloat(point.y) * h
                lmrks.append(Int(xx));
                lmrks.append(Int(yy));
            }
        }
        */
        if currentImage == 1 {
            landmarks1 = lmrks
        } else if currentImage == 2 {
            landmarks2 = lmrks
        }
    }
}
