//
//  ViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit
import SQLite3

var itemBeingEdited: Int!
var db: OpaquePointer?
let queryString = "SELECT * FROM Items"
let insertString = "INSERT INTO Items (shortDescription, longDescription) VALUES (?,?)"
var stmt: OpaquePointer?

let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    .appendingPathComponent("Inventory.sqlite")

struct Item {
    var shortDesc : String
    var longDesc : String
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
        self.title = "Inventory"
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(saveToDatabase(_:)),
                                       name: UIApplication.willResignActiveNotification,
                                       object: nil)
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database.")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Items (id INTEGER PRIMARY KEY AUTOINCREMENT, shortDescription VARCHAR, longDescription VARCHAR)", nil, nil, nil) != SQLITE_OK{
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
            
            items.append(Item(shortDesc: shortDescription, longDesc: longDescription))
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
        }
        else if segue.identifier == "editSegue" {
            let view = segue.destination as! EditViewController
            view.delegate = self
            itemBeingEdited = tableView.indexPathForSelectedRow?.row
            view.shortDesc = items[itemBeingEdited].shortDesc
            view.longDesc = items[itemBeingEdited].longDesc
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

