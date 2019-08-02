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

class AddViewController: UIViewController {
    
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var translationImageView: UIImageView!
    var takenImage: UIImage!
    var delegate:MyProtocol?
    lazy var vision = Vision.vision()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
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
