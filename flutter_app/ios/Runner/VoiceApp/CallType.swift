/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

public enum CallType {
    case INCOMING
    case OUTGOING
    case MISSED
    case UNKNOWN
    
    static func enumFromString(callTypeName: String) -> CallType {
        switch callTypeName {
        case "INCOMING":
            return INCOMING
        case "OUTGOING":
            return OUTGOING
        case "MISSED":
            return MISSED
        case "UNKNOWN":
            return UNKNOWN
        default:
            return UNKNOWN
        }
    }
    
    static func stringFromEnum(callType: CallType) -> String {
        switch callType {
        case .INCOMING:
            return "INCOMING"
        case .OUTGOING:
            return "OUTGOING"
        case .MISSED:
            return "MISSED"
        case .UNKNOWN:
            return "UNKNOWN"
        }
    }
}
