//
//  InterfaceController.swift
//  thoughtCounter WatchKit Extension
//
//  Created by Arina on 09.02.2021.
//

import WatchKit
import Foundation
import CoreData
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    var currentCount: Int = 0

    @IBOutlet weak var minusButton: WKInterfaceButton!
    @IBOutlet weak var plusButton: WKInterfaceButton!
    
    @IBOutlet weak var countLabel: WKInterfaceLabel!
    @IBOutlet weak var adviceLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        setupWatchConnectivity()
        
        if let count = context as? Int {
            self.countLabel.setText(String(count))
        } else {
            self.countLabel.setText(String(currentCount))
        }
        setAdvice()
    }
    
    @IBAction func minusTapped() {
        currentCount -= 1
        sendCountToPhone()
    }
    
    @IBAction func plusTapped() {
        currentCount += 1
        sendCountToPhone()
    }
    
    func setAdvice() {
        let adviceArray: [String] = [
            "Я принимаю все свои эмоции",
            "Меня ничто не ограничивает",
            "Мир вокруг меня безопасен",
            "Я способна быть выше всех этих мыслей",
            "Я легко оставляю прошлое позади, отдаваясь потоку жизни",
            "Все налаживается",
            "У меня прекрасное будущее",
            "Я горжусь всем, чего мне удалось достичь",
            "Моя жизнь полна любви и радости",
            "Я не сужу себя за свои чувства",
            "Нет ничего такого, что «не так» со мной",
            "Эти чувства нормальны. Это часть жизни",
            "Прямо сейчас со мной все в порядке",
            "Я работаю над собой каждый день",
            "Мне немного грустно сейчас, но это нормально",
            "С каждым днем мне становится немного лучше",
            "Я контролирую свои мысли и свою жизнь",
            "Просить о помощи — нормально",
            "Список дел не определяет мою ценность",
            "Я могу сделать всё что угодно, но не одновременно",
            "Здоровье — вот мой главный приоритет",
            "Я всегда смогу сделать всё потом",
            "Отдых — такая же задача, которую нужно выполнить",
            "Нет ничего страшного в том, чтобы притормозить",
            "Это не конец света",
            "Сегодня — это сегодня, не каждый день будет таким",
            "Завтра будет новый день",
            "Я не одна",
            "Если не получается, это не страшно",
            "В этом нет ничего страшного",
            "Я способный человек, я могу справиться со всем",
            "Меня ценят",
            "Я на пути позитивных перемен",
            "Я доверяю себе решение всех проблем",
            "Я эмоционально уравновешенный человек"
        ]
        let rand = Int.random(in: 0...34)
        adviceLabel.setText(adviceArray[rand])
    }
    
    func sendCountToPhone() {
        let thoughtString = "\(currentCount)%\(Date())"
        
        if WCSession.isSupported() {
            let session = WCSession.default
            do {
                let dict: [String: Any] = ["thoughts" : thoughtString]
                try session.updateApplicationContext(dict)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
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
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        let count: Int = applicationContext["count"] as! Int
        
        DispatchQueue.main.async {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "RootController", context: count as AnyObject)])
        }
    }
    
}
