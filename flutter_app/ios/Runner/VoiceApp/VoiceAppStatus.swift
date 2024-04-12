/*
 * Copyright (c) 2022 Exotel Techcom Pvt Ltd
 * All rights reserved
 */

import Foundation

public class VoiceAppStatus {
    private var state:VoiceAppState = .STATUS_NOT_INITIALIZED
    private var message: String = ""
    
    public func getState() -> VoiceAppState {
        return state
    }
    
    public func setState(state: VoiceAppState) {
        self.state = state
    }
    
    public func getMessage() -> String {
        return message
    }
    
    public func setMessage(message: String) {
        self.message = message
    }
}
