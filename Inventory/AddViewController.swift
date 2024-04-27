//
//  AddViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit

protocol MyProtocol {
    func setAddResult(valueSent: Item)
}

class AddViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    //Outlets for storyboard elements
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var translationImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var recognizeButton: UIButton!
    
    //Image received from ViewController
    var takenImage: UIImage!
    //Delegate for passing data
    var delegate:MyProtocol?
    //Vision object from Firebase for recognizing text
    lazy var vision = Vision.vision()
    
    var elements: [Element] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        translationImageView.image = takenImage
        //Zooming
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
        //Round corners
        recognizeButton.layer.cornerRadius = 5
        scrollView.layer.cornerRadius = 5
        shortDescription.layer.cornerRadius = 5
        longDescription.layer.cornerRadius = 5
        //Make keyboard able to dismiss itself
        shortDescription.returnKeyType = .done
        shortDescription.delegate = self
        
        recognizeText(self)
        
    }
    //For keyboard dismissal
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    //For image zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return translationImageView
    }
    //Recognizes text after pressing "Recognize"
    @IBAction func recognizeText(_ sender: Any) {
        //Disable button
        recognizeButton.isEnabled = false
        //Reset zoom
        scrollView.setZoomScale(1.0, animated: true)
        scrollView.maximumZoomScale = 1.0
        //Setup textRecognizer
        let visionImage = VisionImage(image: translationImageView.image!)
        let textRecognizer = vision.cloudTextRecognizer()
        
        //Remove all element buttons
        for view in translationImageView.subviews{
            view.removeFromSuperview()
        }
        
        textRecognizer.process(visionImage) { result, error in
            guard error == nil, let result = result else {
                self.longDescription.text = error?.localizedDescription
                self.recognizeButton.isEnabled = true
                return
            }
            
            //Sets longDescription to have all text that was recognized
            self.longDescription.text = result.text
            //Draws green transparent buttons over elements of text that were recognized
            for block in result.blocks {
                
                // Lines.
                for line in block.lines {
                    
                    // Elements.
                    for element in line.elements {
                        self.elements.append(Element(frame: element.frame, text: element.text))
                        let transformedRect = element.frame.applying(self.transformMatrix())
                        let button = UIButton(frame: transformedRect)
                        button.setTitle(element.text, for: .normal)
                        button.backgroundColor = UIColor.green
                        button.alpha = 0.3
                        button.titleLabel!.adjustsFontSizeToFitWidth = true
                        button.setTitleColor(UIColor.clear, for: .normal)
                        button.addTarget(self, action: #selector(self.lookUpWord), for: .touchUpInside)
                        button.isUserInteractionEnabled = true
                        self.translationImageView.addSubview(button)
                        //Re-enable zoom and button
                        self.recognizeButton.isEnabled = true
                        self.scrollView.maximumZoomScale = 6.0
                    }
                }
            }
        }
        //dismiss keyboard
        shortDescription.resignFirstResponder()
        //allow zooming
        
    }
    
    //Function for buttons to be used to look up a word
    @objc func lookUpWord(sender: UIButton) {
        let dictionaryLookUp = UIReferenceLibraryViewController.init(term: sender.titleLabel?.text ?? "No Definition Found")
        self.present(dictionaryLookUp, animated: true, completion: nil)
    }
    
    //Function for scaling rectangles to size of view (By Google)
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
    
    //Send item back to ViewController if shortDescription is not empty
    @objc func saveItem() {
        if(!(shortDescription.text?.trimmingCharacters(in: .whitespaces).isEmpty)! && shortDescription.text != nil){
            let data = try! JSONEncoder().encode(elements)
            
            let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text, image: takenImage.toString()!, imageOrientation: String(takenImage.imageOrientation.rawValue), jsonElements: String(data: data, encoding: .utf8) ?? "")
            delegate?.setAddResult(valueSent: newItem)
            self.navigationController?.popViewController(animated: true)
        }
        else {
            let alert = UIAlertController(title: "No Title", message: "You need a title for this picture.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
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
