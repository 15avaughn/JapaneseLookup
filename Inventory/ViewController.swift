//
//  ViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit
import SQLite3
import Firebase

var itemBeingEdited: Int!
var db: OpaquePointer?
let queryString = "SELECT * FROM Items"
let insertString = "INSERT INTO Items (shortDescription, longDescription, image, imageOrientation) VALUES (?,?,?,?)"
var stmt: OpaquePointer?
var imagePicker = UIImagePickerController()
let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    .appendingPathComponent("Inventory.sqlite")

struct Item {
    var shortDesc : String
    var longDesc : String
    var image : String
    var imageOrientation : String
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MyProtocol, MyEditProtocol {
    
    func setEditResult(valueSent: Item) {
        items[itemBeingEdited] = valueSent
        self.tableView.reloadData()
    }
    
    
    func setAddResult(valueSent: Item) {
        items.append(valueSent)
        self.tableView.reloadData()
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [Item] = []
    var takenImage: UIImage?
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:
            "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].shortDesc
        cell.detailTextLabel?.text = items[indexPath.row].longDesc
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            (action:UIContextualAction, sourceView:UIView, actionPerformed:(Bool) -> Void) in
            self.items.remove(at: indexPath.row)
            tableView.reloadData()
            actionPerformed(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "History"
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(saveToDatabase(_:)),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database.")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Items (id INTEGER PRIMARY KEY AUTOINCREMENT, shortDescription VARCHAR, longDescription VARCHAR, image VARCHAR, imageOrientation VARCHAR)", nil, nil, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error creating table: \(errmsg)")
        }
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error preparing insert: \(errmsg)")
            return
        }
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let shortDescription = String(cString: sqlite3_column_text(stmt, 1))
            let longDescription = String(cString: sqlite3_column_text(stmt, 2))
            let img = String(cString: sqlite3_column_text(stmt,3))
            let imgOrientation = String(cString: sqlite3_column_text(stmt,4))
            items.append(Item(shortDesc: shortDescription, longDesc: longDescription, image: img, imageOrientation: imgOrientation))
        }
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        if segue.identifier == "addSegue" {
            let view = segue.destination as! AddViewController
            view.delegate = self
            view.takenImage = takenImage
        }
        else if segue.identifier == "editSegue" {
            let view = segue.destination as! EditViewController
            view.delegate = self
            itemBeingEdited = tableView.indexPathForSelectedRow?.row
            view.shortDesc = items[itemBeingEdited].shortDesc
            view.longDesc = items[itemBeingEdited].longDesc
            view.takenImage = items[itemBeingEdited].image.toImage()
            view.imageOrientation = Int(items[itemBeingEdited].imageOrientation)
            
        }
     }
    
    
    @IBAction func addNewImage(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {_ in self.openCamera()}))
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {_ in self.openGallery()}))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func openCamera(){
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .overCurrentContext
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallery(){
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)){
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .overCurrentContext
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @objc func saveToDatabase(_ notification:Notification){
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database.")
        }
        
        if sqlite3_exec(db, "DELETE FROM Items", nil, nil, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error deleting table: \(errmsg)")
        }
        
        for item in items{
            if sqlite3_prepare(db, insertString, -1, &stmt, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Error preparing insert: \(errmsg)")
                return
            }
            
            //binding the parameters
            if sqlite3_bind_text(stmt, 1, (item.shortDesc as NSString).utf8String, -1, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("failure binding shortDesc: \(errmsg)")
                return
            }
            
            if sqlite3_bind_text(stmt, 2, (item.longDesc as NSString).utf8String, -1, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("failure binding longDesc: \(errmsg)")
                return
            }
            
            if sqlite3_bind_text(stmt, 3, (item.image as NSString).utf8String, -1, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("failure binding image: \(errmsg)")
                return
            }
            
            if sqlite3_bind_text(stmt, 4, (item.imageOrientation as NSString).utf8String, -1, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("failure binding imageOrientation: \(errmsg)")
                return
            }
            
            //executing the query to insert values
            if sqlite3_step(stmt) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("Failure inserting item: \(errmsg)")
                return
            }
        }
        sqlite3_close(db)
    }
    
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]){
        self.takenImage = info[.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "addSegue", sender: Any?.self)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.isNavigationBarHidden = false
        self.dismiss(animated: true, completion: nil)
    }
}

extension String {
    func toImage() -> UIImage? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data)
        }
        return nil
    }
}

extension UIImage {
    func toString() -> String? {
        let data: Data? = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
}
