/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation
import UserNotifications
import UIKit
import ExotelVoice

public class NotificationPublisher: NSObject {
    static let shared = NotificationPublisher()
    let databaseHelper = DatabaseHelper.shared
    let TAG = "NotificationPublisher"
    var callerId = ""
    public var pushNotificationData :[AnyHashable: Any] = [:]
    
    func sendNotification(callerName: String) {
        callerId = callerName
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Exotel Voice Sample App"
        notificationContent.subtitle = ""
        notificationContent.body = "Connecting.... \(callerId)"
        notificationContent.categoryIdentifier = "CALL_ARRIVED"
        var delayTimeTrigger: UNTimeIntervalNotificationTrigger?
        let delayInterval:Int? = 1
        if let delayInterval = delayInterval {
            delayTimeTrigger   = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delayInterval), repeats: false)
        }
        notificationContent.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: "exotel_ringtone_20.wav"))
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        let meetingInviteCategory =
        UNNotificationCategory(identifier: "CALL_ARRIVED",
                               actions: [],
                               intentIdentifiers: [],
                               hiddenPreviewsBodyPlaceholder: "",
                               options: .customDismissAction)
        // Register the notification type.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([meetingInviteCategory])
        
        let request = UNNotificationRequest(identifier: "CALL_ARRIVED", content: notificationContent, trigger: delayTimeTrigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                VoiceAppLogger.debug(TAG: self.TAG, message: "error :\(error.localizedDescription)")
            }
        }
    }
}

extension NotificationPublisher: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.actionIdentifier
        
        switch identifier {
        case UNNotificationDismissActionIdentifier:
            VoiceAppLogger.debug(TAG: TAG, message: "The notification was dismissed")
            var callType: CallType
            callType = .MISSED
            let callerId = callerId
            let date = Date().description
            let result = databaseHelper.insertData(callerId: callerId, callType: callType, time: date.description)
            if result {
                VoiceAppLogger.debug(TAG: TAG, message: "Inserted as Missed call to recent calls table in database")
            }
            completionHandler()
            
        case UNNotificationDefaultActionIdentifier:
            VoiceAppLogger.debug(TAG: TAG, message: "The user opened the app from notification")
            guard let data = try? PushNotificationData(decoding: pushNotificationData) else {
                VoiceAppLogger.debug(TAG: TAG, message: "In UNNotificationDefaultActionIdentifier PushNotificationData\(pushNotificationData)")
                return
            }
            VoiceAppService.shared.onReceivePushNotification(pnData: data)
            VoiceAppLogger.debug(TAG: TAG, message: "Notification Publisher Exit")
            completionHandler()
            
        default:
            VoiceAppLogger.debug(TAG: TAG, message: "The default action of Notification")
            completionHandler()
        }
    }
    
}
