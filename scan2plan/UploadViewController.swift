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

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let image = UIImagePickerController()

    // MARK: Outlets
    @IBOutlet weak var borderView: UIImageView!
    @IBOutlet weak var uploadView: UIImageView!
    
    // MARK: Actions
    
    @IBOutlet weak var uploadButton: UIButton!
    @IBAction func uploadButton(_ sender: Any) {
        uploadView.image = UIImage(named: "placeholder")
        image.delegate = self
        image.sourceType = UIImagePickerController.SourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
        {
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            uploadView.image = image
        }
        else {
            print("error")
        }
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        image.delegate = self
        let IMAGE_SIZE:CGFloat = 350 // whatever
        let OFFSET:CGFloat = -60
        // Do any additional setup after loading the view.
        uploadView.image = UIImage(named: "placeholder")
        borderView.image = UIImage(named: "whiteborder")
//        let bounds:CGRect = self.view.layer.bounds
//        self.uploadButton.frame = CGRect(x: bounds.width/2 - bounds.width/12, y: (bounds.height * 8.5)/10, width: bounds.width, height: bounds.width)
        uploadView.translatesAutoresizingMaskIntoConstraints = false
        uploadView.widthAnchor.constraint(equalToConstant: IMAGE_SIZE).isActive = true
        uploadView.heightAnchor.constraint(equalToConstant: IMAGE_SIZE).isActive = true
        uploadView.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor).isActive = true
        uploadView.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor, constant: OFFSET).isActive = true
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.widthAnchor.constraint(equalToConstant: IMAGE_SIZE).isActive = true
        borderView.heightAnchor.constraint(equalToConstant: IMAGE_SIZE).isActive = true
        borderView.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor).isActive = true
        borderView.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor, constant: OFFSET).isActive = true
    }
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
