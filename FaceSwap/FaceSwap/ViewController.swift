//
//  ViewController.swift
//  FaceSwap
//
//  Created by Alexander Karlsson on 2019-12-22.
//  Copyright © 2019 Alexander Karlsson. All rights reserved.
//

// TODO:
// 1 Get landmarks and put them in two arrays.
// 2 Insert them in image utils together with the images.

import UIKit
import MobileCoreServices
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    var im1: UIImage!
    var im2: UIImage!
    var selected_index = 0
    @IBOutlet weak var swap_button: UIBarButtonItem!
    var sequenceHandler = VNSequenceRequestHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    /**
     Listens for tap gesture. When tapped, the camera roll will be opened.
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
     Listens for swap button press. Is enabled if both images are not nil.
     */
    @IBAction func onSwapPressed(_ sender: Any) {
//        detectLandmarks(image:
        let im_utils = ImageUtilsWrapper()
        let lmarks1: NSMutableArray = [0];
        let lmarks2: NSMutableArray = [0];
        let im3 = im_utils.swap(im1, face2: im2, landmarks1: lmarks1, landmarks2: lmarks2);

//        let im3 = detectFaces(image: im1)
//        let im4 = detectFaces(image: im2)
//
//        if selected_index == 0 {
//            imageView.image = im3
//        } else if selected_index == 1 {
//            imageView.image = im4
//        }
//
//        im1 = im3
//        im2 = im4
    }
    
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
        
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceFeatures)
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: CGImagePropertyOrientation(rawValue: CGImagePropertyOrientation.RawValue(orientation))!, options: [:])
        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error)
        }
        
    }
    
    func handleFaceFeatures(request: VNRequest, errror: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected result type!")
        }

        for face in observations {
            addFaceLandmarksToImage(face)
        }
    }
    
    
    func detectFaces(image: UIImage) -> UIImage {
        let ciImage1 = CIImage(cgImage: image.cgImage!)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
        let faces = faceDetector.features(in: ciImage1)
        var im = image
        
        if let face = faces.first as? CIFaceFeature {
            im = drawRectangleOnImage(image: im, rect: face.bounds)
        }
        
        return im
    }
    
    
    /**
     Draws a rectangle over an UIImage. Returns a new image.
     */
    func drawRectangleOnImage(image: UIImage, rect: CGRect) -> UIImage {
        let image_size = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(image_size, false, scale)
        
        let origin = CGPoint(x: rect.origin.x, y: image.size.height - rect.size.height - rect.origin.y)
        let rect2 = CGRect(origin: origin, size: rect.size)
        
        image.draw(at: CGPoint.zero)
        UIColor.green.setStroke()
        UIRectFrame(rect2)
        
        let image_with_box = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image_with_box!
    }
    
    
    /**
     Opens the camera roll and gets the selected image.
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
     Listens for dismiss of camera roll.
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Listens for segment (button) change.
     */
    @IBAction func onSegmentChange(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            imageView.image = im1
        } else if sender.selectedSegmentIndex == 1 {
            imageView.image = im2
        }
        selected_index = sender.selectedSegmentIndex
    }
    
    
    func addFaceLandmarksToImage(_ face: VNFaceObservation) {
        var image = im1!
        
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
     
        // face contour
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.faceContour {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // outer lips
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.outerLips {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // inner lips
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.innerLips {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // left eye
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.leftEye {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // right eye
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.rightEye {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // left pupil
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.leftPupil {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // right pupil
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.rightPupil {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // left eyebrow
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.leftEyebrow {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // right eyebrow
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.rightEyebrow {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // nose
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.nose {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.closePath()
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // nose crest
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.noseCrest {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // median line
        context?.saveGState()
        context?.setStrokeColor(UIColor.yellow.cgColor)
        if let landmark = face.landmarks?.medianLine {
            for i in 0...landmark.pointCount - 1 { // last point is 0,0
                let point = landmark.normalizedPoints[i]
                if i == 0 {
                    context?.move(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                } else {
                    context?.addLine(to: CGPoint(x: x + CGFloat(point.x) * w, y: y + CGFloat(point.y) * h))
                }
            }
        }
        context?.setLineWidth(8.0)
        context?.drawPath(using: .stroke)
        context?.saveGState()
     
        // get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
     
        // end drawing context
        UIGraphicsEndImageContext()
     
        imageView.image = finalImage
    }
}
