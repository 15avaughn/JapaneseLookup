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

class EditViewController: UIViewController {

    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var translationImageView: UIImageView!
    
    var delegate:MyEditProtocol?
    var shortDesc: String!
    var longDesc: String!
    var takenImage: UIImage!
    lazy var vision = Vision.vision()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Edit Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        shortDescription.text = shortDesc
        longDescription.text = longDesc
        translationImageView.image = takenImage
    }
    
    @IBAction func recognizeText(_ sender: Any) {
        let visionImage = VisionImage(image: takenImage)
        let textRecognizer = vision.cloudTextRecognizer()
        
        textRecognizer.process(visionImage) { result, error in
            guard error == nil, let result = result else {
                return
            }
            self.longDescription.text += result.text
        }
    }
    
    @objc func saveItem() {
        let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text, image: takenImage.toString()!)
        delegate?.setEditResult(valueSent: newItem)
        self.navigationController?.popViewController(animated: true)
        
    }
    

}
