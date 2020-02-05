//
//  ViewController.swift
//  Business Card Reader
//
//  Created by Praveen V on 2/1/20.
//  Copyright © 2020 Praveen V. All rights reserved.
//

import UIKit
import MobileCoreServices
import TesseractOCR
import GPUImage

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var companyField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    
    var recognizedText:String = ""
    
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // IBAction methods
  @IBAction func backgroundTapped(_ sender: Any) {
    view.endEditing(true)
  }
  
  @IBAction func takePhoto(_ sender: Any) {
    let imagePickerActionSheet =
      UIAlertController(title: "Snap/Upload Image",
                        message: nil,
                        preferredStyle: .actionSheet)
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let cameraButton = UIAlertAction(
        title: "Take Photo",
        style: .default) { (alert) -> Void in
          self.activityIndicator.startAnimating()
          let imagePicker = UIImagePickerController()
          imagePicker.delegate = self
          imagePicker.sourceType = .camera
          imagePicker.mediaTypes = [kUTTypeImage as String]
          self.present(imagePicker, animated: true, completion: {
            self.activityIndicator.stopAnimating()
          })
      }
      imagePickerActionSheet.addAction(cameraButton)
    }
    
    let libraryButton = UIAlertAction(
      title: "Choose Existing",
      style: .default) { (alert) -> Void in
        self.activityIndicator.startAnimating()
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(imagePicker, animated: true, completion: {
          self.activityIndicator.stopAnimating()
        })
    }
    imagePickerActionSheet.addAction(libraryButton)
    
    let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
    imagePickerActionSheet.addAction(cancelButton)
    
    present(imagePickerActionSheet, animated: true)
  }

  // Tesseract Image Recognition
  func performImageRecognition(_ image: UIImage) {
    let scaledImage = image.scaledImage(1000) ?? image
    let preprocessedImage = scaledImage.preprocessedImage() ?? scaledImage
    
    if let tesseract = G8Tesseract(language: "eng+fra") {
      tesseract.engineMode = .tesseractCubeCombined
      tesseract.pageSegmentationMode = .auto
      
      tesseract.image = preprocessedImage
      tesseract.recognize()
        if tesseract.recognizedText != nil{
            recognizedText = tesseract.recognizedText!
    
            while recognizedText.prefix(1) == " " || recognizedText.suffix(1) == " " {
                recognizedText = recognizedText.trimmingCharacters(in: NSCharacterSet.whitespaces)
                let lines = recognizedText.split { $0.isNewline }
                recognizedText = lines.joined(separator: "\n")
            }
            
        }
      textView.text = recognizedText
        recognizedText = recognizedText.replacingOccurrences(of: "\n", with: " ")
    }
    putValues()
    activityIndicator.stopAnimating()
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController,
       didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let selectedPhoto =
      info[.originalImage] as? UIImage else {
        dismiss(animated: true)
        return
    }
    activityIndicator.startAnimating()
    dismiss(animated: true) {
      self.performImageRecognition(selectedPhoto)
    }
  }
    
    
    func putValues() {
        let phoneNumber = getPhoneNumber()[0]
        phoneField.text = phoneNumber
        recognizedText = recognizedText.replacingOccurrences(of: phoneNumber, with: "")
        
        let email = getEmail()
        emailField.text = getEmail()
        recognizedText = recognizedText.replacingOccurrences(of: email, with: "")
        
        let name = getName()
        nameField.text = recognizedText
        recognizedText = recognizedText.replacingOccurrences(of: name, with: "")
        
        companyField.text = recognizedText
        
        addressField.text = recognizedText
    }
     
    func getName() -> String {
        let arr = recognizedText.components(separatedBy: [" ", "\t"])
        var name = String(arr[0])
        if arr[1].contains(".") {
            name += " " + arr[1] + " " + arr[2]
        }
        return name
    }
    
    func getPhoneNumber() -> [String] {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let matches = detector.matches(in: recognizedText, options: [], range: NSRange(location: 0, length: recognizedText.count))
        var resultsArray = [String]()
        for match in matches {
            if match.resultType == .phoneNumber,
                let component = match.phoneNumber {
                resultsArray.append(component)
            }
        }
        resultsArray.append("")
        return resultsArray
    }
    
    func getEmail() -> String{
        var email = ""
        let arr = recognizedText.split(separator: " ")
        for string in arr {
            if string.contains("com") {
                if email != "" {
                    if string.contains("@") {
                        email = String(string)
                        break
                    }
                } else {
                    email = String(string)
                }
            }
        }
        return email
    }
    
}

// MARK: - UIImage extension
extension UIImage {
  func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)

    if size.width > size.height {
      scaledSize.height = size.height / size.width * scaledSize.width
    } else {
      scaledSize.width = size.width / size.height * scaledSize.height
    }

    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
  }
  
  func preprocessedImage() -> UIImage? {
    let stillImageFilter = GPUImageAdaptiveThresholdFilter()
    stillImageFilter.blurRadiusInPixels = 15.0
    let filteredImage = stillImageFilter.image(byFilteringImage: self)
    return filteredImage
  }
    
}


