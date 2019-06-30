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

class AddViewController: UIViewController {
    
    @IBOutlet weak var longDescription: UITextView!
    @IBOutlet weak var shortDescription: UITextField!
    var delegate:MyProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Item"
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        self.navigationItem.rightBarButtonItem = save
    }
    
    @objc func saveItem() {
        let newItem = Item(shortDesc: shortDescription.text ?? "", longDesc: longDescription.text)
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
