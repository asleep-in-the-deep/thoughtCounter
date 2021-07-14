//
//  ViewController.swift
//  thoughtCounter
//
//  Created by Arina on 09.02.2021.
//

import UIKit
import CoreData
import FSCalendar
import WatchConnectivity

class ViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, WCSessionDelegate {
    
    @IBOutlet weak var calendar: FSCalendar!
    
    @IBOutlet weak var selectedDateLabel: UILabel!
    @IBOutlet weak var totalPerWeekLabel: UILabel!
    @IBOutlet weak var compareLabel: UILabel!
    @IBOutlet weak var totalMonthLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.calendar.delegate = self
        self.calendar.dataSource = self
        
        setLabels()
        sendCountToWatch()
        setupWatchConnectivity()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
    func setLabels() {
        let thoughtsPerWeek = String(getTotalThoughts(date: Date(), days: -7, inversedCompare: true))
        let thoughtsPerMonth = String(getTotalThoughts(date: Date(), days: -30, inversedCompare: true))
        
        selectedDateLabel.text = "Выбранная дата: \(dateToString(forDate: Date()))"
        totalPerWeekLabel.text = "Всего за прошедшую неделю: \(thoughtsPerWeek)"
        compareLabel.text = compareThoughtsPerWeeks()
        totalMonthLabel.text = "Всего за прошлые 30 дней: \(thoughtsPerMonth)"
    }
    
    func reloadCalendar() {
        calendar.reloadData()
        setLabels()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDateLabel.text = "Выбранная дата: " + dateToString(forDate: date)
    }
    
    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        let resultThoughts = getTotalThoughts(date: date, days: 1, inversedCompare: false)
        
        if resultThoughts == 0 {
            return nil
        } else {
            return String(resultThoughts)
        }
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print(#function)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print(#function)
        WCSession.default.activate()

    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let thoughtString: String = applicationContext["thoughts"] as! String
        DispatchQueue.main.async {
            self.saveResult(forString: thoughtString)
        }
    }
    
    func dateToString(forDate date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        let currentDate = formatter.string(from: date)
        return currentDate
    }
    
    func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func getDatePredicate(date: Date, days: Int, inversedCompare: Bool, fetchRequest: NSFetchRequest<Thought>) {
        let calendar = Calendar.current
        
        var dateFrom: Date
        var dateTo: Date
        var fromPredicate: NSPredicate
        var toPredicate: NSPredicate
        
        if inversedCompare == true {
            dateFrom = date
            dateTo = calendar.date(byAdding: .day, value: days, to: dateFrom)!
            fromPredicate = NSPredicate(format: "date < %@", dateFrom as NSDate)
            toPredicate = NSPredicate(format: "date > %@", dateTo as NSDate)
        } else {
            dateFrom = calendar.startOfDay(for: date)
            dateTo = calendar.date(byAdding: .day, value: days, to: dateFrom)!
            fromPredicate = NSPredicate(format: "date > %@", dateFrom as NSDate)
            toPredicate = NSPredicate(format: "date < %@", dateTo as NSDate)
        }
        
        let datePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fromPredicate, toPredicate])
        fetchRequest.predicate = datePredicate
    }
    
    func getTotalThoughts(date: Date, days: Int, inversedCompare: Bool) -> Int {
        let context = getContext()
        let fetchRequest: NSFetchRequest<Thought> = Thought.fetchRequest()
        
        getDatePredicate(date: date, days: days, inversedCompare: inversedCompare, fetchRequest: fetchRequest)
        
        var resultCount = 0
        do {
            let results = try context.fetch(fetchRequest)
            for result in results {
                let thoughts = result.value(forKey: "count") as! Int
                resultCount += thoughts
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return resultCount
    }
    
    func compareThoughtsPerWeeks() -> String {
        let weekAgoDay = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        
        let lastWeek = getTotalThoughts(date: Date(), days: -7, inversedCompare: true)
        let previousWeek = getTotalThoughts(date: weekAgoDay!, days: -14, inversedCompare: true)
        let difference = lastWeek - previousWeek
        
        if difference > 0 {
            return "Это больше, чем на прошлой неделе на \(difference)"
        } else if difference < 0 {
            return "Это меньше, чем на прошлой неделе на \(difference)"
        } else {
            return "Это также, как на прошлой неделе"
        }
    }
    
    func saveResult(forString string: String) {
        let stringsArray = string.components(separatedBy: "%")
        let count = stringsArray[0]
        let dateString = stringsArray[1]
        let context = getContext()

        let date = stringToDate(string: dateString)
        
        guard let entityThought = NSEntityDescription.entity(forEntityName: "Thought", in: context) else { return }
        let thoughtObject = Thought(entity: entityThought, insertInto: context)
        thoughtObject.date = date
        thoughtObject.count = Int32(count) ?? 0
        
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        reloadCalendar()
        sendCountToWatch()
    }
    
    func stringToDate(string: String) -> Date {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: string) ?? Date()
        return date
    }
    
    func sendCountToWatch() {
        if WCSession.isSupported() {
            let count = getTotalThoughts(date: Date(), days: 1, inversedCompare: false)
            
            do {
                let dict: [String: Any] = ["count": count]
                try WCSession.default.updateApplicationContext(dict)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}

//    func deletePreviuosData(date: Date) {
//        let context = getContext()
//        let fetchRequest: NSFetchRequest<Thought> = Thought.fetchRequest()
//
//        getDatePredicate(date: date, days: 1, fetchRequest: fetchRequest)
//
//        do {
//            let results = try context.fetch(fetchRequest)
//            for result in results {
//                context.delete(result)
//            }
//        } catch let error as NSError {
//            print(error.localizedDescription)
//        }
//    }
