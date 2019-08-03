//
//  EditViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit
import Firebase

protocol MyEditProtocol {
    func setEditResult(valueSent: Item)
}

class EditViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var translationImageView: UIImageView!
    @IBOutlet weak var recognizeButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var delegate:MyEditProtocol?
    var shortDesc: String!
    var longDesc: String!
    var takenImage: UIImage!
    var imageOrientation: Int!
    lazy var vision = Vision.vision()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Edit Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        shortDescription.text = shortDesc
        longDescription.text = longDesc
        let fixedTakenImage = UIImage(cgImage: takenImage.cgImage!, scale: takenImage.scale, orientation: UIImage.Orientation(rawValue: imageOrientation!)!)
        translationImageView.image = fixedTakenImage
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.delegate = self
        recognizeButton.layer.cornerRadius = 5
        scrollView.layer.cornerRadius = 5
        shortDescription.layer.cornerRadius = 5
        longDescription.layer.cornerRadius = 5
        shortDescription.returnKeyType = .done
        shortDescription.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return translationImageView
    }
    
    @IBAction func recognizeText(_ sender: Any) {
        scrollView.setZoomScale(1.0, animated: true)
        let visionImage = VisionImage(image: translationImageView.image!)
        let textRecognizer = vision.cloudTextRecognizer()
        for view in translationImageView.subviews{
            view.removeFromSuperview()
        }
        textRecognizer.process(visionImage) { result, error in
            guard error == nil, let result = result else {
                return
            }
            self.longDescription.text = result.text
            for block in result.blocks {
                
                // Lines.
                for line in block.lines {
                    
                    // Elements.
                    for element in line.elements {
                        let transformedRect = element.frame.applying(self.transformMatrix())
                        
                        let button = UIButton(frame: transformedRect)
                        button.setTitle(element.text, for: .normal)
                        button.backgroundColor = UIColor.green
                        button.alpha = 0.3
                        button.titleLabel!.adjustsFontSizeToFitWidth = false
                        button.setTitleColor(UIColor.clear, for: .normal)
                        button.addTarget(self, action: #selector(self.lookUpWord), for: .touchUpInside)
                        button.isUserInteractionEnabled = true
                        self.translationImageView.addSubview(button)
                    }
                }
            }
        }
        scrollView.maximumZoomScale = 6.0
        shortDescription.resignFirstResponder()
    }
    
    @objc func lookUpWord(sender: UIButton) {
        let dictionaryLookUp = UIReferenceLibraryViewController.init(term: sender.titleLabel?.text ?? "No Definition Found")
        self.present(dictionaryLookUp, animated: true, completion: nil)
    }
    
    private func transformMatrix() -> CGAffineTransform {
        guard let image = translationImageView.image else { return CGAffineTransform() }
        let imageViewWidth = translationImageView.frame.size.width
        let imageViewHeight = translationImageView.frame.size.height
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        let imageViewAspectRatio = imageViewWidth / imageViewHeight
        let imageAspectRatio = imageWidth / imageHeight
        let scale = (imageViewAspectRatio > imageAspectRatio) ?
            imageViewHeight / imageHeight :
            imageViewWidth / imageWidth
        
        // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
        // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
        let scaledImageWidth = imageWidth * scale
        let scaledImageHeight = imageHeight * scale
        let xValue = (imageViewWidth - scaledImageWidth) / CGFloat(2.0)
        let yValue = (imageViewHeight - scaledImageHeight) / CGFloat(2.0)
        
        var transform = CGAffineTransform.identity.translatedBy(x: xValue, y: yValue)
        transform = transform.scaledBy(x: scale, y: scale)
        return transform
    }
    
    
    @objc func saveItem() {
        if(!(shortDescription.text?.trimmingCharacters(in: .whitespaces).isEmpty)! && shortDescription.text != nil){
            let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text, image: takenImage.toString()!, imageOrientation: String(takenImage.imageOrientation.rawValue))
            delegate?.setEditResult(valueSent: newItem)
            self.navigationController?.popViewController(animated: true)
        }
        else {
            let alert = UIAlertController(title: "No Title", message: "You need a title for this picture.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    

}
