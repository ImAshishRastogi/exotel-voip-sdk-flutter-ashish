/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

public enum DeviceTokenState {
    case DEVICE_TOKEN_NOT_SENT
    case DEVICE_TOKEN_SEND_SUCCESS
    case DEVICE_TOKEN_SEND_FAILURE
    
    static func stringFromEnum(deviceTokenState: DeviceTokenState) -> String {
        switch deviceTokenState {
        case .DEVICE_TOKEN_NOT_SENT:
            return "DEVICE_TOKEN_NOT_SENT"
        case .DEVICE_TOKEN_SEND_SUCCESS:
            return "DEVICE_TOKEN_SEND_SUCCESS"
        case .DEVICE_TOKEN_SEND_FAILURE:
            return "DEVICE_TOKEN_SEND_FAILURE"
        }
    }
    
    static func enumFromString(deviceTokenState: String) -> DeviceTokenState {
        switch deviceTokenState {
        case "DEVICE_TOKEN_NOT_SENT":
            return .DEVICE_TOKEN_NOT_SENT
        case "DEVICE_TOKEN_SEND_SUCCESS":
            return .DEVICE_TOKEN_SEND_SUCCESS
        case "DEVICE_TOKEN_SEND_FAILURE":
            return DEVICE_TOKEN_SEND_FAILURE
        default:
            return .DEVICE_TOKEN_NOT_SENT
        }
    }
}
