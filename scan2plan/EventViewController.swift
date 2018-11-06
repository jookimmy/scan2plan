//
//  eventViewController.swift
//  scan2plan
//
//  Created by Mulye, Daman on 10/20/18.
//  Copyright © 2018 CS196Illinois. All rights reserved.
//

import UIKit
import EventKit

class EventViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var startDateTimeField: UIDatePicker!
    var detectedText = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startDateTimeField.date = Date()
        titleTextField.text = "Meeting"
        locationTextField.text = ""
        informationExtractor()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func informationExtractor() {
        let eventString = detectedText
        let range = NSRange(eventString.startIndex..<eventString.endIndex, in: eventString)
        let detectionTypes: NSTextCheckingResult.CheckingType = [.date, .address]
        let detector = try NSDataDetector(types: detectionTypes.rawValue)
        detector.enumerateMatches(in: eventString, options: [], range: range) { (match, flags, _) in
            guard let match = match else {
                return
            }
            
            switch match.resultType {
            case .date:
                let detectedDate = match.date
                print(detectedDate)
                startDateTimeField.date = detectedDate
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
            default:
                return
            }
        }
//        let dataDetector = NSDataDetector(types: detectionTypes.rawValue, error: nil)
//        dataDetector?.enumerateMatchesInString(detectedText, options: nil, range: NSMakeRange(0, eventString.length)) { (match, flags, _) in
//            let matchString = eventString.substringWithRange(match.rnage)
//            if match.resultType == .Date {
//                println("Matched Date: \(matchString); \n- Date: \(match.date)")
//            } else if match.resultType == .Address {
//                if let addressComponents = match.addressComponents as NSDictionary? {
//                    println("Match: \(matchString); \n- Street: \(addressComponents[NSTextCheckingStreetKey]);\n- Zip: \(addressComponents[NSTextCheckingZIPKey])")
//                }
//            } else {
//                println("Match: \(matchString)")
//            }
//        }
        
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

    @IBAction func addEventToCalendar(_ sender: Any) {
        let eventStore:EKEventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event, completion: {(granted, error) in
            if(granted && error == nil) {
                print("Access granted. \(granted)")
                print("Error: \(String(describing: error))")
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                event.title = titleTextField.text
                event.startDate = startDateTimeField.date
                event.endDate = startDateTimeField.date + 1800 //1800 seconds is the equivelant to 30 minutes
                event.location = locationTextField.text
                event.notes = "Just a test of date creation"
                event.calendar = eventStore.defaultCalendarForNewEvents
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let error as NSError {
                    print(error)
                }
            } else {
                print("error: \(error)")
            }
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
