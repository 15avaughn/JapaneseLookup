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

//Item passed to EditViewController
var itemBeingEdited: Int!

//Variables for database interaction
var db: OpaquePointer?
let queryString = "SELECT * FROM Items"
let insertString = "INSERT INTO Items (shortDescription, longDescription, image, imageOrientation, jsonElements) VALUES (?,?,?,?,?)"
var stmt: OpaquePointer?
let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    .appendingPathComponent("Inventory.sqlite")

//Image picker view for choosing a new image from library or camera
var imagePicker = UIImagePickerController()

//Consists of base64 representation of image, its orientation, its title, and its content that has been recognized
struct Item {
    var shortDesc : String
    var longDesc : String
    var image : String
    var imageOrientation : String
    var jsonElements : String
}

//For JSON encoding individual buttons
struct Element: Codable {
    var frame : CGRect
    var text : String
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MyProtocol, MyEditProtocol {

    
    
    @IBOutlet weak var tableView: UITableView!
    //Array of items to be saved in database/displayed in list
    var items: [Item] = []
    //Variable for image that will be taken
    var takenImage: UIImage?
    
    
    //Deals with data sent back from Add and Edit Views
    func setEditResult(valueSent: Item) {
        items[itemBeingEdited] = valueSent
        self.tableView.reloadData()
    }
    func setAddResult(valueSent: Item) {
        items.append(valueSent)
        self.tableView.reloadData()
    }
    
    //Setting up table view
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
    
    //Removing from table view
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            (action:UIContextualAction, sourceView:UIView, actionPerformed:(Bool) -> Void) in
            self.items.remove(at: indexPath.row)
            tableView.reloadData()
            actionPerformed(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    //Loading from database when the view loads
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
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Items (id INTEGER PRIMARY KEY AUTOINCREMENT, shortDescription VARCHAR, longDescription VARCHAR, image VARCHAR, imageOrientation VARCHAR, jsonElements VARCHAR)", nil, nil, nil) != SQLITE_OK{
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
            let jsonElements = String(cString: sqlite3_column_text(stmt,5))
            items.append(Item(shortDesc: shortDescription, longDesc: longDescription, image: img, imageOrientation: imgOrientation,jsonElements: jsonElements))
        }
    }
   
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.identifier.
     // Pass the selected object(s) to the new view controller.
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
            view.elementsJSON = items[itemBeingEdited].jsonElements
        }
     }
    
    //IBAction for + Button to add a new image.
    @IBAction func addNewImage(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {_ in self.openCamera()}))
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {_ in self.openGallery()}))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    //Opens an image picker view to the Camera
    func openCamera(){
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .overCurrentContext
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    //Opens an image picker view to the Gallery
    func openGallery(){
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary)){
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            imagePicker.modalPresentationStyle = .overCurrentContext
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    //Saves objects to database
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
            
            if sqlite3_bind_text(stmt, 5, (item.jsonElements as NSString).utf8String, -1, nil) != SQLITE_OK{
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
    //Changes taken image to have a maximum height or width of 920 because
    //Google can't handle images bigger than that without breaking
    func updateImage(with image: UIImage) ->UIImage{
        var scaledHeight:CGFloat = 920.0
        var scaledWidth:CGFloat = 920.0
        if(image.size.width > scaledWidth || image.size.height > scaledHeight){
            if(image.size.width > image.size.height){
                scaledHeight = scaledWidth/image.size.width * image.size.height
                let scaledImage = image.scaledImage(with: CGSize(width: scaledWidth, height: scaledHeight))
                return scaledImage!
            }
            else if(image.size.width == image.size.height){
                let scaledImage = image.scaledImage(with: CGSize(width: scaledWidth, height: scaledHeight))
                return scaledImage!
            }
            else{
                scaledWidth = scaledHeight/image.size.height * image.size.width
                let scaledImage = image.scaledImage(with: CGSize(width: scaledWidth, height: scaledHeight))
                return scaledImage!
            }
        }
        else{
            return image
        }
    }
}
//Required methods for ImagePickerDelegate
//Takes image from picker, sets it, and prepares a segue. Or just cancels everything.
extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]){
        let image = info[.originalImage] as? UIImage
        self.takenImage = updateImage(with: image!)
        picker.dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "addSegue", sender: Any?.self)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.isNavigationBarHidden = false
        self.dismiss(animated: true, completion: nil)
    }
}
//Extension to String to convert a base64 image string to a UIImage
extension String {
    func toImage() -> UIImage? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data)
        }
        return nil
    }
}
//Extensions to UIImage
extension UIImage {
    //Converts image to base64 string
    func toString() -> String? {
        let data: Data? = self.pngData()
        return data?.base64EncodedString(options: .endLineWithLineFeed)
    }
    
    // The following extension method is by Google
    
    // Creates and returns a new image scaled to the given size. The image preserves its original PNG
    // or JPEG bitmap info.
    //
    // - Parameter size: The size to scale the image to.
    // - Returns: The scaled image or `nil` if image could not be resized.
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
