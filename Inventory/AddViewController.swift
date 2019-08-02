//
//  AddViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit
import Firebase

protocol MyProtocol {
    func setAddResult(valueSent: Item)
}

class AddViewController: UIViewController, UIScrollViewDelegate {
    
    
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var translationImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var recognizeButton: UIButton!
    
    var takenImage: UIImage!
    var delegate:MyProtocol?
    lazy var vision = Vision.vision()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        updateImageView(with: takenImage)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.delegate = self
        recognizeButton.layer.cornerRadius = 5
        scrollView.layer.cornerRadius = 5
        shortDescription.layer.cornerRadius = 5
        longDescription.layer.cornerRadius = 5
        shortDescription.returnKeyType = .done
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return translationImageView
    }
    
    private func updateImageView(with image: UIImage) {
        let orientation = UIApplication.shared.statusBarOrientation
        var scaledImageWidth: CGFloat = 0.0
        var scaledImageHeight: CGFloat = 0.0
        switch orientation {
        case .portrait, .portraitUpsideDown, .unknown:
            scaledImageWidth = translationImageView.bounds.size.width
            scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
        case .landscapeLeft, .landscapeRight:
            scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
            scaledImageHeight = translationImageView.bounds.size.height
        @unknown default:
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
            var scaledImage = image.scaledImage(
                with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
            )
            scaledImage = scaledImage ?? image
            guard let finalImage = scaledImage else { return }
            DispatchQueue.main.async {
                self.translationImageView.image = finalImage
            }
        }
    }
    
    @IBAction func recognizeText(_ sender: Any) {
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
                        button.titleLabel!.adjustsFontSizeToFitWidth = true
                        button.setTitleColor(UIColor.clear, for: .normal)
                        button.addTarget(self, action: #selector(self.lookUpWord), for: .touchUpInside)
                        button.isUserInteractionEnabled = true
                        self.translationImageView.addSubview(button)
                        
                    }
                }
            }
        }
        shortDescription.resignFirstResponder()
        scrollView.maximumZoomScale = 6.0
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
        let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text, image: takenImage.toString()!, imageOrientation: String(takenImage.imageOrientation.rawValue))
        delegate?.setAddResult(valueSent: newItem)
        self.navigationController?.popViewController(animated: true)
        
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

extension UIImage {
    
    /// Creates and returns a new image scaled to the given size. The image preserves its original PNG
    /// or JPEG bitmap info.
    ///
    /// - Parameter size: The size to scale the image to.
    /// - Returns: The scaled image or `nil` if image could not be resized.
    public func scaledImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()?.data.flatMap(UIImage.init)
    }
    
    // MARK: - Private
    
    /// The PNG or JPEG data representation of the image or `nil` if the conversion failed.
    private var data: Data? {
        #if swift(>=4.2)
        return self.pngData() ?? self.jpegData(compressionQuality: Constant.jpegCompressionQuality)
        #else
        return UIImagePNGRepresentation(self) ??
            UIImageJPEGRepresentation(self, Constant.jpegCompressionQuality)
        #endif  // swift(>=4.2)
    }
}

// MARK: - Constants

private enum Constant {
    static let jpegCompressionQuality: CGFloat = 0.8
}
