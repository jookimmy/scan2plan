//
//  UploadViewController.swift
//  scan2plan
//
//  Created by Shannon Ferguson on 11/1/18.
//  Copyright © 2018 CS196Illinois. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import Photos
import Firebase
import FirebaseMLVision

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var chosenImage: UIImage!
    var visionText: VisionText!
    
    // Mobile Vision stuff
    private lazy var vision = Vision.vision()
    private lazy var textRecognizer = vision.onDeviceTextRecognizer()
    
    let image = UIImagePickerController()

    // MARK: Outlets
    @IBOutlet weak var uploadView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image.delegate = self
        // Do any additional setup after loading the view.
    }
    
    // MARK: Actions
    @IBAction func uploadButton(_ sender: Any) {
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
        {
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            // assumes that image orientation is .right (need to fix later)
            let rotated = image.rotate(radians: .pi/2)
            self.runTextRecognition(with: rotated!)
            self.uploadView.image = image
            self.chosenImage = image
        } else {
            print("error")
        }
        self.dismiss(animated: true, completion: nil)
    }

    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if segue.identifier == "uploadToPreview" {
            let previewVC = segue.destination as! PreviewViewController
            // Pass the selected object to the new view controller.
            previewVC.capturedPhoto = self.chosenImage
            previewVC.visionText = self.visionText
        }
    }
 
    
    func runTextRecognition(with image: UIImage) {
        let visionImage = VisionImage(image: image)
        textRecognizer.process(visionImage) { features, error in
            self.processResult(from: features, error: error)
        }
    }
    
    func processResult(from text: VisionText?, error: Error?) {
        guard error == nil, let text = text else {
            print("oops")
            return
        }
        self.visionText = text
        self.performSegue(withIdentifier: "uploadToPreview", sender: nil)
    }

}
