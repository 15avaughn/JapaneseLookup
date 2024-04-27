//
//  AddViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit
import Vision

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
    
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var text = [String]()
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            let correctedBox = boundingBox.applying(CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1))
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            let box = VNImageRectForNormalizedRect(correctedBox,
                                                Int(translationImageView.image!.size.width),
                                                Int(translationImageView.image!.size.height))
        
            
            
            self.elements.append(Element(frame: box, text: candidate.string))
            text.append(visionResult.topCandidates(maximumCandidates).first!.string)
            
        }
        
        //Draws green transparent buttons over elements of text that were recognized
        for element in elements {
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
            
        }
        
        self.longDescription.text = text.joined(separator: " ")
        self.recognizeButton.isEnabled = true
        self.scrollView.maximumZoomScale = 6.0

    }
    
    
    //Recognizes text after pressing "Recognize"
    @IBAction func recognizeText(_ sender: Any) {
        //Disable button
        recognizeButton.isEnabled = false
        //Reset zoom
        scrollView.setZoomScale(1.0, animated: true)
        scrollView.maximumZoomScale = 1.0
        //Setup textRecognizer
        let visionImage = VNImageRequestHandler(cgImage: translationImageView.image!.cgImage!)
        let textRecognizer = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        textRecognizer.automaticallyDetectsLanguage = true
        textRecognizer.usesLanguageCorrection = true
        
        //Remove all element buttons
        for view in translationImageView.subviews{
            view.removeFromSuperview()
        }
        
        do {
            // Perform the text-recognition request.
            try visionImage.perform([textRecognizer])
        } catch {
            print("Unable to perform the requests: \(error).")
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
