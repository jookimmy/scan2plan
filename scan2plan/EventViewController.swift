//
//  EventViewController.swift
//  scan2plan
//
//  Created by Mulye, Daman on 10/20/18.
//  Copyright © 2018 CS196Illinois. All rights reserved.
//

import UIKit
import EventKit
import Firebase
import FirebaseMLVision

class EventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var detectedText = String()
    var visionText: VisionText!
    let pickerAnimationDuration = 0.40 // duration for the animation to slide the date picker into view
    let datePickerTag           = 99   // view tag identifiying the date picker view
    
    let titleKey = "title" // key for obtaining the data source item's title
    let dateKey  = "date"  // key for obtaining the data source item's date value
    
    // keep track of which rows have date cells
    let dateStartRow = 1
    let dateEndRow   = 2
    
    let dateCellID       = "dateCell";       // the cells with the start or end date
    let datePickerCellID = "datePickerCell"; // the cell containing the date picker
    let otherCellID      = "otherCell";      // the remaining cells at the end
    
    var dataArray: [[String: AnyObject]] = []
    var dateFormatter = DateFormatter()
    
    // keep track which indexPath points to the cell with UIDatePicker
    var datePickerIndexPath: NSIndexPath?
    
    var pickerCellRowHeight: CGFloat = 216
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        //startDateTimeField.date = createDate(year: 2018, month: 11, day: 8, hour: 19, minute: 30)
//        titleTextField.text = ""
//        locationTextField.text = ""
//        URLTextField.text = ""
//        informationExtractor()
//        detectEventName()
        
        for block in visionText.blocks {
            print(block.text)
            print(block.frame.size.height)
        }

        // setup our data source
        let itemOne = [titleKey : "Tap a cell to change its date:"]
        let itemTwo = [titleKey : "Start Date", dateKey : NSDate()] as [String : Any]
        let itemThree = [titleKey : "End Date", dateKey : NSDate()] as [String : Any]
        let itemFour = [titleKey : "(other item1)"]
        let itemFive = [titleKey : "(other item2)"]
        dataArray = [itemOne as Dictionary<String, AnyObject>, itemTwo as Dictionary<String, AnyObject>, itemThree as Dictionary<String, AnyObject>, itemFour as Dictionary<String, AnyObject>, itemFive as Dictionary<String, AnyObject>]
        
        dateFormatter.dateStyle = .short // show short-style date format
        dateFormatter.timeStyle = .short
        
        // if the local changes while in the background, we need to be notified so we can update the date
        // format in the table view cells
        //
        NotificationCenter.default.addObserver(self, selector: #selector(EventViewController.localeChanged(notif:)), name: NSLocale.currentLocaleDidChangeNotification, object: nil)
    }

    @objc func localeChanged(notif: NSNotification) {
        // the user changed the locale (region format) in Settings, so we are notified here to
        // update the date format in the table view cells
        //
        tableView.reloadData()
    }
    
    /*! Determines if the given indexPath has a cell below it with a UIDatePicker.
     
     @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
     */
    func hasPickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        var hasDatePicker = false
        
        let targetedRow = indexPath.row + 1
        let checkDatePickerCell = tableView.cellForRow(at: IndexPath(row: targetedRow, section: 0))
        let checkDatePicker = checkDatePickerCell?.viewWithTag(datePickerTag)
        
        hasDatePicker = checkDatePicker != nil
        return hasDatePicker
    }
    
    /*! Updates the UIDatePicker's value to match with the date of the cell above it.
     */
    func updateDatePicker() {
        if let indexPath = datePickerIndexPath {
            let associatedDatePickerCell = tableView.cellForRow(at: indexPath as IndexPath)
            if let targetedDatePicker = associatedDatePickerCell?.viewWithTag(datePickerTag) as! UIDatePicker? {
                let itemData = dataArray[self.datePickerIndexPath!.row - 1]
                targetedDatePicker.setDate(itemData[dateKey] as! Date, animated: false)
            }
        }
    }
    
    /*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
     */
    func hasInlineDatePicker() -> Bool {
        return datePickerIndexPath != nil
    }
    
    /*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
     
     @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
     */
    func indexPathHasPicker(indexPath: NSIndexPath) -> Bool {
        return hasInlineDatePicker() && datePickerIndexPath?.row == indexPath.row
    }
    
    /*! Determines if the given indexPath points to a cell that contains the start/end dates.
     
     @param indexPath The indexPath to check if it represents start/end date cell.
     */
    func indexPathHasDate(indexPath: NSIndexPath) -> Bool {
        var hasDate = false
        
        if (indexPath.row == dateStartRow) || (indexPath.row == dateEndRow || (hasInlineDatePicker() && (indexPath.row == dateEndRow + 1))) {
            hasDate = true
        }
        return hasDate
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPathHasPicker(indexPath: indexPath as NSIndexPath) ? pickerCellRowHeight : tableView.rowHeight)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if hasInlineDatePicker() {
            // we have a date picker, so allow for it in the number of rows in this section
            return dataArray.count + 1;
        }
        
        return dataArray.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        var cellID = otherCellID
        
        if indexPathHasPicker(indexPath: indexPath as NSIndexPath) {
            // the indexPath is the one containing the inline date picker
            cellID = datePickerCellID     // the current/opened date picker cell
        } else if indexPathHasDate(indexPath: indexPath as NSIndexPath) {
            // the indexPath is one that contains the date information
            cellID = dateCellID       // the start/end date cells
        }
        
        cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        
        if indexPath.row == 0 {
            // we decide here that first cell in the table is not selectable (it's just an indicator)
            cell?.selectionStyle = .none;
        }
        
        // if we have a date picker open whose cell is above the cell we want to update,
        // then we have one more cell than the model allows
        //
        var modelRow = indexPath.row
        if (datePickerIndexPath != nil && (datePickerIndexPath?.row)! <= indexPath.row) {
            modelRow -= 1
        }
        
        let itemData = dataArray[modelRow]
        
        if cellID == dateCellID {
            // we have either start or end date cells, populate their date field
            //
            cell?.textLabel?.text = itemData[titleKey] as? String
            cell?.detailTextLabel?.text = self.dateFormatter.string(from: (itemData[dateKey] as! NSDate) as Date)
        } else if cellID == otherCellID {
            // this cell is a non-date cell, just assign it's text label
            //
            cell?.textLabel?.text = itemData[titleKey] as? String
        }
        
        return cell!
    }
    
    /*! Adds or removes a UIDatePicker cell below the given indexPath.
     
     @param indexPath The indexPath to reveal the UIDatePicker.
     */
    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        
        tableView.beginUpdates()
        
        let indexPaths = [IndexPath(row: indexPath.row + 1, section: 0)]
        
        // check if 'indexPath' has an attached date picker below it
        if hasPickerForIndexPath(indexPath: indexPath) {
            // found a picker below it, so remove it
            tableView.deleteRows(at: indexPaths as [IndexPath], with: .fade)
        } else {
            // didn't find a picker below it, so we should insert it
            tableView.insertRows(at: indexPaths as [IndexPath], with: .fade)
        }
        
        tableView.endUpdates()
    }
    
    /*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
     
     @param indexPath The indexPath to reveal the UIDatePicker.
     */
    func displayInlineDatePickerForRowAtIndexPath(indexPath: NSIndexPath) {
        
        // display the date picker inline with the table content
        tableView.beginUpdates()
        
        var before = false // indicates if the date picker is below "indexPath", help us determine which row to reveal
        if hasInlineDatePicker() {
            before = (datePickerIndexPath?.row)! < indexPath.row
        }
        
        let sameCellClicked = (datePickerIndexPath?.row == indexPath.row + 1)
        
        // remove any date picker cell if it exists
        if self.hasInlineDatePicker() {
            
            tableView.deleteRows(at: [IndexPath(row: datePickerIndexPath!.row, section: 0)], with: .fade)
            datePickerIndexPath = nil
        }
        
        if !sameCellClicked {
            // hide the old date picker and display the new one
            let rowToReveal = (before ? indexPath.row - 1 : indexPath.row)
            let indexPathToReveal =  IndexPath(row: rowToReveal, section: 0)
            
            toggleDatePickerForSelectedIndexPath(indexPath: indexPathToReveal as NSIndexPath)
            datePickerIndexPath = IndexPath(row: indexPathToReveal.row + 1, section: 0) as NSIndexPath
        }
        
        // always deselect the row containing the start or end date
        tableView.deselectRow(at: indexPath as IndexPath, animated:true)
        
        tableView.endUpdates()
        
        // inform our date picker of the current date to match the current cell
        updateDatePicker()
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath as IndexPath)
        if cell?.reuseIdentifier == dateCellID {
            displayInlineDatePickerForRowAtIndexPath(indexPath: indexPath as NSIndexPath)
        } else {
            tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        }
    }

    // MARK: - Actions
    
    /*! User chose to change the date by changing the values inside the UIDatePicker.
     
     @param sender The sender for this action: UIDatePicker.
     */

    @IBAction func dateAction(_ sender: UIDatePicker) {
        var targetedCellIndexPath: NSIndexPath?
        if self.hasInlineDatePicker() {
            // inline date picker: update the cell's date "above" the date picker cell
            //
            targetedCellIndexPath = IndexPath(row: datePickerIndexPath!.row - 1, section: 0) as NSIndexPath
        } else {
            // external date picker: update the current "selected" cell's date
            targetedCellIndexPath = tableView.indexPathForSelectedRow! as NSIndexPath
        }
        let cell = tableView.cellForRow(at: targetedCellIndexPath! as IndexPath)
        let targetedDatePicker = sender
        // update our data model
        var itemData = dataArray[targetedCellIndexPath!.row]
        itemData[dateKey] = targetedDatePicker.date as AnyObject
        dataArray[targetedCellIndexPath!.row] = itemData
        // update the cell's date string
        cell?.detailTextLabel?.text = dateFormatter.string(from: targetedDatePicker.date)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func detectEventName() {
        var maxHeight = visionText.blocks[0].frame.size.height
        var blockWithMax = visionText.blocks[0].text
        for block in visionText.blocks {
            if block.frame.size.height > maxHeight {
                maxHeight = block.frame.size.height
                blockWithMax = block.text
            }
        }
        titleTextField.text = blockWithMax.capitalized
    }
    func informationExtractor() {
        let charsToRemove: Set<Character> = Set("|{}[]()".characters)
        let eventString = String(detectedText.characters.filter { !charsToRemove.contains($0) })
        let range = NSRange(eventString.startIndex..<eventString.endIndex, in: eventString)
        let detectionTypes: NSTextCheckingResult.CheckingType = [.date, .address, .link]
        
        do {
            let detector = try NSDataDetector(types: detectionTypes.rawValue)
            detector.enumerateMatches(in: eventString, options: [], range: range) { (match, flags, _) in
                guard let match = match else {
                    return
                }
                
                switch match.resultType {
                case .date:
                    let detectedDate = match.date
                    startDateTimeField.date = detectedDate!
                case .address:
                    if let components = match.components {
                        var addressComponents = [components[.name], components[.street], components[.city], components[.state], components[.zip], components[.country]]
                        var addressString = ""
                        for c in addressComponents {
                            if c == nil {
                                continue
                            }
                            addressComponents.append(" ")
                            addressComponents.append(c)
                        }
                        locationTextField.text = addressString
                    }
                case .link:
                    let detectedURL = match.url
                    //URLTextField.text = detectedURL!
                default:
                    return
                }
            }
        } catch {
            return
        }
    }
    
    func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        // Specify date components
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute

        // Create date from components
        let userCalendar = Calendar.current // user calendar
        var dateTime: Date? = nil
        dateTime = userCalendar.date(from: dateComponents) 
        return dateTime!
    }

    // MARK: Actions
    
    @IBAction func addEventToCalendar(_ sender: Any) {
        print("Add Button Clicked")
//        let eventStore:EKEventStore = EKEventStore()
//
//        eventStore.requestAccess(to: .event, completion: {(granted, error) in
//            if(granted && error == nil) {
//                print("Access granted. \(granted)")
//                print("Error: \(String(describing: error))")
//
//                let event:EKEvent = EKEvent(eventStore: eventStore)
//                DispatchQueue.main.async {
//                    event.title = self.titleTextField.text
//                    event.startDate = self.startDateTimeField.date
//                    event.endDate = self.startDateTimeField.date + 3600 //1800 seconds is the equivelant to 30 minutes
//                    event.location = self.locationTextField.text
//                }
//                event.notes = "Just a test of date creation"
//                event.calendar = eventStore.defaultCalendarForNewEvents
//                do {
//                    try eventStore.save(event, span: .thisEvent)
//                } catch let error as NSError {
//                    print(error)
//                }
//            } else {
//                print("error: \(error)")
//            }
//        })
//
//        self.performSegue(withIdentifier: "returnToCamera", sender: self)
    }

    /*
    // MARK: - Navigation
*/

}
