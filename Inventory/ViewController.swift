//
//  ViewController.swift
//  Inventory
//
//  Created by Austin Vaughn on 6/29/19.
//  Copyright © 2019 Austin Vaughn. All rights reserved.
//

import UIKit

var itemBeingEdited: Int!

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
 
    
}

