/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

public struct RecentCallDetails {
    private var remoteId: String
    private var callType: CallType
    private var time: String
    
    public init(remoteId: String, callType: CallType, time: String) {
        self.remoteId = remoteId
        self.callType = callType
        self.time = time
    }
    
    public func getRemoteId() -> String {
        return remoteId
    }
    
    public func getCallType() -> CallType {
        return callType
    }
    
    public func getTime() -> String {
        return time
    }
}
