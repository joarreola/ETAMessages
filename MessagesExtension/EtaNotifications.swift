//
//  EtaNotifications.swift
//  ETAMessages
//
//  Created by taiyo on 6/5/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UserNotifications
//import NotificationCenter

class EtaNotifications {
// configure
    let content = UNMutableNotificationContent()
    let center = UNUserNotificationCenter.current()
    
    func configureContent() {
        print("-- EtaNotifications -- configureContent()")
        
        // Configure the content. . .
        self.content.title = NSString.localizedUserNotificationString(forKey: "ETAMessages", arguments: nil)
        self.content.body = NSString.localizedUserNotificationString(forKey: "Here", arguments: nil)
        self.content.sound = UNNotificationSound.default()
        
        // Deliver the notification in five seconds.
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        //let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
    
    }
    
    func scheduleNotification() {
        print("-- EtaNotifications -- scheduleNotification()")
        
        // Deliver the notification in five seconds.

        // can't be <60sec if repeating
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "OneSecond", content: self.content, trigger: trigger)
        
        // Schedule the notification.
        //let center = UNUserNotificationCenter.current()
        
        print("-- EtaNotifications -- scheduleNotification -- center.add(request)")
        center.add(request) { (error : Error?) in
            if let theError = error {
                // Handle any errors
                print("-- EtaNotifications -- scheduleNotification -- center.add -- closure -- Error: \(theError.localizedDescription)")
            } else {
                print("-- EtaNotifications -- scheduleNotification -- center.add -- closure -- NoError")
            }
        }
    }

    func requestAuthorization() {
        print("-- EtaNotifications -- requestAuthorization()")
        
        // requestAuthorization
        //let center = UNUserNotificationCenter.current()
        self.center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
            print("-- EtaNotifications -- requestAuthorization -- closure")
            
            let generalCategory = UNNotificationCategory(identifier: "OneSecond",
                                                         actions: [],
                                                         intentIdentifiers: [],
                                                         options: .customDismissAction)
            
            self.center.setNotificationCategories([generalCategory])
            
        }
    }

    func all() {
         print("-- EtaNotifications -- all()")
        
        // configure
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Hello!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Hello_message_body", arguments: nil)
        content.sound = UNNotificationSound.default()
        
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                // Handle any errors
                print(theError.localizedDescription)
            }
        }
    }
    
    func registerNotification() {
        // Register
        print("-- EtaNotifications -- registerNotification()")
        
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                 actions: [],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
    
        // Register the category.
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([generalCategory])
    }
    
    
/*
// custom actions
    let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                 actions: [],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
    
    // Create the custom actions for the TIMER_EXPIRED category.
    let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION",
                                            title: "Snooze",
                                            options: UNNotificationActionOptions(rawValue: 0))
    let stopAction = UNNotificationAction(identifier: "STOP_ACTION",
                                          title: "Stop",
                                          options: .foreground)
    
    let expiredCategory = UNNotificationCategory(identifier: "TIMER_EXPIRED",
                                                 actions: [snoozeAction, stopAction],
                                                 intentIdentifiers: [],
                                                 options: UNNotificationCategoryOptions(rawValue: 0))
    
    // Register the notification categories.
    let center = UNUserNotificationCenter.current()
    center.setNotificationCategories([generalCategory, expiredCategory])
    
    
// Schedule a local notification for delivery
    // Create the request object.
    let request = UNNotificationRequest(identifier: "MorningAlarm", content: content, trigger: trigger)
    
    // Schedule the request.
    let center = UNUserNotificationCenter.current()
    center.add(request) { (error : Error?) in
    if let theError = error {
    print(theError.localizedDescription)
    }
    }
 */
}
