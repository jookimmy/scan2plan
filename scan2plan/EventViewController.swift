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

class EventViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var titleTextField: UITableViewCell!
    @IBOutlet weak var locationTextField: UITableViewCell!
    @IBOutlet weak var startDateTimeField: UIDatePicker!
    
    // Passed from PreviewViewController
    var detectedText = String()
    var visionText: VisionText!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startDateTimeField.date = createDate(year: 2018, month: 11, day: 8, hour: 19, minute: 30)
        titleTextField.text = ""
        locationTextField.text = ""
        //URLTextField.text = ""
        informationExtractor()
        detectEventName()
        
        for block in visionText.blocks {
            print(block.text)
            print(block.frame.size.height)
        }
        
        // Do any additional setup after loading the view.
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
        print()
        print()
        print()
        print("THIS IS THE MAX HEIGHT: ")
        print(maxHeight)
        print("THIS IS TEXT WITH MAX HEIGHT: ")
        print(blockWithMax)
        print()
        print()
        print()
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
//                    print()
//                    print()
//                    print()
//                    print("THIS IS THE DATE")
//                    print(match.date)
//                    print()
//                    print()
//                    print()
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

    // MARK: Actions
    
    @IBAction func addEventToCalendar(_ sender: Any) {
        let eventStore:EKEventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event, completion: {(granted, error) in
            if(granted && error == nil) {
                print("Access granted. \(granted)")
                print("Error: \(String(describing: error))")
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                DispatchQueue.main.async {
                    event.title = self.titleTextField.text
                    event.startDate = self.startDateTimeField.date
                    event.endDate = self.startDateTimeField.date + 3600 //1800 seconds is the equivelant to 30 minutes
                    event.location = self.locationTextField.text
                }
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
        
        self.performSegue(withIdentifier: "returnToCamera", sender: self)
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
