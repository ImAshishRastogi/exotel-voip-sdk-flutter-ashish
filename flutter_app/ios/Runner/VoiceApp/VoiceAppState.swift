/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation


public enum VoiceAppState {
    case STATUS_BUSY
    case STATUS_NOT_INITIALIZED
    case STATUS_INITIALIZATION_FAILURE
    case STATUS_INITIALIZATION_IN_PROGRESS
    case STATUS_READY
    
    static func stringFromEnum(voiceAppState: VoiceAppState) -> String {
        switch voiceAppState {
        case .STATUS_BUSY:
            return "Busy"
        case .STATUS_NOT_INITIALIZED:
            return "Not Initialized"
        case .STATUS_INITIALIZATION_FAILURE:
            return "Failure"
        case .STATUS_INITIALIZATION_IN_PROGRESS:
            return "In Progress"
        case .STATUS_READY:
            return "Ready"
        }
    }
    
    static func enumFromString(voiceAppState: String) -> VoiceAppState {
        switch voiceAppState {
        case "Busy":
            return .STATUS_BUSY
        case "Not Initialized":
            return .STATUS_NOT_INITIALIZED
        case "Failure":
            return .STATUS_INITIALIZATION_FAILURE
        case "In Progress":
            return .STATUS_INITIALIZATION_IN_PROGRESS
        case "Ready":
            return .STATUS_READY
        default:
            return .STATUS_NOT_INITIALIZED
        }
    }
}
