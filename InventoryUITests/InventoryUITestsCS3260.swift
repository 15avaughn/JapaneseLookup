//
//  InventoryUITestsCS3260.swift
//  InventoryUITests
//
//  Created by Ted Cowan on 10/13/18.
//  Copyright © 2018 Ted Cowan. All rights reserved.
//

import XCTest

class InventoryUITestsCS3260: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testVerifyLabelsAndTable() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(app.navigationBars["Inventory"].exists, "Screen not titled \"Inventory\"")
        XCTAssert(app.navigationBars["Inventory"].buttons["Add"].exists, "Add button not found")
        XCTAssert(app.tables.element(boundBy: 0).exists, "No table found on opening screen")

    }
    
    func testAddItems() {
        
        let sampleItems = [("Item one", "This is item one"),
                           ("Item two", "This is item two"),
                           ("Item three", "This is item three"),
        ]
        let tableView = app.tables.element(boundBy: 0)

        for i in 0..<sampleItems.count {
            app.navigationBars["Inventory"].buttons["Add"].tap()
            XCTAssert(app.navigationBars["Add New Item"].exists, "Screen not titled \"Add New Item\"")
            XCTAssert(app.navigationBars["Add New Item"].buttons["Inventory"].exists, "Inventory back button not found in Add New Item")
            XCTAssert(app.navigationBars["Add New Item"].buttons["Save"].exists, "Save button not found in Add New Item")
            XCTAssert(app.textFields["addShortDescription"].exists, "No textField found with identifier addShortDescription in Add New Item")
            XCTAssert(app.textViews["addLongDescription"].exists, "No textView found with identifier addLongDescription in Add New Item")
            
            XCTAssert(app.textFields["addShortDescription"].title == "", "addShortDescription is not empty on entry to Add New Item")
            XCTAssert(app.textViews["addLongDescription"].title == "", "addLongDescription is not empty on entry to Add New Item")

            app.textFields["addShortDescription"].tap()
            app.typeText(sampleItems[i].0)
            app.textViews["addLongDescription"].tap()
            app.typeText(sampleItems[i].1)
            app.navigationBars["Add New Item"].buttons["Save"].tap()
        }
        let rowCount = tableView.cells.count
        XCTAssert(rowCount == sampleItems.count, "Table should have \(sampleItems.count) rows, but found \(rowCount)")

        let cells = tableView.children(matching: .cell)
        for i in 0..<sampleItems.count {
            let texts = cells.element(boundBy: i).staticTexts
            let titleFound = texts.element(boundBy: 0).label
            let subTitleFound = texts.element(boundBy: 1).label
            print("\(i): \(titleFound) \(subTitleFound)")
            XCTAssert(titleFound == sampleItems[i].0, "Table cell \(i) title contains \"\(titleFound)\" but should contain \"\(sampleItems[i].0)\"")
            XCTAssert(subTitleFound == sampleItems[i].1, "Table cell \(i) subTitle contains \"\(subTitleFound)\" but should contain \"\(sampleItems[i].1)\"")
            
            let buttons = cells.element(boundBy: i).buttons
            let button = buttons.element(boundBy: 0)
            XCTAssert(button.label ==  "More Info", "Table entry \(i) disclosure button not found")

        }
    }
    
    func testEditItem() {
        var sampleItems = [("Item one", "This is item one"),
                           ("Item two", "This is item two"),
                           ("Item three", "This is item three"),
                           ]
        
        let tableView = app.tables.element(boundBy: 0)
        
        for i in 0..<sampleItems.count {
            XCTAssert(app.navigationBars["Inventory"].buttons["Add"].exists, "Add button not found on Inventory screen")
            app.navigationBars["Inventory"].buttons["Add"].tap()
            
            XCTAssert(app.textFields["addShortDescription"].exists, "No textField found with identifier addShortDescription in Add New Item")
            XCTAssert(app.textViews["addLongDescription"].exists, "No textView found with identifier addLongDescription in Add New Item")
            XCTAssert(app.navigationBars["Add New Item"].buttons["Save"].exists, "Save button not found")

            app.textFields["addShortDescription"].tap()
            app.typeText(sampleItems[i].0)
            app.textViews["addLongDescription"].tap()
            app.typeText(sampleItems[i].1)
            app.navigationBars["Add New Item"].buttons["Save"].tap()
        }
        let rowCount = tableView.cells.count
        XCTAssert(rowCount == sampleItems.count, "Table should have \(sampleItems.count) rows, but found \(rowCount)")
        
        let buttons = tableView.buttons
        XCTAssert(buttons.element(boundBy: 1).exists, "Second cell to be deleted not found")
        
        buttons.element(boundBy: 1).tap()
        XCTAssert(app.navigationBars["Edit Item"].exists, "Screen not titled \"Edit Item\"")
        XCTAssert(app.navigationBars["Edit Item"].buttons["Inventory"].exists, "Inventory back button not found")
        XCTAssert(app.navigationBars["Edit Item"].buttons["Save"].exists, "Save button not found")
        XCTAssert(app.textFields["editShortDescription"].exists, "No textField found with identifier addShortDescription in Edit Item")
        XCTAssert(app.textViews["editLongDescription"].exists, "No textView found with identifier addLongDescription in Edit Item")


        let addedText = " more text added here"
        app.textFields["editShortDescription"].tap()
        app.textFields["editShortDescription"].tap()
        app.menuItems["Select All"].tap()
        app.menuItems["Cut"].tap()
        app.typeText(sampleItems[1].0 + addedText)
        app.textViews["editLongDescription"].tap()
        app.textViews["editLongDescription"].tap()
        app.menuItems["Select All"].tap()
        app.menuItems["Cut"].tap()
        app.typeText(sampleItems[1].1 + addedText)
        app.navigationBars["Edit Item"].buttons["Save"].tap()

        let cells = tableView.children(matching: .cell)
        sampleItems[1].0 = sampleItems[1].0 + addedText
        sampleItems[1].1 = sampleItems[1].1 + addedText

        for i in 0..<sampleItems.count {
            let texts = cells.element(boundBy: i).staticTexts
            let titleFound = texts.element(boundBy: 0).label
            let subTitleFound = texts.element(boundBy: 1).label
            XCTAssert(titleFound == sampleItems[i].0, "Table cell \(i) title contains \"\(titleFound)\" but should contain \"\(sampleItems[i].0)\"")
            XCTAssert(subTitleFound == sampleItems[i].1, "Table cell \(i) subTitle contains \"\(subTitleFound)\" but should contain \"\(sampleItems[i].1)\"")
        }
    }
    
    func testDeleteItem() {
        var sampleItems = [("Item one", "This is item one"),
                           ("Item two", "This is item two"),
                           ("Item three", "This is item three"),
                           ]
        
        let tableView = app.tables.element(boundBy: 0)
        
        let itemToDelete = 1
        
        for i in 0..<sampleItems.count {
            app.navigationBars["Inventory"].buttons["Add"].tap()
            app.textFields["addShortDescription"].tap()
            app.typeText(sampleItems[i].0)
            app.textViews["addLongDescription"].tap()
            app.typeText(sampleItems[i].1)
            app.navigationBars["Add New Item"].buttons["Save"].tap()
        }
        var rowCount = tableView.cells.count
        XCTAssert(rowCount == sampleItems.count, "Table should have \(sampleItems.count) rows, but found \(rowCount)")
        
        let cells = tableView.cells
        let cell = cells.element(boundBy: itemToDelete)
        cell.swipeLeft()
        XCTAssert(cell.buttons["Delete"].exists, "Second cell does not include a Swipe to Delete button")
        cell.buttons["Delete"].tap()
        
        sampleItems.remove(at: itemToDelete)
        
        rowCount = tableView.cells.count
        XCTAssert(rowCount == sampleItems.count, "After Delete, table should have \(sampleItems.count) rows, but found \(rowCount)")

        for i in 0..<sampleItems.count {
            let texts = cells.element(boundBy: i).staticTexts
            let titleFound = texts.element(boundBy: 0).label
            let subTitleFound = texts.element(boundBy: 1).label
            XCTAssert(titleFound == sampleItems[i].0, "Table cell \(i) title contains \"\(titleFound)\" but should contain \"\(sampleItems[i].0)\"")
            XCTAssert(subTitleFound == sampleItems[i].1, "Table cell \(i) subTitle contains \"\(subTitleFound)\" but should contain \"\(sampleItems[i].1)\"")
        }
    }
    
    func testBackButtonDoesNotSave() {
        var sampleItems = [("Item one", "This is item one"),
                           ("Item two", "This is item two"),
                           ("Item three", "This is item three"),
                           ]
        
        let tableView = app.tables.element(boundBy: 0)
        
        for i in 0..<sampleItems.count {
            XCTAssert(app.navigationBars["Inventory"].buttons["Add"].exists, "Add button not found on Inventory screen")
            app.navigationBars["Inventory"].buttons["Add"].tap()
            
            XCTAssert(app.textFields["addShortDescription"].exists, "No textField found with identifier addShortDescription in Add New Item")
            XCTAssert(app.textViews["addLongDescription"].exists, "No textView found with identifier addLongDescription in Add New Item")
            XCTAssert(app.navigationBars["Add New Item"].buttons["Save"].exists, "Save button not found")
            
            app.textFields["addShortDescription"].tap()
            app.typeText(sampleItems[i].0)
            app.textViews["addLongDescription"].tap()
            app.typeText(sampleItems[i].1)
            app.navigationBars["Add New Item"].buttons["Inventory"].tap()
        }

        let rowCount = tableView.cells.count
        XCTAssert(rowCount == 0, "Table should have no rows in it, but found \(rowCount)")
    }
}
