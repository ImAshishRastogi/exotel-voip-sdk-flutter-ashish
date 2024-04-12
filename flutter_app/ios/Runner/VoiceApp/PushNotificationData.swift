/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

public struct PushNotificationData : Codable {
    var subscriberName: String
    var payloadVersion: String
    var payload: String
    
    init(decoding userInfo: [AnyHashable: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
        self = try JSONDecoder().decode(PushNotificationData.self, from: data)
    }
    
    func getNotificationResponse() -> String {
        var result = "Subscriber Name: \(subscriberName)\n"
        result = result + "Payload Version: \(payloadVersion)\n"
        result = result + "Payload: \(payload)\n"
        return result
    }
}
