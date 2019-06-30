//
//  EditViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit

protocol MyEditProtocol {
    func setEditResult(valueSent: Item)
}

class EditViewController: UIViewController {

    @IBOutlet weak var shortDescription: UITextField!
    @IBOutlet weak var longDescription: UITextView!
    
    var delegate:MyEditProtocol?
    var shortDesc: String!
    var longDesc: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Edit Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
        shortDescription.text = shortDesc
        longDescription.text = longDesc
    }
    
    @objc func saveItem() {
        let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text)
        delegate?.setEditResult(valueSent: newItem)
        self.navigationController?.popViewController(animated: true)
        
    }
    

}
