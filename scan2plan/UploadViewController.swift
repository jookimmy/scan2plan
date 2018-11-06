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
            self.runTextRecognition(with: image)
            uploadView.image = image
        } else {
            print("error")
        }
        self.dismiss(animated: true, completion: nil)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
        let detectedText = text.text
        
        let okAlert = UIAlertAction(title: "OK", style: .default) { (action) in
            // segue to next view controller
        }
        
        let alert = UIAlertController(title: "Detected text", message: detectedText, preferredStyle: .alert)
        alert.addAction(okAlert)
        
        self.present(alert, animated: true) {
            print("alert was presented")
        }
    }

}
