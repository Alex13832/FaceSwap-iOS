//
//  ViewController.swift
//  FaceSwap
//
//  Created by Alexander Karlsson on 2019-12-22.
//  Copyright © 2020 Alexander Karlsson. All rights reserved.
//

import UIKit
import MobileCoreServices
import Vision

class FaceSwapView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var swapButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var regretButton: UIButton!
            
    let imUtilsWrapper =  ImageUtilsWrapper()
    let faceSwapLogic = FaceSwapLogic()
    let maxSize = 1300
    
    var sequenceHandler = VNSequenceRequestHandler()
    var im1: UIImage!
    var im1Backup: UIImage!
    var im2: UIImage!
    var im2Backup: UIImage!
    var imTemporary: UIImage!
    var currentImage = 0
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     Listens for tap gesture. When tapped, the camera roll will be opened.
     - Parameter sender: UITapGestureRecognizer
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
     - Parameter sender: Any
     */
    @IBAction func onSwapPressed(_ sender: Any) {
        
        if faceSwapLogic.swapFaces(im1: im1, im2: im2) {
            
            im1 = faceSwapLogic.getResultImage2()
            im2 = faceSwapLogic.getResultImage1()
            
            if selectedIndex == 0 {
                imageView.image = im1
            } else if selectedIndex == 1 {
                imageView.image = im2
            }
            
            shareButton.isEnabled = true
            regretButton.isHidden = false
            regretButton.isEnabled = true
        }
    }
    
    /**
     Listens for segment (button) change.
     - Parameter sender: UISegmentedControl
     */
    @IBAction func onSegmentChange(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            imageView.image = im1
        } else if sender.selectedSegmentIndex == 1 {
            imageView.image = im2
        }
        selectedIndex = sender.selectedSegmentIndex
    }
    
    /**
     Opens a menu with possible share actions such as save photo and assign to contact.
     - Parameter sender: UIBarButtonItem
     */
    @IBAction func onShareButtonPressed(_ sender: UIBarButtonItem) {
        var im: UIImage!
        
        if selectedIndex == 0 {
            im = im1
        } else if selectedIndex == 1 {
            im = im2
        }
        
        if let image = im {
            let vc = UIActivityViewController(activityItems: [image], applicationActivities: [])
            present(vc, animated: true)
        }
    }
    
    /**
     Replaces the result images with the original input.
     - Parameter sender: UIButton
     */
    @IBAction func onRegretPressed(_ sender: UIButton) {
        im1 = im1Backup
        im2 = im2Backup
        
        if selectedIndex == 0 {
            imageView.image = im1
        } else if selectedIndex == 1 {
            imageView.image = im2
        }
        
        regretButton.isHidden = true
        regretButton.isEnabled = false
    }
    
    
    /**
     Opens the camera roll and gets the selected image.
     - Parameter picker: UIImagePickerController
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        shareButton.isEnabled = false
        regretButton.isHidden = true
        regretButton.isEnabled = false
        
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            var image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            imageView.image = image
            
            // Resize image if it's to big
            if Int(image.size.height) > maxSize || Int(image.size.width) > maxSize {
                image = faceSwapLogic.resizeImage(image: image)
            }
            
            if selectedIndex == 0 {
                im1 = image
                im1Backup = image
            } else if selectedIndex == 1 {
                im2 = image
                im2Backup = image
            }
            
            if (im1 != nil) && (im2 != nil) {
                swapButton.isEnabled = true
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Listens for dismiss of camera roll.
     - Parameter picker: UIImagePickerController
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
