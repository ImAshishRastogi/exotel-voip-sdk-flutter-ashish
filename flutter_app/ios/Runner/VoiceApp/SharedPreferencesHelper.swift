/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

extension UserDefaults {
    enum Keys: String, CaseIterable {
        case enableDebugDialing
        case firebaseToken
        case exophoneNumber
        case lastDialedNumber
        case subscriberName
        case displayName
        case bellatrixHostName
        case milesHostName
        case accountSID
        case password
        case isLoggedIn
        case deviceTokenState
        case voiceAppState
        case enableMultiCall
        case toastMessage
        case contextMessage
        case contextDisplayName
    }
    
    func reset() {
        Keys.allCases.forEach {
            switch $0.rawValue {
            case UserDefaults.Keys.firebaseToken.rawValue:
                break
            default:
                removeObject(forKey: $0.rawValue)
            }
        }
        UserDefaults.resetStandardUserDefaults()
        UserDefaults.standard.synchronize()
    }
    
    func disableFeatures() {
        UserDefaults.standard.set("false", forKey: UserDefaults.Keys.enableDebugDialing.rawValue)
        UserDefaults.standard.set("false", forKey: UserDefaults.Keys.enableMultiCall.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    func resetMessages() {
        UserDefaults.standard.set("", forKey: UserDefaults.Keys.toastMessage.rawValue)
        UserDefaults.standard.set("", forKey: UserDefaults.Keys.contextMessage.rawValue)
        UserDefaults.standard.synchronize()
    }
}
